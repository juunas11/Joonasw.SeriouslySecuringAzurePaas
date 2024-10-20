# Joonasw.SeriouslySecuringAzurePaas

Demo for Cloudbrew 2024

A certificate is needed to encrypt the connections between users and the Application Gateway.
I used Let's Encrypt through an ACME client to get one (90 days more than enough to be valid until the conference is done).
The certificate is expected in "deployment/cert.pfx".

The "EnableApplicationGatewayNetworkIsolation" preview flag must be currently enabled on the subscription to deploy the Application Gateway WAF with no public endpoints.