#!/bin/bash -eu
#
# Copyright 2022 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Scripts that run idle shutdown logic when the right metadata is set.

# Skips when running unit tests

if [[ -z ${TEST_SRCDIR:-""} ]]; then
  # shellcheck disable=SC1091
  source /opt/c2d/c2d-utils || exit 1
  source /etc/profile.d/env.sh || exit 1
fi

# Obtain Notebook type: DLVM, USER_MANAGED_NOTEBOOK, GOOGLE_MANAGED_NOTEBOOK
notebook=$(notebook_type)

# System performs idle checks every minute. (Defined by cron schedule * * * * *)
# Uses port 8081 which returns both local and remote sessions from Mixer.
URL_SESSIONS="http://127.0.0.1:8080/api/sessions"
URL_SESSIONS_MIXER="http://127.0.0.1:8081/api/sessions"
URL_TERMINALS="http://127.0.0.1:8080/api/terminals"
NAMESPACE=$(guest_attributes_namespace)

function calculate_idle_origin_time() {
  time_given="$1"
  time_instance="$2"
  # Uses the max between the latest activity and the creation time of the instance.
  # This prevents idle shutdown to trigger due to ghost sessions unrelated to the
  # instance and that might have existed before the instance was created. See b/241870602.
  if [[ -z ${time_instance} ]]; then
    echo ""
    exit 0
  fi
  if [[ -z ${time_given} ]]; then
    echo "${time_instance}"
    exit 0
  fi
  if [[ ${time_instance} -gt "${time_given}" ]]; then
    echo "${time_instance}"
    exit 0
  fi
  echo "${time_given}"
}

function set_origin_time_attribute() {
  # Sets an immutable time similar to instance creation time.
  origin_time=$(get_origin_time_attribute)
  if [[ -z "$origin_time" ]]; then
    origin_time=$(get_current_time_in_sec)
    echo "Setting an origin timestamp ${origin_time} as a minimum base for idle calculations."
    set_guest_attributes "${NAMESPACE}/origin_time" "${origin_time}"
  fi
}

function get_origin_time_attribute() {
  last_activity_attribute=$(get_guest_attributes "${NAMESPACE}/origin_time")
  echo "${last_activity_attribute}"
}

function set_last_activity_attribute() {
  now=$(get_current_time_in_sec)
  timestamp_to_set="$1"
  reason="$2"
  origin_timestamp=$(get_origin_time_attribute)
  timestamp_to_set=$(calculate_idle_origin_time "${timestamp_to_set}" "${origin_timestamp}")
  # shellcheck disable=SC9002
  if [ "$timestamp_to_set" -ge "$origin_timestamp" ];then
    reason="Reason - $2 - replaced by later instance creation date"
  fi
  echo "Setting last notebook activity timestamp ${timestamp_to_set} at ${now} for the following reason: ${reason}"
  set_guest_attributes "${NAMESPACE}/last_activity" "${timestamp_to_set}"
}

function get_last_activity_attribute() {
  last_activity_attribute=$(get_guest_attributes "${NAMESPACE}/last_activity")
  echo "${last_activity_attribute}"
}

function get_terminals() {
  curl -s "${URL_TERMINALS}"
}

function get_sessions() {
  retval="${URL_SESSIONS}"
  if [[ "$(notebook_type)" = "GOOGLE_MANAGED_NOTEBOOK" ]]; then
    retval="${URL_SESSIONS_MIXER}"
  fi
  enable_mixer_attribute=$(get_attribute_value enable-mixer || true)
  if [[ "${enable_mixer_attribute,,}" = "true" ]]; then
    retval="${URL_SESSIONS_MIXER}"
  fi
  echo "Checking sessions at $retval"
  curl -s "${retval}"
}

function update_last_activity() {
  # Sessions `.kernel.last_activity` gets updated only when there's cell outputs
  # e.g. `time.sleep(60)` only updates session at start and after 60s
  # e.g. a for loop with print every 10s updates sessions at start and every 10s
  # Sessions with a cell running have `.kernel.state` == busy. Otherwise "idle".
  sessions=$(get_sessions)

  # When there's a running cell, uses "now" which addresses the potential no
  # output use case (ex: time.sleep)
  latest_activity=$(jq -r --raw-output '[ .[] | select(.kernel.execution_state == "busy").kernel.last_activity | sub(".[0-9]+Z$"; "Z") | fromdate ] | max | values' <<< "${sessions}")
  if [[ -n "$latest_activity" ]]; then
    latest_activity=$(get_current_time_in_sec)
    set_last_activity_attribute "${latest_activity}" "running cell"
    return 0
  fi

  latest_activity_previous=$(get_last_activity_attribute)
  latest_activity=$(jq -r --raw-output '[ .[] | .kernel.last_activity | sub(".[0-9]+Z$"; "Z") | fromdate ] | max | values' <<< "${sessions}")

  # When there is no sessions and we never set an activity attribute, uses "now"
  # which is more or less the creation date.
  if [[ -z "$latest_activity$latest_activity_previous" ]]; then
    latest_activity=$(get_current_time_in_sec)
    set_last_activity_attribute "${latest_activity}" "no known previous activity"
    return 0
  fi

  # When there is no sessions during the following cron calls, uses the previous
  # recorded time.
  if [[ -z "$latest_activity" ]]; then
    latest_activity="${latest_activity_previous}"
  fi

  # Checks if there is any active terminals. Terminal API doesn't provide a idle
  # or busy like kernels so we can not check cases like `sleep 5``. But we still
  # want to minimize shutdown case when terminals might run.
  # Skips when terminals are not enabled in JupyterLab (curl returns a 404 error)
  terminals=$(get_terminals)
  latest_activity_terminals=$(jq -r --raw-output '[ .[] | .last_activity | sub(".[0-9]+Z$"; "Z") | fromdate ] | max | values' <<< "${terminals}")
  status=$?
  # shellcheck disable=SC9002
  if [ $status -eq 0 ]; then
    if [[ $latest_activity_terminals > $latest_activity ]]; then
      latest_activity="${latest_activity_terminals}"
      set_last_activity_attribute "${latest_activity}" "terminals active after sessions"
      return 0
    fi
  fi

  # Uses latest activity of all sessions when there's at least one idle session.
  set_last_activity_attribute "${latest_activity}" "latest session activity"
  return 0
}

function shutdown_if_idle_timeout() {
  now=$(date +'%s')
  # Condition for WBI idle's metadata and old Runtime idle's metadata.
  idle_timeout_seconds=$(get_attribute_value idle-timeout-seconds || get_attribute_value idle-shutdown-timeout || 0)
  last_activity=$(get_last_activity_attribute)
  if [[ ${now} -gt $((last_activity + idle_timeout_seconds)) ]]; then
    echo "Shutting down with last_activity ${last_activity} at ${now}"
    echo "Reporting IDLE event"
    # Ensures that at the next instance start, origin_time won't be the creation
    # time but the start time.
    delete_guest_attributes "${NAMESPACE}/origin_time"
    report_event "IDLE"
  fi
}

if [[ -z ${TEST_SRCDIR:-""} ]]; then
  # Condition for WBI idle's metadata and old Runtime idle's metadata.
  if [[ -n "$(get_attribute_value idle-timeout-seconds)" || -n "$(get_attribute_value idle-shutdown-timeout)" ]]; then
    # Although google-wi-promote-premium.service removes code related to idle
    # shutdown, we still add this condition to skip the run for DLVM.
    if [[ $notebook != "DLVM" ]]; then
      set_origin_time_attribute
      update_last_activity
      shutdown_if_idle_timeout
    fi
  fi
fi
