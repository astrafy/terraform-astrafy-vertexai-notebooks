# terraform-gcp-user-managed-notebook

## Usage
To use the module please refer to the example below. Be aware that some unmentioned variables have default values associated, please refer to the [Inputs](#inputs) section.


example `main.tf` file:
```hcl
provider "google" {
    project = "project-name"
    region = "EU"
}

module "terraform-gcp-user-managed-notebook" {
    source = "terraform.richemont.com/Richemont-International-SA/user-managed-notebook/gcp"
    version = "0.5.0"
    project_id = "example-project-id"
    default_region = "eu-west3"
    # notebook config
    notebook_name_to_email_map = {
        "user1" : "user1@email.com",
        "user2" : "user2@email.com"
    }
    notebook_location = "europe-west3-a"
    notebook_network = "example-network"
    notebook_subnet = "example-subnet"
    # startup script proxy and no_proxy assignments
    proxy = "proxy_address"
    no_proxy = "no_proxy_address1,no_proxy_address2"
    # zscaler certificate
    bootstrap_bucket    = "boostrap-bucket-name"
    bootstrap_cert_file = "zscaler.cert"
    autoshutdown_counter_threshold    = 60
    autoshutdown_idle_timeout_seconds = 60
    autoshutdown_sleep_seconds        = 60
    nb_group_name                     = "nbgroup"
    access_group_email_set            = toset(["group1@email.com", "group2@email.com"])

}

```
Note: if using from gitlab the source should be 
```hcl
module "terraform-gcp-user-managed-notebook" {
    source = "git::ssh://git@gitlab.richemont.com/tfe_modules_project/grp-ric-tfe-modules-AI_COE/terraform-gcp-user-managed-notebook.git?ref=v0.4.2"
    ...
}
```

To create a GPU-enabled VM be sure to add the `accelerator_config` argument and choose the appropriate accelerator, notebook location and vm image. More info at https://cloud.google.com/vertex-ai/docs/general/locations#europe_2.
An example below:

```hcl
module "terraform-gcp-user-managed-notebook" {
    source = "terraform.richemont.com/Richemont-International-SA/user-managed-notebook/gcp"
    version = "0.5.0"
    project_id = "example-project-id"
    default_region = "eu-west3"
    # notebook config
    notebook_name_to_email_map = {
        "user1" : "user1@email.com",
        "user2" : "user2@email.com"
    }
    notebook_network = "example-network"
    notebook_subnet = "example-subnet"
    # startup script proxy and no_proxy assignments
    proxy = "proxy_address"
    no_proxy = "no_proxy_address1,no_proxy_address2"
    # zscaler certificate
    bootstrap_bucket    = "boostrap-bucket-name"
    bootstrap_cert_file = "zscaler.cert"
    autoshutdown_counter_threshold    = 60
    autoshutdown_idle_timeout_seconds = 60
    autoshutdown_sleep_seconds        = 60
    nb_group_name                     = "nbgroup"
    access_group_email_set            = toset(["group1@email.com", "group2@email.com"])
    
    # for GPU usage refer to the supported GPUs per location
    notebook_location                 = "europe-west3-b" 
    notebook_machine_type             = "n1-standard-4"
    notebook_vm_image_project         = "deeplearning-platform-release"
    notebook_vm_image_family          = "tf-latest-gpu"
    accelerator_config                = { "accelerator_type" : "NVIDIA_TESLA_T4", "accelerator_count" : 1 }
}
```

## Useful commands

### Refresh Zscaler Certificate
If the Zscaler certificate, present in your sourced bucket, is updated then the following actions will be performed:

* The Terraform run will verify a new file in the source bucket
* Terraform will update the certificate in the notebook scripts bucket
* The user can run the `refresh_zscaler_cert` bash function

### Refresh Autoshutdown service
If the Autoshutdown script and service, present in your notebook scripts bucket, are updated then the following actions will be performed:

* The Terraform run will verify a new file in the notebook scripts bucket
* Terraform will update the files in the notebook scripts bucket
* The user can run the `refresh_autoshutdown` bash function

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 4.34 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 4.53.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_notebooks_instance.notebook_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/notebooks_instance) | resource |
| [google_service_account.vertex_notebook_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.sa_user_to_user_managed_notebook](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_storage_bucket.vertex_nb_scripts](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_member.vertex_nb_scripts_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_storage_bucket_object.nb_autoshutdown_script](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_storage_bucket_object.nb_autoshutdown_service_script](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_storage_bucket_object.nb_startup_script](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_storage_bucket_object.zscaler-certificate-target](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_storage_bucket_object_content.zscaler-certificate-source](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/storage_bucket_object_content) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_accelerator_config"></a> [accelerator\_config](#input\_accelerator\_config) | n/a | <pre>object({<br>    accelerator_type  = string<br>    accelerator_count = number<br>  })</pre> | `null` | no |
| <a name="input_access_group_email_set"></a> [access\_group\_email\_set](#input\_access\_group\_email\_set) | Emails of groups to give service account user role. | `set(string)` | n/a | yes |
| <a name="input_autoshutdown_counter_threshold"></a> [autoshutdown\_counter\_threshold](#input\_autoshutdown\_counter\_threshold) | Maximum amount of inactivity events. Once maximum number are achieved, the VM is shut down. | `number` | `360` | no |
| <a name="input_autoshutdown_idle_timeout_seconds"></a> [autoshutdown\_idle\_timeout\_seconds](#input\_autoshutdown\_idle\_timeout\_seconds) | Time threshold to assign a notebook or terminal last activity date as inactive. | `number` | `10` | no |
| <a name="input_autoshutdown_sleep_seconds"></a> [autoshutdown\_sleep\_seconds](#input\_autoshutdown\_sleep\_seconds) | Time interval between autoshutdown inactivity checks. | `number` | `10` | no |
| <a name="input_bootstrap_bucket"></a> [bootstrap\_bucket](#input\_bootstrap\_bucket) | Bootstrap bucket name. | `string` | n/a | yes |
| <a name="input_bootstrap_cert_file"></a> [bootstrap\_cert\_file](#input\_bootstrap\_cert\_file) | Bootstrap Zscaler certificate file. | `string` | n/a | yes |
| <a name="input_default_region"></a> [default\_region](#input\_default\_region) | Default region for resource creation. | `string` | n/a | yes |
| <a name="input_enable_secure_boot"></a> [enable\_secure\_boot](#input\_enable\_secure\_boot) | n/a | `bool` | `true` | no |
| <a name="input_nb_group_name"></a> [nb\_group\_name](#input\_nb\_group\_name) | Distinct group name for the group of Vertex AI notebooks. | `string` | n/a | yes |
| <a name="input_no_proxy"></a> [no\_proxy](#input\_no\_proxy) | No proxy string value to assign the NO\_PROXY environmental variable. | `string` | n/a | yes |
| <a name="input_notebook_boot_disk_type"></a> [notebook\_boot\_disk\_type](#input\_notebook\_boot\_disk\_type) | Vertex AI Notebook VM boot disk type. | `string` | `"PD_STANDARD"` | no |
| <a name="input_notebook_data_disk_type"></a> [notebook\_data\_disk\_type](#input\_notebook\_data\_disk\_type) | Vertex AI Notebook VM data disk type. | `string` | `"PD_STANDARD"` | no |
| <a name="input_notebook_location"></a> [notebook\_location](#input\_notebook\_location) | Vertex AI Notebook location. | `string` | n/a | yes |
| <a name="input_notebook_machine_type"></a> [notebook\_machine\_type](#input\_notebook\_machine\_type) | Vertex AI Notebook machine type. | `string` | `"e2-highmem-4"` | no |
| <a name="input_notebook_metadata"></a> [notebook\_metadata](#input\_notebook\_metadata) | n/a | `map(string)` | `null` | no |
| <a name="input_notebook_name_to_email_map"></a> [notebook\_name\_to\_email\_map](#input\_notebook\_name\_to\_email\_map) | Mapping with the reference of the notebook suffix as keys, and their respective owner emails as values.<br>    All notebook names will be prefixed with the local variable notebook\_name.<br>    Example:<br>      {<br>        "dp": "somebody@email.com"<br>      }<br>    Will produce a notebook named `vert-<nb-group-name>-dp`. | `map(string)` | n/a | yes |
| <a name="input_notebook_network"></a> [notebook\_network](#input\_notebook\_network) | Vertex AI Notebook network. | `string` | n/a | yes |
| <a name="input_notebook_subnet"></a> [notebook\_subnet](#input\_notebook\_subnet) | Vertex AI Notebook subnet. | `string` | n/a | yes |
| <a name="input_notebook_vm_image_family"></a> [notebook\_vm\_image\_family](#input\_notebook\_vm\_image\_family) | Vertex AI Notebook VM image family. | `string` | `"common-cpu-notebooks"` | no |
| <a name="input_notebook_vm_image_project"></a> [notebook\_vm\_image\_project](#input\_notebook\_vm\_image\_project) | Vertex AI Notebook VM image project. | `string` | `"deeplearning-platform-release"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP Project ID where resources will be deployed. | `string` | n/a | yes |
| <a name="input_proxy"></a> [proxy](#input\_proxy) | Proxy string value to assign the HTTP\_PROXY and HTTPS\_PROXY environmental variables. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_user_notebook_names"></a> [user\_notebook\_names](#output\_user\_notebook\_names) | Created User-Managed Notebook names |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
