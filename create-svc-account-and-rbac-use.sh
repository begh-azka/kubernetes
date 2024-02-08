kubectl create serviceaccount jenkins --dry-run=client -o yaml > jenkins-sa.yml
kubectl apply -f jenkins-sa.yml
---------------------------------------------------------------
# Either
---------------------------------------------------------------
TOKEN=$(kubectl create token jenkins)
kubectl config set-credentials jenkins --token=$TOKEN
---------------------------------------------------------------
# OR
---------------------------------------------------------------
# Create a secret object of the type service-account-token

cat <<EOT>> ./secret-sa.yml
apiVersion: v1
kind: Secret
metadata:
 name: jenkins-secret
 annotations:
  kubernetes.io/service-account.name: jenkins
type: kubernetes.io/service-account-token
EOT
--------------------------------------------------------------------------
kubectl apply -f secret-sa.yml
kubectl get secret secret-sa -o jsonpath="{.data.token}" | base64 -d        -> get the token
------------------------------------------------------------------------
kubectl create role serviceaccountrole --verb=create,list,get --resource=pods,pods/log --namespace=default --dry-run=client -o yaml > role.yml 
kubectl create rolebinding servicerolebind --role=serviceaccountrole --serviceaccount=default:jenkins --dry-run=client -o yaml > rolebind.yml 
kubectl apply -f role.yml 
kubectl apply -f rolebind.yml 

kubectl config current-context
kubectl config set-context jenkins-context --cluster=k8skops.aab12.xyz --user=jenkins
kubectl config get-contexts

kubectl auth can-i create deployments --namespace=default --as=jenkins
kubectl auth can-i create secrets --namespace=default --as=jenkins
kubectl auth can-i get pods --namespace=default --as=jenkins

kubectl config use-context jenkins-context
kubectl get pods
