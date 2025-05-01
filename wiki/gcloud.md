# 🚀 Déploiement sur Google Kubernetes Engine (GKE)

## 🛠 Installation du SDK Google Cloud

1. Télécharger et installer le SDK Google Cloud : ➔ [https://cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install)

2. Initialiser gcloud :

```bash
gcloud init
```

(Connexion avec ton compte Google + sélection du projet)

---

## 🔧 Activer Kubernetes Engine API

```bash
gcloud services enable container.googleapis.com
```

---

## 🔧 Installer le plugin d'authentification GKE pour Windows

1. Installer le plugin :

```powershell
gcloud components install gke-gcloud-auth-plugin
```

2. Définir la variable d'environnement pour la session PowerShell :

```powershell
$env:USE_GKE_GCLOUD_AUTH_PLUGIN = "True"
```

(Pour rendre cette variable permanente : ajouter manuellement dans les variables système Windows.)

3. Mettre à jour les composants :

```bash
gcloud components update
```

---

## ☁️ Créer un cluster Kubernetes `devops-training-cluster`

```bash
gcloud container clusters create devops-training-cluster \
  --zone europe-west1-b \
  --num-nodes=1
```

- Le cluster sera créé dans la zone `europe-west1-b`
- Il aura un seul nœud pour l'environnement de test

---

## 📡 Configurer kubectl pour utiliser ton cluster

```bash
gcloud container clusters get-credentials devops-training-cluster --zone europe-west1-b
```

Cette commande met à jour ton fichier kubeconfig pour cibler ton nouveau cluster.

---

## ✅ Vérifier que tout est en place

```bash
kubectl get nodes
```

Tu dois voir ton nœud actif avec le statut `Ready` ✅

---

## ⚙️ Cas particulier : déploiement sans Vault

Si vous désactivez Vault dans votre application Spring Boot, il est impératif de :

- Supprimer toute référence à `secretKeyRef` dans `deployment.yaml`.
- Utiliser uniquement les variables d'environnement classiques si nécessaire.

Exemple de correction dans `deployment.yaml` :

```yaml
env:
  - name: SPRING_PROFILES_ACTIVE
    value: "default"
```

Cela permet d'éviter les erreurs `CreateContainerConfigError` au démarrage du pod sur GKE.

---

## 🛠 Que faire si l'Ingress GKE reste sans IP ?

Il peut arriver que l'Ingress soit créé, mais qu'aucune IP publique ne lui soit attribuée immédiatement.

Voici les principales vérifications à faire :

### 1. Vérifier que l'Ingress est correct

- Assurez-vous que le fichier `ingress.yaml` utilise `ingressClassName: gce`.
- Vérifiez que votre `Service` est bien de type `ClusterIP`.

### 2. Vérifier que l'API Compute Engine est activée

Activez l'API nécessaire avec la commande :

```bash
gcloud services enable compute.googleapis.com
```

### 3. Vérifier les quotas GCP

Dans la console GCP ➔ "IAM & Admin" ➔ "Quotas" :

- Vérifiez que vous avez du quota pour : IP addresses, Backend services, Load Balancers.

### 4. Patienter

La création d'un LoadBalancer dans un projet GCP récent peut prendre jusqu'à 10–15 minutes.

---

## ✅ Validation de l'Application après Déploiement

### Tester l'Application en local (port-forward)

```bash
kubectl port-forward pod/<nom-du-pod> 8081:8081
```

Accéder ensuite à :

```text
http://localhost:8081/
```

✅ Si vous voyez la réponse de l'application (`Application OK` ou `/public`), alors votre pod est prêt.

### Tester depuis Internet (IP publique)

Dans votre navigateur :

```text
http://<adresse-ip-publique>/
```

ou

```text
http://<adresse-ip-publique>/public
```

Si cela ne fonctionne pas :

- Vérifiez que votre backend est `HEALTHY`
- Vérifiez les règles Firewall Google Cloud

---

## 📋 Checklist rapide si l'Application n'est pas accessible

| Vérification                 | Commande / Action                          |
| ---------------------------- | ------------------------------------------ |
| Pod Running                  | `kubectl get pods`                         |
| Service Exposé               | `kubectl get svc`                          |
| Ingress IP publique          | `kubectl get ingress`                      |
| Test Local (port-forward)    | `kubectl port-forward pod/<pod> 8081:8081` |
| Test navigateur localhost    | `http://localhost:8081/`                   |
| Test navigateur IP publique  | `http://<ip>`                              |
| Firewall GCP autorise TCP 80 | Console GCP ➔ VPC ➔ Firewall Rules         |

---

## 🛠 Mini script Windows PowerShell pour automatiser déploiement

Créez un fichier **deploy.ps1** à la racine du projet avec :

```powershell
Write-Host "➡️ Compilation du projet Maven..."
mvn clean package

Write-Host "➡️ Construction de l'image Docker..."
docker build -t walid/devops-training:latest .

Write-Host "➡️ Push de l'image vers Docker Hub..."
docker push walid/devops-training:latest

Write-Host "➡️ Redémarrage du déploiement Kubernetes..."
kubectl rollout restart deployment devops-training

Write-Host "✅ Déploiement terminé !"
```

Exécutez ensuite :

```powershell
.\deploy.ps1
```

Cela rebuild, push et restart votre application en une seule commande 🚀

---

## 🚀 Utiliser Spring Boot Actuator pour Health Check Kubernetes

Pour exposer un Health Check fiable dans votre application Spring Boot :

1. Ajouter la dépendance Actuator dans `pom.xml` :

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

2. Configurer `application.yml` pour exposer `/actuator/health` :

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health
  endpoint:
    health:
      show-details: always
```

3. Adapter votre classe de sécurité pour autoriser `/actuator/health` :

```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/actuator/health", "/public").permitAll()
            .anyRequest().authenticated()
        )
        .httpBasic();
    return http.build();
}
```

4. Mettre à jour le Health Check GKE pour cibler `/actuator/health` au lieu de `/`.

---

## ⚙️ Toujours utiliser la dernière image Docker dans Kubernetes

Lorsque vous poussez une nouvelle image avec le tag `latest`, Kubernetes peut utiliser l'ancienne image locale si `imagePullPolicy` n'est pas forcé.

Pour s'assurer que la dernière image est toujours utilisée :

Dans `deployment.yaml`, configurez :

```yaml
spec:
  containers:
    - name: devops-training
      image: walid/devops-training:latest
      imagePullPolicy: Always
```

Ensuite, réappliquez le déploiement :

```bash
kubectl apply -f acid/k8s/deployment.yaml
kubectl rollout restart deployment devops-training
```

Cela garantira que Kubernetes télécharge toujours la dernière version de l'image à chaque redémarrage du déploiement.

---

## 🚀 Gérer les mises à jour d'images Docker proprement sur Kubernetes

Lorsque vous poussez des images Docker avec le tag `latest`, Kubernetes peut continuer d'utiliser une ancienne version en cache.

Pour éviter cela, il est recommandé d'utiliser **des tags versionnés** (`v1`, `v2`, etc.).

### 📦 Workflow recommandé pour les images Docker

1. Construire l'image avec un tag unique (ex: `v2`) :

```bash
docker build -t walid/devops-training:v2 .
```

2. Pousser l'image vers Docker Hub :

```bash
docker push walid/devops-training:v2
```

3. Modifier `deployment.yaml` pour utiliser l'image versionnée :

```yaml
spec:
  containers:
    - name: devops-training
      image: walid/devops-training:v2
      imagePullPolicy: Always
```

4. Appliquer les changements :

```bash
kubectl apply -f acid/k8s/deployment.yaml
kubectl rollout restart deployment devops-training
```

✅ Cela garantit que Kubernetes tire **l'image correcte** et **ne reste pas bloqué** avec une ancienne version en cache.

---

### 🛠 Astuce rapide : forcer une mise à jour sans changer le tag

Si vous utilisez encore `:latest` pour des tests rapides, vous pouvez forcer Kubernetes à re-puller l'image en supprimant manuellement le pod :

```bash
kubectl delete pod <nom-du-pod>
```

Le pod sera recréé et Kubernetes téléchargera l'image la plus récente.


---

## 💬 Remarque importante

- Sur Windows, n'oublie pas que certaines commandes bash doivent être adaptées dans PowerShell.
- Toujours penser à maintenir la variable `USE_GKE_GCLOUD_AUTH_PLUGIN` active.

---

**Ton environnement est maintenant prêt pour déployer ton application Spring Boot sur GKE !** 🚀

