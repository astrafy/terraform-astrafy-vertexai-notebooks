# Service account
locals {
  # Format [use_case_name]-[vxpl|vm|cf|sched]-[name]
  # vxpl, vm, cf.. : how the SA is used (vm if attached to a VM instance, sched if attached to a cloud scheduler etc..)
  sa_account_id_format_spec = "notebook-dev-%s"
}

# TODO: maybe we should have the account_id as a variable?
resource "google_service_account" "vertex_notebook_sa" {
  for_each    = var.notebook_name_to_email_map
  project     = var.project_id
  account_id  = format(local.sa_account_id_format_spec, split("@", each.value)[0])
  description = "SA used by the user-managed notebook (should not contain any permissions)"
}

# Google cloud storage
locals {
  gcs_name_format_spec = "${var.project_id}-%s"
}

resource "google_storage_bucket" "vertex_nb_scripts" {
  project                     = var.project_id
  name                        = format(local.gcs_name_format_spec, "notebook-scripts")
  location                    = var.default_region
  uniform_bucket_level_access = true
  force_destroy               = false
  labels                      = local.resource_labels
}

resource "google_storage_bucket_object" "nb_startup_script" {
  name         = "startup_script.sh"
  bucket       = google_storage_bucket.vertex_nb_scripts.name
  content_type = "text/plain; charset=utf-8"
  content = templatefile("${path.module}/nb_scripts/startup_script.sh", {
    nb_scripts_bucket = google_storage_bucket.vertex_nb_scripts.name,
  })
}

resource "google_storage_bucket_object" "nb_autoshutdown_script" {
  name         = "autoshutdown"
  bucket       = google_storage_bucket.vertex_nb_scripts.name
  content_type = "text/plain; charset=utf-8"
  content = templatefile("${path.module}/nb_scripts/autoshutdown", {
    autoshutdown_counter_threshold    = var.autoshutdown_counter_threshold,
    autoshutdown_idle_timeout_seconds = var.autoshutdown_idle_timeout_seconds,
    autoshutdown_sleep_seconds        = var.autoshutdown_sleep_seconds
  })
}

resource "google_storage_bucket_object" "nb_autoshutdown_service_script" {
  name         = "autoshutdown.service"
  bucket       = google_storage_bucket.vertex_nb_scripts.name
  content_type = "text/plain; charset=utf-8"
  source       = "${path.module}/nb_scripts/autoshutdown.service"
}

resource "google_storage_bucket_iam_member" "vertex_nb_scripts_viewer" {
  for_each = google_service_account.vertex_notebook_sa
  bucket   = google_storage_bucket.vertex_nb_scripts.name
  role     = "roles/storage.objectViewer"
  member   = each.value.member
}

# User-Managed Notebook

resource "google_notebooks_instance" "notebook_instance" {
  for_each = var.notebook_name_to_email_map

  project = var.project_id

  lifecycle {
    ignore_changes = [
      machine_type
    ]
  }

  name         = format(local.sa_account_id_format_spec, split("@", each.value)[0])
  location     = var.notebook_location
  machine_type = var.notebook_machine_type
  vm_image {
    project      = var.notebook_vm_image_project
    image_family = var.notebook_vm_image_family
  }
  instance_owners = [each.value]
  service_account = google_service_account.vertex_notebook_sa[each.key].email
  boot_disk_type  = var.notebook_boot_disk_type
  data_disk_type  = var.notebook_data_disk_type
  no_public_ip    = true

  post_startup_script = "${google_storage_bucket.vertex_nb_scripts.url}/startup_script.sh"

  network = var.notebook_network
  subnet  = var.notebook_subnet

  # gpu
  install_gpu_driver = var.accelerator_config != null ? true : null
  dynamic "accelerator_config" {
    for_each = var.accelerator_config != null ? [1] : []
    content {
      type       = var.accelerator_config.accelerator_type
      core_count = var.accelerator_config.accelerator_count
    }
  }

  metadata = var.notebook_metadata

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = var.enable_secure_boot
    enable_vtpm                 = true
  }

  labels = local.resource_labels

  depends_on = [
    google_storage_bucket_object.nb_autoshutdown_script,
    google_storage_bucket_object.nb_autoshutdown_service_script,
    google_storage_bucket_object.nb_startup_script,
    google_service_account_iam_member.sa_user_to_user_managed_notebook
  ]
}

# Necessary for using a user managed notebook
resource "google_service_account_iam_member" "sa_user_to_user_managed_notebook" {
  for_each           = var.notebook_name_to_email_map
  service_account_id = google_service_account.vertex_notebook_sa[each.key].name
  role               = "roles/iam.serviceAccountUser"
  member             = "user:${each.value}"
}

resource "google_project_iam_member" "sa_user_to_user_managed_notebook" {
  for_each = var.notebook_name_to_email_map
  project  = var.project_id
  role     = "roles/notebooks.admin"
  member   = "user:${each.value}"
}

