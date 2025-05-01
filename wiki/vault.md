# Documentation - Déploiement de Vault sur Google Kubernetes Engine (GKE)

---

## Objectif

Déployer une instance Vault propre et fonctionnelle sur un cluster Kubernetes (GKE) avec une IP statique, en partant de zéro.

---

## Pré-requis

- Cluster Kubernetes créé sur GKE.
- SDK Google Cloud installé et configuré.
- IP statique réservée sur GCP.

Commande pour créer une IP statique :

```bash
gcloud compute addresses create vault-static-ip --global
gcloud compute addresses describe vault-static-ip --global
```

---

## Fichiers Kubernetes

### 1. vault-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vault
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vault
  template:
    metadata:
      labels:
        app: vault
    spec:
      containers:
        - name: vault
          image: hashicorp/vault:1.15.5
          ports:
            - containerPort: 8200
          env:
            - name: VAULT_DEV_ROOT_TOKEN_ID
              value: "myroot"
            - name: VAULT_DEV_LISTEN_ADDRESS
              value: "0.0.0.0:8200"
          readinessProbe:
            httpGet:
              path: /v1/sys/health
              port: 8200
            initialDelaySeconds: 10
            periodSeconds: 5
```

### 2. vault-service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: vault
  annotations:
    cloud.google.com/backend-config: '{"ports": {"8200":"vault-backendconfig"}}'
spec:
  type: ClusterIP
  selector:
    app: vault
  ports:
    - name: vault-api
      port: 8200
      targetPort: 8200
```

### 3. vault-backendconfig.yaml

```yaml
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: vault-backendconfig
spec:
  healthCheck:
    type: HTTP
    port: 8200
    requestPath: /v1/sys/health
    checkIntervalSec: 15
    timeoutSec: 10
    healthyThreshold: 1
    unhealthyThreshold: 3
```

### 4. vault-ingress.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: vault-ingress
  annotations:
    kubernetes.io/ingress.class: "gce"
    kubernetes.io/ingress.global-static-ip-name: vault-static-ip
    cloud.google.com/backend-config: '{"default": "vault-backendconfig"}'
spec:
  rules:
    - host: vault.devops.local
      http:
        paths:
          - path: /*
            pathType: ImplementationSpecific
            backend:
              service:
                name: vault
                port:
                  number: 8200
```

---

## Déploiement

Appliquer les fichiers YAML dans cet ordre :

```bash
kubectl apply -f vault-deployment.yaml
kubectl apply -f vault-service.yaml
kubectl apply -f vault-backendconfig.yaml
kubectl apply -f vault-ingress.yaml
```

Vérifier que les ressources sont correctement créées :

```bash
kubectl get pods,svc,ingress
```

---

## Configuration locale

Ajouter l'IP statique dans le fichier hosts de votre ordinateur :

Exemple sous Windows (fichier `C:\Windows\System32\drivers\etc\hosts`) :

```
34.149.51.185   vault.devops.local
```

---

## Accès à Vault

Accéder à Vault via le navigateur :

```
http://vault.devops.local
```

Token à utiliser : **myroot**

---

## Commandes utiles

- Voir les logs du pod Vault :

```bash
kubectl logs deployment/vault
```

- Port-forward local pour accéder directement sans DNS :

```bash
kubectl port-forward svc/vault 8200:8200
```

Puis accéder à :

```
http://localhost:8200
```

---

## Nettoyage complet

Pour supprimer toutes les ressources Vault :

```bash
kubectl delete -f vault-ingress.yaml vault-service.yaml vault-backendconfig.yaml vault-deployment.yaml
```

---

# Fin de la documentation 🚀

