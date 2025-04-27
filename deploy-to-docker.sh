#!/bin/bash

echo "➡️ Entrez le numéro de version (ex: v3, v4, etc.): "
read VERSION

# Définir les variables
IMAGE_NAME="walidbensmida/devops-training"

echo "➡️ Compilation du projet Maven..."
mvn clean install

echo "➡️ Construction de l'image Docker..."
docker build -t $IMAGE_NAME:latest -t $IMAGE_NAME:$VERSION .

echo "➡️ Push des images Docker (latest et $VERSION)..."
docker push $IMAGE_NAME:latest
docker push $IMAGE_NAME:$VERSION

echo "✅ Images poussées avec succès."

#echo "➡️ Redémarrage du déploiement Kubernetes..."
# 1. Connexion au cluster GKE
#gcloud container clusters get-credentials devops-training-cluster \
#  --zone europe-west1-b \
#  --project devops-training-project-458011
#kubectl rollout restart deployment devops-training

echo "✅ Déploiement terminé avec l'image $VERSION !"
