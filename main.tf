# Service account
locals {
  # Format [use_case_name]-[vxpl|vm|cf|sched]-[name]
  # vxpl, vm, cf.. : how the SA is used (vm if attached to a VM instance, sched if attached to a cloud scheduler etc..)
  sa_account_id_format_spec = "common-%s-%s-%s"
}

# TODO: maybe we should have the account_id as a variable?
resource "google_service_account" "vertex_notebook_sa" {
  project     = var.project_id
  account_id  = format(local.sa_account_id_format_spec, var.nb_group_name, "vxnb", "default")
  description = "SA used by the user-managed notebook (should not contain any permissions)"
}

# Google cloud storage
locals {
  gcs_name_format_spec = "${var.project_id}-common-%s-%s"
}

resource "google_storage_bucket" "vertex_nb_scripts" {
  name                        = format(local.gcs_name_format_spec, var.nb_group_name, "notebook-scripts")
  location                    = var.default_region
  uniform_bucket_level_access = true
  force_destroy               = false
  labels = local.resource_labels
}

resource "google_storage_bucket_object" "nb_startup_script" {
  name         = "startup_script.sh"
  bucket       = google_storage_bucket.vertex_nb_scripts.name
  content_type = "text/plain; charset=utf-8"
  content = templatefile("${path.module}/nb_scripts/startup_script.sh", {
    proxy             = var.proxy,
    no_proxy          = var.no_proxy,
    nb_scripts_bucket = google_storage_bucket.vertex_nb_scripts.name,
    cert_file         = var.bootstrap_cert_file
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

data "google_storage_bucket_object_content" "zscaler-certificate-source" {
  name   = var.bootstrap_cert_file
  bucket = var.bootstrap_bucket
}

resource "google_storage_bucket_object" "zscaler-certificate-target" {
  name         = var.bootstrap_cert_file
  bucket       = google_storage_bucket.vertex_nb_scripts.name
  content_type = "text/plain; charset=utf-8"
  content      = data.google_storage_bucket_object_content.zscaler-certificate-source.content
}

resource "google_storage_bucket_iam_member" "vertex_nb_scripts_viewer" {
  bucket = google_storage_bucket.vertex_nb_scripts.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.vertex_notebook_sa.email}"
}

# User-Managed Notebook
locals {
  notebook_name = "vert-%s-%s"
}

resource "google_notebooks_instance" "notebook_instance" {
  for_each = var.notebook_name_to_email_map

  lifecycle {
    ignore_changes = [
      machine_type
    ]
  }

  # Should we use the notebook_name prefix?
  name         = format(local.notebook_name, var.nb_group_name, each.key)
  location     = var.notebook_location
  machine_type = var.notebook_machine_type
  vm_image {
    project      = var.notebook_vm_image_project
    image_family = var.notebook_vm_image_family
  }
  instance_owners = [each.value]
  service_account = google_service_account.vertex_notebook_sa.email
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
  for_each           = var.access_group_email_set
  service_account_id = google_service_account.vertex_notebook_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "group:${each.value}"
}
