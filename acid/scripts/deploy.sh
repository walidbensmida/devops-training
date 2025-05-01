#!/bin/bash

echo "Déploiement de l'infrastructure Kubernetes..."

# Jenkins Configuration as Code
#kubectl apply -f ../jenkins/jenkins-casc.yaml
#kubectl apply -f ../jenkins/jenkins-casc-secrets.yaml

# Vault
kubectl apply -f ../k8s/vault/vault-backendconfig.yaml
kubectl apply -f ../k8s/vault/vault-deployment.yaml
kubectl apply -f ../k8s/vault/vault-service.yaml
kubectl apply -f ../k8s/vault/vault-ingress.yaml

# Jenkins
kubectl apply -f ../k8s/jenkins/jenkins-backendconfig.yaml
kubectl apply -f ../k8s/jenkins/jenkins-pvc.yaml
kubectl apply -f ../k8s/jenkins/jenkins-deployment.yaml
kubectl apply -f ../k8s/jenkins/jenkins-service.yaml
kubectl apply -f ../k8s/jenkins/jenkins-ingress.yaml

# DevOps Training App
kubectl apply -f ../k8s/devops-training/deployment.yaml
kubectl apply -f ../k8s/devops-training/service.yaml
kubectl apply -f ../k8s/devops-training/ingress.yaml

echo "✅ Déploiement terminé avec succès !"
