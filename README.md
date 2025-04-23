# Environnement de développement

## Étape 1 : Java + IDE
- Java 17 (JDK)
    - Va sur : https://adoptium.net/fr/temurin/releases/
    - Télécharge le JDK 17 pour Windows x64 (MSI)
    - Installe-le, puis vérifie dans le terminal :
      ```bash
      java -version
      ```

- IDE :
    - IntelliJ IDEA Community
    - Visual Studio Code (VS Code)

## Étape 2 : Docker + Kubernetes (Minikube)
- Docker Desktop
    - Télécharge ici : https://www.docker.com/products/docker-desktop/
    - Installe-le et active l’option Kubernetes dans les paramètres.
    - Vérifie l'installation :
      ```bash
      docker version
      kubectl version --client
      ```

Si tu préfères Minikube (cluster indépendant), passe à l'étape suivante.

## Étape 3 : Minikube (cluster Kubernetes local)
### Prérequis :
- Installe Chocolatey (terminal en tant qu’administrateur) :
  ```powershell
  Set-ExecutionPolicy Bypass -Scope Process -Force; `
  [System.Net.ServicePointManager]::SecurityProtocol = `
  [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
  iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
  ```
- Installe Minikube :
  ```powershell
  choco install minikube
  ```
- Lance Minikube :
  ```bash
  minikube start --driver=docker
  ```

## Étape 4 : Jenkins
- Option recommandée via Docker :
  ```bash
  docker run -d -p 8080:8080 -p 50000:50000 --name jenkins \
    -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts
  ```
- Accès Jenkins : http://localhost:8080

## Étape 5 : Vault (HashiCorp)
- Mode développement simple :
    - Télécharge ici : https://developer.hashicorp.com/vault/downloads
    - Décompresse l’exécutable (exemple : `C:\vault`)
    - Lance Vault :
      ```bash
      vault server -dev
      ```
    - Accède à Vault via http://127.0.0.1:8200 (token root dans la console)

## Étape 6 : WSL + Ansible
1. Activer WSL (PowerShell en administrateur) :
   ```powershell
   wsl --install
   ```
   Redémarre si demandé.

2. Installer Ubuntu via Microsoft Store.

3. Dans Ubuntu, exécute :
   ```bash
   sudo apt update
   sudo apt install ansible
   ansible --version
   ```

## Étape 7 : Terraform
- Va sur : https://developer.hashicorp.com/terraform/downloads
- Télécharge et décompresse l’exécutable (comme Vault).
- Ajoute le dossier contenant l'exécutable à ta variable `PATH`.
- Vérifie :
  ```bash
  terraform version
  ```
## Déploiement sur Minikube

1. Démarrer Minikube
  ```bash
minikube start
  ```
2. Activer le contrôleur Ingress
  ```bash

minikube addons enable ingress
  ```
3. Ajouter une entrée dans /etc/hosts

Ajoutez la ligne suivante pour simuler un nom de domaine :
  ```
127.0.0.1  devops.local
  ```

4. Appliquer les fichiers Kubernetes

Depuis la racine du projet :
  ```bash
kubectl apply -f acid/k8s/
  ```
5. Vérifier le déploiement
  ```bash
kubectl get pods
kubectl get svc
kubectl get ingress
  ```
6. Accéder à l'application

Dans un navigateur : http://devops.local