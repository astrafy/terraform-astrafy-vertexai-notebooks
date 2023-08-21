output "user_notebook_names" {
  value       = [for notebook in google_notebooks_instance.notebook_instance : notebook.name]
  description = "Created User-Managed Notebook names"
}

output "service_accounts" {
  value       = google_service_account.vertex_notebook_sa
  description = "Service accounts created"
}
