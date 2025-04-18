# TLS Certificates

More information on [Elastic Cloud Kubernetes TLS configuration](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-tls-certificates.html) can be found here.

## Self-Signed Certificate (Development)

For development purposes, we will use `mkcert` to generate a self-signed CA, wildcard certificate, and key to be used by the Elastic resources.

- [mkcert](https://github.com/FiloSottile/mkcert)

1. Install `mkcert`. This guide is for Mac, but other install options can be found on the [mkcert GitHub](https://github.com/FiloSottile/mkcert).

   `brew install mkcert`

2. Set up `mkcert`. This installs the local CA into the system trust store.

   `mkcert install`

3. Generate self-signed certs for Elastic resources managed by ECK.

   `mkcert -key-file elastic/certificates/tls.key -cert-file elastic/certificates/tls.crt '*.es.eck.dev' '*.kb.eck.dev' '*.fleet.eck.dev' '*.apm.eck.dev' '*.ls.eck.dev'`

4. Copy the new root CA to the certificates directory.

   `cp "$(mkcert -CAROOT)/rootCA.pem" ./elastic/certificates/ca.crt`

5. Create Kubernetes Secrets that will be used for TLS.

   > Monitoring Namespace

   `kubectl -n monitoring create secret generic eck-certificate --from-file=elastic/certificates/ca.crt --from-file=elastic/certificates/tls.crt --from-file=elastic/certificates/tls.key`

   > Deployments Namespace

   `kubectl -n deployments create secret generic eck-certificate --from-file=elastic/certificates/ca.crt --from-file=elastic/certificates/tls.crt --from-file=elastic/certificates/tls.key`

## Bring your own CA & Certificate (Production)

It is strongly advised to use your own certificates, which are trusted within your environment. The following will be required for this guide:

- `tls.key` - The Key
- `tls.crt` - The Certificate
- `ca.crt` - The CA certificate that signed the certificate

The certificate should be configured with the following SANs:

- `*.es.<your domain>`
- `*.kb.<your domain>`
- `*.fleet.<your domain>`
- `*.apm.<your domain>`
- `*.ls.<your domain>`

For example:

- `*.es.eck.elastic.co`
- `*.kb.eck.elastic.co`
- `*.fleet.eck.elastic.co`
- `*.apm.eck.elastic.co`
- `*.ls.eck.elastic.co`

Once you have the required files, you can create a Kubernetes secret with them using the following commands:

> Monitoring Namespace

`kubectl -n monitoring create secret generic eck-certificate --from-file=elastic/certificates/ca.crt --from-file=elastic/certificates/tls.crt --from-file=elastic/certificates/tls.key`

> Deployments Namespace

`kubectl -n deployments create secret generic eck-certificate --from-file=elastic/certificates/ca.crt --from-file=elastic/certificates/tls.crt --from-file=elastic/certificates/tls.key`

We are creating two secrets, one in each namespace where Elastic resources will be deployed, as secrets are namespace-bound.

## Configure Elastic resources to use the certificate

More detailed information can be found within the [Elastic Cloud Kubernetes documentation](https://www.elastic.co/docs/deploy-manage/security/k8s-https-settings).

To have Elastic resources use this new certificate, add the following to the Elastic resource manifest:

```
http:
   tls:
      certificate:
         secretName: eck-certificate
```

The resource manifest should look something like the following:

```
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: monitoring-deployment
  namespace: monitoring
spec:
  version: 8.17.4
  count: 1
  elasticsearchRef:
    name: monitoring-deployment
  podTemplate:
    spec:
      containers:
      - name: kibana
        env:
          - name: NODE_OPTIONS
            value: "--max-old-space-size=1024"
        resources:
          requests:
            memory: 1Gi
            cpu: 0.5
          limits:
            memory: 1Gi
            cpu: 1
  http:
    tls:
      certificate:
        secretName: eck-certificate
```
