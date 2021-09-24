/* Set up IP address
 */
resource "google_compute_global_address" "default" {
  name = var.lb_addr_name
}

/* Set up TLS certificate
 */
data "google_secret_manager_secret_version" "tls_key" {
  secret = var.lb_tls_secret
}

resource "google_compute_ssl_certificate" "default" {
  name        = var.lb_tls_cert_name
  private_key = data.google_secret_manager_secret_version.tls_key.secret_data
  certificate = file("${path.cwd}/cert.pem")

  // SSL certificates cannot be updated after creation. In order to apply
  // the specified configuration, Terraform will destroy the existing
  // resource and create a replacement. To effectively use an SSL
  // certificate resource with a Target HTTPS Proxy resource, it's
  // recommended to specify create_before_destroy in a lifecycle block.
  lifecycle {
    create_before_destroy = true
  }
}

/* Set up NEGs (Network Endpoint Groups)
 */
resource "google_compute_region_network_endpoint_group" "neg" {
  for_each = { for n in var.lb_negs_list : n.name => n }

  name                  = each.value.name
  region                = each.value.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = each.value.run_svc
  }
}

/* Set up back-end service
 */
resource "google_compute_backend_service" "default" {
  name = var.lb_backend_name

  dynamic "backend" {
    for_each = google_compute_region_network_endpoint_group.neg
    content {
      group = backend.value.id
    }
  }
}

/* Set up URL map
 */
resource "google_compute_url_map" "default" {
  name            = var.lb_name
  default_service = google_compute_backend_service.default.self_link
}
