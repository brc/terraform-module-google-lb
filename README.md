# Terraform module for GCP External HTTPS Load Balancer

## Inputs

See [`./lb/vars.tf`](./lb/vars.tf):

Name | Description | Required
---- | ----------- | --------
`lb_name` | Name of external load balancer to create | Yes
`lb_addr_name` | Name of external IP address to create | Yes
`lb_backend_name` | Name of Back-end service to create | Yes
`lb_neg_list` | List of NEG objects to create for back-end | Yes
`lb_frontend_name` | Name of front-end service (Forwarding Rule) to create | Yes
`lb_proxy_name` | Name of HTTPS Target Proxy to create | Yes
`lb_tls_cert_name` | Name of SSL Certificate resource to create | Yes
`lb_tls_secret` | Name of GCS secret containing TLS RSA private key | Yes

## Requirements

### TLS certificate file created in advance

A file named `cert.pem` needs to exist in the CWD of wherever Terraform is being
invoked (sorry, PoC!).

### TLS private key in GCP Secret Manager

The TLS certificate PEM is revision-controlled in this repo, but the RSA private
key is stored as a secret in GCP and is retrieved by the `lb` module.

### Provider config

This module doesn't specify a provider nor pin versions; that is currently done
by the caller (consumer) of this module, which is
[terraform-helloworld-web](https://github.com/invsblduck/terraform-helloworld-web).

(PoC!)

# TODO

- Add `examples/` and `tests/`
- Automate testing with GitOps via GCP Cloud Build

# Background info

The following `gcloud` commands were used to experiment and "prove out" a
working GCP external load balancer with multi-region Cloud Run NEGs (Network
Endpoint Groups) before developing the Terraform module to accomplish the same
idempotently:

```bash
# Generate self-signed cert (hint: '-nodes' means "No DES")
openssl req -x509 \
    -newkey rsa:2048 \
    -keyout key.pem \
    -out cert.pem \
    -nodes \
    -days 365

# Create SSL cert resource
gcloud compute ssl-certificates create ssl-helloworld \
    --certificate=cert.pem --private-key=key.pem --global

# Reserve global anycast IPv4 address
gcloud compute addresses create --global addr-helloworld-fe

# Create Serverless NEGs
gcloud compute network-endpoint-groups create neg-helloworld-uswest \
    --region=us-west2 \
    --network-endpoint-type=SERVERLESS \
    --cloud-run-service=helloworld-dev-pr5 

# Create back-end service
gcloud compute backend-services create --global be-helloworld

# add SNEGs
gcloud compute backend-services add-backend --global be-helloworld \
    --network-endpoint-group-region=us-west2 \
    --network-endpoint-group=neg-helloworld-uswest

# Create URL map
gcloud compute url-maps create lb-helloworld --default-service=be-helloworld

# Create HTTPS target proxy
gcloud compute target-https-proxies create proxy-helloworld \
  --ssl-certificates=ssl-helloworld \
  --url-map=lb-helloworld

# Create Forwarding rule
gcloud compute forwarding-rules create --global fe-helloworld \
  --target-https-proxy=proxy-helloworld \
  --address=addr-helloworld-fe \
  --ports=443
```
