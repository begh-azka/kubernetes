1. First, Generate a private key for the new user using OpenSSL:

openssl genpkey -out john.key -algorithm Ed25519

2. Generate Certificate Signing Request (CSR) from the private key:

openssl req -new -key john.key -out john.csr -subj "/CN=john,/O=edit"

3. Encode the CSR file

# Will encode and print the base64 code. Copy and paste in the certificatesigningrequest resource's field request below

cat john.csr | base64 | tr -d "\n" 

4. Now create CertificateSigningRequest object in the Kubernetes

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: john
spec:
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlHZU1GSUNBUUF3SHpFT01Bd0dBMVVFQXd3RmFtOW9iaXd4RFRBTEJnTlZCQW9NQkdWa2FYUXdLakFGQmdNcgpaWEFESVFEbk9nYXEzSEcyMkw1dFROZ0JaQ1lHYkJiSjdXQ05BTmE2aWhsNll0NWFkNkFBTUFVR0F5dGxjQU5CCkFPeVJaZlpKY2c3eE90eHBjUmFqZmlySk9WcVkvaE9CQldneEJubERFek4rbXpJRm12MkU5czNoaXBQZjBOYk8KMkNrR0pNR0NhOXJabStVRHowelhqZ009Ci0tLS0tRU5EIENFUlRJRklDQVRFIFJFUVVFU1QtLS0tLQo=
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF

5. Approve the Certificate Signing Request
kubectl certificate approve john

kubectl describe csr/john 

6. Get the certificate of the user
kubectl get csr/john -o jsonpath="{.status.certificate}" | base64 -d > john.crt

cp ~/.kube/config john-kube-config   #always backup
kubectl config get-clusters
kubectl api-resources -o wide

# Not using the main config, using the backed up one
# ADD CERT TO CONFIG FILE - Optional
kubectl config set-credentials john --client-key john.key --client-certificate john.csr --embed-certs=true

Get Users in K8s: kubectl config get-users

7. Create Role and RoleBinding

kubectl create role pod-manager --verb=create,list,get --resource=pods --namespace=default --dry-run=client -o yaml > pod-manager-role.yml
kubectl create rolebinding bind-pod-manager --role=pod-manager --user=john --dry-run=client -o yaml > pod-manager-rolebind.yml

kubectl apply -f pod-manager-role.yml
kubectl apply -f pod-manager-rolebind.yml

8. Validate the user's access

kubectl auth can-i create deployments --namespace=default --as=john
kubectl auth can-i create secrets --namespace=default --as=john
kubectl auth can-i get pods --namespace=default --as=john

9. Create New Context in config file
kubectl config set-context john-context --cluster=k8skops.aab12.xyz --user=john --namespace=default
kubectl config get-contexts

10. Switch to the new context
kubectl config use-context john-context

11. Run command to check your access
kubectl get pods
