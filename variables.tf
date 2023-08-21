variable "project_id" {
  type        = string
  description = "GCP Project ID where resources will be deployed."
}

variable "default_region" {
  type        = string
  description = "Default region for resource creation."
}

variable "usecase_name" {
  type        = string
  description = "Name of the use case (used for labels)"
  default     = "dev"
}

# User-Managed Notebook

variable "notebook_name_to_email_map" {
  type        = set(string)
  description = <<EOF
    set with the reference of the owner emails.
    All notebook names will be prefixed with the local variable notebook_name.
    Example:
      [
        "name@astrafy.io"
      ]
  EOF
}

variable "notebook_location" {
  type        = string
  description = "Vertex AI Notebook location."
}

variable "notebook_machine_type" {
  type        = string
  default     = "e2-highmem-4"
  description = "Vertex AI Notebook machine type."
}

variable "notebook_vm_image_project" {
  type        = string
  default     = "deeplearning-platform-release"
  description = "Vertex AI Notebook VM image project."
}

variable "notebook_vm_image_family" {
  type        = string
  default     = "common-cpu-notebooks"
  description = "Vertex AI Notebook VM image family."
}

variable "notebook_boot_disk_type" {
  type        = string
  default     = "PD_STANDARD"
  description = "Vertex AI Notebook VM boot disk type."
}

variable "notebook_data_disk_type" {
  type        = string
  default     = "PD_STANDARD"
  description = "Vertex AI Notebook VM data disk type."
}

variable "notebook_network" {
  type        = string
  description = "Vertex AI Notebook network."
}

variable "notebook_subnet" {
  type        = string
  description = "Vertex AI Notebook subnet."
}

variable "autoshutdown_counter_threshold" {
  type        = number
  default     = 360
  description = "Maximum amount of inactivity events. Once maximum number are achieved, the VM is shut down."
}
variable "autoshutdown_idle_timeout_seconds" {
  type        = number
  default     = 10
  description = "Time threshold to assign a notebook or terminal last activity date as inactive."
}
variable "autoshutdown_sleep_seconds" {
  type        = number
  default     = 10
  description = "Time interval between autoshutdown inactivity checks."
}

variable "accelerator_config" {
  type = object({
    accelerator_type  = string
    accelerator_count = number
  })
  default = null
}

variable "notebook_metadata" {
  type    = map(string)
  default = null
}

variable "enable_secure_boot" {
  type    = bool
  default = true
}
