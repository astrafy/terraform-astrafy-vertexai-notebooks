#!/bin/bash

export HTTP_PROXY=${proxy}
export HTTPS_PROXY=${proxy}
export NO_PROXY=${no_proxy}
export CERT_GCS_PATH=gs://${nb_scripts_bucket}/${cert_file}
export CERT_PATH=/usr/local/share/ca-certificates/ZscalerRootCertificate-2048-SHA256.crt
export AUTOSHUTDOWN_GCS_PATH=gs://${nb_scripts_bucket}/autoshutdown
export AUTOSHUTDOWN_GCS_SERVICE_PATH=gs://${nb_scripts_bucket}/autoshutdown.service
export AUTOSHUTDOWN_PATH=/usr/local/bin/autoshutdown
export AUTOSHUTDOWN_SERVICE_PATH=/lib/systemd/system/autoshutdown.service

# this function to allow the user to refresh the zscaler certificate
function refresh_zscaler_cert(){
    sudo gsutil cp \$CERT_GCS_PATH \$CERT_PATH
    sudo update-ca-certificates
    pip config set global.cert /etc/ssl/certs/ca-certificates.crt
}

# this function to allow the user to refresh the autoshutdown service
function refresh_autoshutdown(){
    sudo gsutil cp \$AUTOSHUTDOWN_GCS_PATH \$AUTOSHUTDOWN_PATH
    sudo gsutil cp \$AUTOSHUTDOWN_GCS_SERVICE_PATH \$AUTOSHUTDOWN_SERVICE_PATH
    sudo chmod +x /usr/local/bin/autoshutdown
    sudo systemctl daemon-reload
    sudo systemctl --no-reload --now enable /lib/systemd/system/autoshutdown.service
    sudo systemctl restart autoshutdown.service
}

# updates the startup_script to the latest available version in the bucket
function execute_post_startup_script(){
    sudo gsutil cp gs://${nb_scripts_bucket}/post_startup_script.sh /usr/local/bin/post_startup_script.sh
    chmod +x /usr/local/bin/post_startup_script.sh
    source /usr/local/bin/post_startup_script.sh
}