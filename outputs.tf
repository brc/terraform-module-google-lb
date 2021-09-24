output "address" {
  value       = google_compute_global_address.default.address
  description = "IPv4 address of load balancer"
}
