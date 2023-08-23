# terraform-gcp-user-managed-notebook
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 4.34 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 4.58.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_notebooks_instance.notebook_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/notebooks_instance) | resource |
| [google_project_iam_member.sa_user_to_user_managed_notebook](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.vertex_notebook_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.sa_user_to_user_managed_notebook](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_storage_bucket.vertex_nb_scripts](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_member.vertex_nb_scripts_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_storage_bucket_object.nb_autoshutdown_script](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_storage_bucket_object.nb_autoshutdown_service_script](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_storage_bucket_object.nb_startup_script](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_accelerator_config"></a> [accelerator\_config](#input\_accelerator\_config) | n/a | <pre>object({<br>    accelerator_type  = string<br>    accelerator_count = number<br>  })</pre> | `null` | no |
| <a name="input_autoshutdown_counter_threshold"></a> [autoshutdown\_counter\_threshold](#input\_autoshutdown\_counter\_threshold) | Maximum amount of inactivity events. Once maximum number are achieved, the VM is shut down. | `number` | `360` | no |
| <a name="input_autoshutdown_idle_timeout_seconds"></a> [autoshutdown\_idle\_timeout\_seconds](#input\_autoshutdown\_idle\_timeout\_seconds) | Time threshold to assign a notebook or terminal last activity date as inactive. | `number` | `10` | no |
| <a name="input_autoshutdown_sleep_seconds"></a> [autoshutdown\_sleep\_seconds](#input\_autoshutdown\_sleep\_seconds) | Time interval between autoshutdown inactivity checks. | `number` | `10` | no |
| <a name="input_default_region"></a> [default\_region](#input\_default\_region) | Default region for resource creation. | `string` | n/a | yes |
| <a name="input_enable_secure_boot"></a> [enable\_secure\_boot](#input\_enable\_secure\_boot) | n/a | `bool` | `true` | no |
| <a name="input_notebook_boot_disk_type"></a> [notebook\_boot\_disk\_type](#input\_notebook\_boot\_disk\_type) | Vertex AI Notebook VM boot disk type. | `string` | `"PD_STANDARD"` | no |
| <a name="input_notebook_data_disk_type"></a> [notebook\_data\_disk\_type](#input\_notebook\_data\_disk\_type) | Vertex AI Notebook VM data disk type. | `string` | `"PD_STANDARD"` | no |
| <a name="input_notebook_location"></a> [notebook\_location](#input\_notebook\_location) | Vertex AI Notebook location. | `string` | n/a | yes |
| <a name="input_notebook_machine_type"></a> [notebook\_machine\_type](#input\_notebook\_machine\_type) | Vertex AI Notebook machine type. | `string` | `"e2-highmem-4"` | no |
| <a name="input_notebook_metadata"></a> [notebook\_metadata](#input\_notebook\_metadata) | n/a | `map(string)` | `null` | no |
| <a name="input_notebook_name_to_email_map"></a> [notebook\_name\_to\_email\_map](#input\_notebook\_name\_to\_email\_map) | set with the reference of the owner emails.<br>    All notebook names will be prefixed with the local variable notebook\_name.<br>    Example:<br>      [<br>        "name@astrafy.io"<br>      ] | `set(string)` | n/a | yes |
| <a name="input_notebook_network"></a> [notebook\_network](#input\_notebook\_network) | Vertex AI Notebook network. | `string` | n/a | yes |
| <a name="input_notebook_subnet"></a> [notebook\_subnet](#input\_notebook\_subnet) | Vertex AI Notebook subnet. | `string` | n/a | yes |
| <a name="input_notebook_vm_image_family"></a> [notebook\_vm\_image\_family](#input\_notebook\_vm\_image\_family) | Vertex AI Notebook VM image family. | `string` | `"common-cpu-notebooks"` | no |
| <a name="input_notebook_vm_image_project"></a> [notebook\_vm\_image\_project](#input\_notebook\_vm\_image\_project) | Vertex AI Notebook VM image project. | `string` | `"deeplearning-platform-release"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP Project ID where resources will be deployed. | `string` | n/a | yes |
| <a name="input_usecase_name"></a> [usecase\_name](#input\_usecase\_name) | Name of the use case (used for labels) | `string` | `"dev"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_service_accounts"></a> [service\_accounts](#output\_service\_accounts) | Service accounts created |
| <a name="output_user_notebook_names"></a> [user\_notebook\_names](#output\_user\_notebook\_names) | Created User-Managed Notebook names |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
