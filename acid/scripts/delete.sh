#!/bin/bash

echo "🔄 Suppression de l'infrastructure Jenkins, Vault et App..."

# Vault
kubectl delete -f acid/k8s/vault/vault-ingress.yaml
kubectl delete -f acid/k8s/vault/vault-service.yaml
kubectl delete -f acid/k8s/vault/vault-deployment.yaml
kubectl delete -f acid/k8s/vault/vault-backendconfig.yaml

# Jenkins
kubectl delete -f acid/k8s/jenkins/jenkins-ingress.yaml
kubectl delete -f acid/k8s/jenkins/jenkins-service.yaml
kubectl delete -f acid/k8s/jenkins/jenkins-deployment.yaml
kubectl delete -f acid/k8s/jenkins/jenkins-backendconfig.yaml
# ❗ Ne supprime PAS le PVC Jenkins
# kubectl delete -f acid/k8s/jenkins/jenkins-pvc.yaml

# Devops Training App
kubectl delete -f acid/k8s/devops-training/ingress.yaml
kubectl delete -f acid/k8s/devops-training/service.yaml
kubectl delete -f acid/k8s/devops-training/deployment.yaml

# Secrets + Config pour Jenkins
kubectl delete -f acid/jenkins/jenkins-casc-secrets.yaml
# Si tu utilises configmap (pas GitHub) :
# kubectl delete -f acid/jenkins/jenkins-casc-configmap.yaml

echo "✅ Suppression terminée (PVC Jenkins conservé)"
