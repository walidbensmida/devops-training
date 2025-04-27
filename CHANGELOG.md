# Changelog

## v3 - [Deployment of Vault on GKE]

- Set up a Vault instance with a static IP
- Deployed Vault in dev mode with a readiness probe
- Exposed Vault via a GKE Ingress
- Configured backend HealthCheck for GKE
- Added Vault access via local domain `vault.devops.local`
- Validated access to Vault web interface with root token `myroot`
