# This script generates needed certificates consumed by the infrastructure ingresses.
# This script is autoloaded.

CERTIFICATE_DATA = {
    # key, value             -> domain, cert secret name
    "demblock.com"            : "demblock-cert",
    "backend-demblock.com"    : "backend-demblock-cert",
    "demblock-tge.com"        : "demblock-tge-cert",
    "backend.demblock-tge.com": "backend-demblock-tge-cert",
    "token.demblock-tge.com"  : "token-demblock-tge-cert",
}

def generate_certs():
    result = ""
    for domain, secret_name in CERTIFICATE_DATA.items():
        result += """
apiVersion: networking.gke.io/v1beta1
kind: ManagedCertificate
metadata:
  name: {0}
spec:
  domains:
    - {1}
---
        """.format(secret_name, domain)
    return result

if __name__ == "__main__":
    print(generate_certs())
