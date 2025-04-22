// outputs.tf
output "service_endpoint_id" {
  value = module.tls_cert_service_conn_federated[0].service_endpoint_id
}

output "service_endpoint_name" {
  value = module.tls_cert_service_conn_federated[0].service_endpoint_name
}

output "identity_app_name" {
  value       = module.tls_cert_service_conn_federated[0].identity_app_name
  description = "User Managed Identity name"
}

output "identity_client_id" {
  value       = module.tls_cert_service_conn_federated[0].identity_client_id
  description = "The ID of the app associated with the Identity."
}

output "identity_principal_id" {
  value       = module.tls_cert_service_conn_federated[0].identity_principal_id
  description = "The ID of the Service Principal object associated with the created Identity."
}

output "service_principal_object_id" {
  value       = module.tls_cert_service_conn_federated[0].service_principal_object_id
  description = "The ID of the Service Principal object associated with the created Identity."
}
