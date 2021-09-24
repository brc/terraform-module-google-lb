resource "google_compute_region_network_endpoint_group" "neg" {
  for_each              = { for n in var.lb_negs_list : n.name => n }
  name                  = each.value.name
  region                = each.value.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = each.value.run_svc
  }
}
