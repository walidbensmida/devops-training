# 📁 Dossier ACID – Méthodologie projet DevOps

Ce dossier contient la structure et le détail du projet selon la méthode ACID : **Analyse, Conception, Implémentation, Déploiement**.

---

## 🅰️ A – Analyse

### Objectifs du projet :

- Développer une API Spring Boot sécurisée avec Spring Security
- Centraliser la gestion des secrets avec HashiCorp Vault
- Dockeriser l’application pour faciliter les déploiements
- Déployer l’application sur Kubernetes (Minikube local ou AWS)
- Automatiser le pipeline de CI/CD avec Jenkins
- Intégrer Terraform et Ansible pour la gestion d’infrastructure

### Contraintes techniques :

- Application exposée sur le port `8081`
- Nom de l’application : `devops-training`
- L’environnement de dev est basé sur Windows 11 avec Docker Desktop et Minikube

---

## 🅲 C – Conception

### Architecture technique :

- **Backend** : Java 17 + Spring Boot 3.4.4
- **Secrets** : HashiCorp Vault (mode dev en local)
- **Conteneurisation** : Docker
- **Orchestration** : Kubernetes via Minikube
- **CI/CD** : Jenkins
- **IaC / automation** : Terraform, Ansible

### Fichiers clés à concevoir :

- `Dockerfile` : pour builder l’image de l’application
- `deployment.yaml` : déploiement Kubernetes
- `service.yaml` : exposition du pod en cluster
- `ingress.yaml` : routage via Ingress Controller
- `Jenkinsfile` : pipeline de build, test et déploiement

---

## 🅸 I – Implémentation

### Étapes réalisées :

- Création de l’application Spring Boot avec `/public` et `/private`
- Intégration de Spring Security avec credentials dynamiques depuis Vault
- Configuration de Vault en mode dev avec secret KV2 (`secret/app`)
- Écriture du `Dockerfile` + build de l’image
- Test de l’application dans Docker

### À implémenter :

- Fichiers YAML Kubernetes (Deployment, Service, Ingress)
- Pipeline Jenkins avec étapes : test → build Docker → push image → déploiement
- Utilisation de Terraform pour automatiser les manifestes (optionnel)
- Playbook Ansible pour automatiser config locale (Vault, Jenkins…)

---

## 🅳 D – Déploiement

### Environnement cible :

- Minikube (local Kubernetes)
- Vault local (HTTP, non SSL, token root en dev)
- Jenkins local via Docker

### Étapes de déploiement :

💬 Pour consulter les logs d’un pod :

```bash
kubectl logs <nom-du-pod>
```

Exemple :

```bash
kubectl logs devops-training-bcf6f6c97-wgwgg
```

Ou en mode temps réel :

```bash
kubectl logs -f devops-training-bcf6f6c97-wgwgg
```

1. Builder le jar avec `mvn clean package`
2. Construire l’image Docker : `docker build -t devops-training .`
3. Lancer en local pour test : `docker run -p 8081:8081 devops-training`
4. Déployer dans Kubernetes : `kubectl apply -f acid/k8s/`
5. Lancer le pipeline Jenkins : clone → test → build → deploy
6. Utiliser Ansible pour provisionner Jenkins et Vault

---

### 📁 Contenu du dossier `acid/k8s/`

#### `Dockerfile`

```dockerfile
FROM openjdk:17-jdk-slim

WORKDIR /app

COPY target/devops-training-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"]
```

🧠 **Explication ligne par ligne :**

- `FROM openjdk:17-jdk-slim` → Utilise une image de base Java 17 légère
- `WORKDIR /app` → Définit le répertoire de travail à l'intérieur du conteneur
- `COPY target/... app.jar` → Copie le fichier `.jar` généré dans le conteneur
- `EXPOSE 8081` → Indique à Docker que l’application écoute sur le port 8081
- `ENTRYPOINT` → Commande exécutée automatiquement au démarrage du conteneur

#### `deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
   name: devops-training
spec:
   replicas: 1
   selector:
      matchLabels:
         app: devops-training
   template:
      metadata:
         labels:
            app: devops-training
      spec:
         containers:
            - name: devops-training
              image: walid/devops-training:latest
              ports:
                 - containerPort: 8081
              env:
                 - name: SPRING_PROFILES_ACTIVE
                   value: "default"
                 - name: VAULT_TOKEN
                   valueFrom:
                      secretKeyRef:
                         name: vault-token-secret
                         key: VAULT_TOKEN
```

🧠 **Explication ligne par ligne :**

- `apiVersion: apps/v1` → Version stable de l’API Kubernetes pour un Deployment
- `kind: Deployment` → Type de ressource : un déploiement qui gère des pods
- `metadata.name` → Nom du déploiement dans le cluster
- `spec.replicas` → Nombre de pods que tu veux faire tourner (1 ici pour du local)
- `selector.matchLabels` et `template.metadata.labels` → Doivent correspondre pour lier le déploiement aux pods créés
- `spec.template.spec.containers` → Liste des conteneurs à lancer dans le pod
- `image` → Nom de l’image Docker à utiliser
- `containerPort` → Port exposé dans le pod (doit correspondre à celui de ton app)
- `env` → Variables d’environnement (ici, pour activer un profil Spring par exemple)

#### `service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: devops-training
spec:
  type: ClusterIP
  selector:
    app: devops-training
  ports:
    - protocol: TCP
      port: 8081
      targetPort: 8081
```

🧠 **Explication ligne par ligne :**

- `apiVersion: v1` → Version de l’API Kubernetes pour les objets de type `Service`
- `kind: Service` → Ce fichier définit un service, une ressource réseau interne à Kubernetes
- `metadata.name` → Le nom du service (utilisé par l’ingress ou d’autres pods)
- `spec.type: ClusterIP` → Le service est accessible uniquement dans le cluster (par défaut)
- `spec.selector.app` → Ce service cible les pods ayant le label `app=devops-training`
- `ports.port` → Le port exposé par le service (celui que les clients utiliseront dans le cluster)
- `ports.targetPort` → Le port sur lequel les pods écoutent réellement

🧠 **Pourquoi on a besoin du Service :**

- Les pods sont éphémères, leur IP peut changer → le Service fournit une IP ou un nom DNS stable
- Il permet la communication entre ressources du cluster
- Il est utilisé comme point de routage par l’Ingress
- Il agit comme un répartiteur de charge simple entre plusieurs pods (réplicas)

#### `ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: devops-training-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: devops.local
      http:
        paths:
          - path: /public
            pathType: Prefix
            backend:
              service:
                name: devops-training
                port:
                  number: 8081
```

🧠 **Explication ligne par ligne :**

- `apiVersion: networking.k8s.io/v1` → Version stable de l'API Kubernetes pour les objets Ingress.
- `kind: Ingress` → Cette ressource gère le routage HTTP/HTTPS depuis l'extérieur du cluster vers les services internes.
- `metadata.name` → Nom de l'Ingress, utilisé pour le référencer dans le cluster.
- `annotations` → Métadonnées utilisées par le contrôleur Ingress (ici NGINX). La réécriture d'URL `rewrite-target: /` permet à l'app de ne pas avoir à gérer les sous-chemins.
- `spec.rules` → Liste des règles de routage en fonction des hôtes (domaines).
- `host: devops.local` → Nom de domaine simulé en local, doit être ajouté dans `/etc/hosts` pour pointer vers Minikube.
- `http.paths` → Routes HTTP à rediriger.
- `path: /public` → L’Ingress n’interceptera que les requêtes `/public`
- `pathType: Prefix` → Type de correspondance du chemin (`Prefix` = tout ce qui commence par `/public`).
- `backend.service.name` → Le nom du service Kubernetes vers lequel on redirige les requêtes.
- `backend.service.port.number` → Le port utilisé par ce service (doit correspondre à `targetPort` dans le service).

---

### 🧠 Pourquoi utilise-t-on un Ingress ?

- L’Ingress permet d’exposer **plusieurs applications** sur un même point d’entrée HTTP (port 80 ou 443).
- Il agit comme un **reverse proxy** dans le cluster, généralement géré par NGINX ou Traefik.
- Il permet d’utiliser des **noms de domaine** pour accéder aux apps (ex: `devops.local`) au lieu de ports techniques.
- Il simplifie l’accès aux services : plus besoin de créer un `NodePort` ou `LoadBalancer` par application.
- En local avec Minikube, on doit activer l’addon Ingress (`minikube addons enable ingress`) et ajouter l’entrée `devops.local` dans le fichier `/etc/hosts`.

---

### 🚀 Déploiement sur Minikube

### ⚠️ Limitations connues sur Windows avec Minikube et Ingress

Sur Windows, avec Minikube (driver Docker Desktop), il peut arriver que l'Ingress Controller fonctionne dans le cluster, mais que le tunnel réseau Windows bloque l'accès externe à `devops.local`.

**Pourquoi ?**
- Minikube utilise un réseau interne Docker.
- Windows limite l'accès aux ports inférieurs à 1024 (80/443).
- Firewall Windows ou Docker peut bloquer l'exposition du service.

**Solutions :**
- Utiliser `minikube service devops-training` pour accéder à l'application localement.
- Continuer la formation sans bloquer, en simulant un accès NodePort.
- Passer ensuite sur un vrai cluster cloud pour apprendre Ingress proprement (GKE, EKS...).

➡️ Nous allons désormais continuer la formation en déployant sur **Google Kubernetes Engine (GKE)** pour reproduire un vrai environnement professionnel.

---

### 📚 Pourquoi `minikube service` permet d'accéder à l'application ?

### 📚 Pourquoi `minikube service` permet d'accéder à l'application ?

Dans Kubernetes, un `Service` de type `ClusterIP` est normalement **inaccessible depuis l'extérieur** du cluster. Minikube simule un vrai cluster, donc ton service est interne par défaut.

Quand tu utilises :

```bash
minikube service devops-training
```

👉 Minikube crée **un tunnel temporaire** entre ton poste Windows et ton Service Kubernetes. Cela te fournit une URL locale du type :

```
http://127.0.0.1:65186/
```

💡 Cela permet de tester ton application **sans avoir besoin d'Ingress** ou de LoadBalancer compliqué en local.

| Sans tunnel (`minikube service`) | Avec tunnel (`minikube service`) |
|:---------------------------------|:--------------------------------:|
| Pas d'accès au Service           | Accès local direct temporaire    |
| Besoin d'Ingress ou LoadBalancer | Tunnel automatique               |
| Complexité réseau                | Accès simple via 127.0.0.1        |

⚠️ En production (ex: AWS, GCP), `minikube service` n'existe pas :
- Il faut exposer l'application via un **Ingress Controller** ou un **Service de type LoadBalancer**.

---

#### 💡 Si l'application n'est pas accessible via http://devops.local/public

Lance cette commande dans un terminal **en mode administrateur**, et laisse-la tourner :

```bash
minikube tunnel
```

> Cela permet de faire le pont entre ta machine et le réseau interne du cluster Kubernetes (ports 80/443 pour l'Ingress).

---

#### 1. Démarrer Minikube

```bash
minikube start
```

#### 2. Activer le contrôleur Ingress

```bash
minikube addons enable ingress
```

#### 3. Ajouter une entrée dans /etc/hosts

Obtenez l'adresse IP de Minikube avec :

```bash
minikube ip
```

Puis ajoutez cette ligne (en remplaçant par l'adresse affichée) :

```txt
192.168.49.2  devops.local
```

> ✅ Remplacez `192.168.49.2` par l'adresse renvoyée par la commande ci-dessus

#### 4. Appliquer les fichiers Kubernetes

Depuis la racine du projet :

```bash
kubectl apply -f acid/k8s/
```

#### 5. Vérifier le déploiement

```bash
kubectl get pods
kubectl get svc
kubectl get ingress
```

#### 6. Accéder à l'application

Dans un navigateur : [http://devops.local](http://devops.local)

---

### 📦 Création d'un Secret Kubernetes pour Vault

Pour éviter de stocker le `VAULT_TOKEN` en clair dans `deployment.yaml`, on utilise un Secret Kubernetes.

#### Commande pour créer le Secret :

```bash
kubectl create secret generic vault-token-secret --from-literal=VAULT_TOKEN=ton-vrai-token-ici
```

- Cela crée un secret nommé `vault-token-secret`.
- Le `deployment.yaml` lit la variable d'environnement `VAULT_TOKEN` à partir de ce secret.
- Sécurité renforcée : aucun token sensible n'est stocké dans Git.

---

### 📦 Déploiement de l'image depuis Docker Hub

#### Étapes à suivre :

1. **Créer un compte Docker Hub** (si ce n’est pas déjà fait) : [https://hub.docker.com/](https://hub.docker.com/)
2. **Te connecter depuis le terminal :**
   ```bash
   docker login
   ```
3. **Taguer l’image avec ton nom Docker Hub :** Remplace `monuser` par ton nom d’utilisateur Docker Hub :
   ```bash
   docker tag devops-training monuser/devops-training:latest
   ```
4. **Pousser l’image sur Docker Hub :**
   ```bash
   docker push monuser/devops-training:latest
   ```
5. **Modifier ton **``** pour pointer vers l’image distante :**
   ```yaml
   image: monuser/devops-training:latest
   ```
6. **Redéployer dans Kubernetes :**
   ```bash
   kubectl apply -f acid/k8s/
   ```

Tu peux maintenant déployer depuis n'importe quelle machine connectée à Docker Hub 👍

---

### 📌 Remarques :

- Le port `8081` est utilisé pour éviter un conflit avec Jenkins (8080)
- `host.docker.internal` est utilisé pour que Docker communique avec Vault local

---

**Fin du document ACID.**

