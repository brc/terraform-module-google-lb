# variable "lb_frontend_name" {
#   description = "Name of front-end"
#   type        = string
# }

# variable "lb_proxy_name" {
#   description = "Name of HTTPS target proxy"
#   type        = string
# }

variable "lb_name" {
  description = "Name of external load balancer"
  type        = string
}

variable "lb_addr_name" {
  description = "Name of external IP address"
  type        = string
}

variable "lb_tls_cert_name" {
  description = "Name of TLS certificate resource"
  type        = string
}

variable "lb_tls_secret" {
  description = "Name of secret which holds TLS private key"
  type        = string
}

variable "lb_negs_list" {
  description = "List of NEG objects to be used in back-end"
  type        = list(object({
    name    = string
    region  = string
    run_svc = string
  }))
}

variable "lb_backend_name" {
  description = "Name of back-end service"
  type        = string
}
