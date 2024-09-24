# Helm Chart

## Disclaimer

### New customers

This is the most advanced way to install Secoda. Secoda can help with Secoda-specific issues, but we suggest retaining Kubernetes consultants for the expertise to maintain this cluster. If you are new to Secoda or Kubernetes, we recommend you proceed with [docker-compose](https://github.com/secoda/docker-compose) solution.

## Prerequisites

- You will need to contact us for your company-specific Docker registry token.
- A PostgreSQL database.
We recommend using an externally managed postgres database with backups enabled (for example, AWS RDS) as persistent volumes are not as reliable.
The version we suggest is `>= 14`.
- An Opensearch cluster (single-node is fine).
We recommend using an externally managed Opensearch cluster with backups enabled (for example, AWS Opensearch) as persistent volumes are not as reliable.
The version we suggest is `2.6.0`.
- This chart runs Secoda in a single pod and requires about *4 vCPU* and *16 GB memory*.


## Setup

Once your database is created, connect to it and then create the keycloak user and two seperate databases on it.

```bash
psql -h <HOST> -U postgres
```

```bash
create database keycloak;
create database secoda;
create user keycloak with encrypted password '<SAME_PASSWORD_AS_DEFINED_IN_PREDEFINED-SECRETS.YAML>';
grant all privileges on database keycloak to keycloak;
grant all privileges on database secoda to keycloak;
```

## Usage

1.  Run this command `git clone https://github.com/secoda/helm.git`

2. Modify the `examples/predefined-secrets.yaml` file. Replace all values that have a comment next to them.

3. Create a secret for the ingress certificate:
```bash
# We suggest using a proper, signed certificate for production environments.
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=CommonNameOrHostname"
kubectl create secret tls lb \
--key key.pem \
--cert cert.pem
```

4. Specify the name of the SSL certificate to use as the value of `ingress.tls.secretName`. The default is `lb`, set in the previous step.

5. GKE-specific configurations:

- Specify `/*` as the value of `ingress.hosts.paths.path`.
- The field `ingress.tls.servicePort` is not required.
- (Optional) Follow SQL Auth Proxy [guide](https://cloud.google.com/sql/docs/postgres/connect-kubernetes-engine) and enable `cloudSqlAuthProxy.enabled` and modify `cloudSqlAuthProxy.databaseName`.

6.  Add your customer-specific docker secret, this is required to pull Secoda's images:

        $ kubectl create secret docker-registry secoda-dockerhub --docker-server=https://index.docker.io/v1/ --docker-username=secodaonpremise --docker-password=<CUSTOMER_SPECIFIC_TOKEN_PROVIDED_BY_SECODA> --docker-email=carter@secoda.co

7.  Now you're ready to install Secoda:

        $ gcloud container clusters get-credentials <CLUSTER> --region <REGION> # Only if using GKE.
        $ cd helm/helm/charts
        $ helm install -f secoda/examples/predefined-secrets.yaml secoda ./secoda

## Contributing

Install these tools:

```bash
brew install pre-commit
pre-commit install
```

## Troubleshooting

If testing locally with minikube, you can port-forward the service to your local machine:
```
minikube service secoda
```
Then connect over `https` on the provided `tunnel` url.

If you are getting the status error `ImagePullBackOff`. It usually has to do with Docker access token issues. Check the following:
* `imagePullSecrets` must all be in the same namespace as the Pod.
* Confirm the docker secret has been created: `kubectl get secrets` and `kubectl get secret secoda-dockerhub`

## Cheatsheet

        $ kubectl get pods
        $ kubectl describe pods
        $ kubectl describe deployment
        $ kubectl get services
        $ kubectl logs <POD_NAME> api