output "user_notebook_names" {
  value       = [for notebook in google_notebooks_instance.notebook_instance : notebook.name]
  description = "Created User-Managed Notebook names"
}