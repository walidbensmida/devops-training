# Documentation - Deployment of Jenkins on Google Kubernetes Engine (GKE) with Static IP and Persistent Storage

---

## Objective

Deploy a fully functional Jenkins instance on GKE with:
- Static IP address
- Persistent Volume Claim (PVC) for Jenkins data
- Proper BackendConfig for GKE Health Checks
- Detailed YAML configurations

---

## Understanding Load Balancer and Ingress

When you create an **Ingress** resource in GKE, Google Cloud **automatically creates a Load Balancer** for you.

### How it works:

| Layer | Component | Role |
|:-----|:----------|:----|
| 1 | **Browser** | You access Jenkins via `http://jenkins.devops.local` |
| 2 | **Google Cloud Load Balancer** | Receives the HTTP request from the internet |
| 3 | **Ingress Controller** | Routes the HTTP request inside the Kubernetes cluster |
| 4 | **Service (jenkins-service)** | Forwards the request to the correct pod |
| 5 | **Pod (Jenkins)** | Runs the Jenkins application |

### Why use Ingress and Load Balancer?

- Without Ingress: you would need **one LoadBalancer per application**, costing more money.
- With Ingress: **one LoadBalancer** can manage **multiple applications** like Jenkins, Vault, etc., using rules.

✅ Ingress allows smarter routing (e.g., `/jenkins` → Jenkins service, `/vault` → Vault service) over a **single public IP address**.

### Visual summary:

```
[Internet / Browser]
        ↓
[Google Cloud Load Balancer (Static IP)]
        ↓
[Ingress Controller in GKE]
        ↓
[Service (jenkins-service)]
        ↓
[Pod (Jenkins container)]
```

---

## Prerequisites

- Kubernetes cluster created on GKE.
- Google Cloud SDK installed and configured.
- Static IP address reserved for Jenkins.
- Helm **NOT USED** (manual YAML deployment).

---

## Reserve Static IP

Reserve a global static IP for Jenkins:

```bash
gcloud compute addresses create jenkins-static-ip --global
gcloud compute addresses describe jenkins-static-ip --global
```

Example IP assigned: `34.149.51.186`

---

## Persistent Volume Claim (PVC)

Create a PVC to persist Jenkins data:

### File: `jenkins-pvc.yaml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pvc
spec:
  accessModes:
    - ReadWriteOnce # Only one node can mount the volume in read-write mode.
  resources:
    requests:
      storage: 5Gi # Requested storage size.
  storageClassName: standard # Use the standard StorageClass.
```

Apply:
```bash
kubectl apply -f jenkins-pvc.yaml
```

✅ 5GB is sufficient for a small Jenkins instance and remains inside Free Tier limits.

---

## Deployment YAML

### File: `jenkins-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
spec:
  replicas: 1 # One Jenkins pod.
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      securityContext:
        fsGroup: 1000 # Allows Jenkins process to write to mounted volumes.
      containers:
        - name: jenkins
          image: jenkins/jenkins:lts # Official Jenkins LTS image.
          ports:
            - containerPort: 8080 # Jenkins Web UI.
            - containerPort: 50000 # Jenkins agent communication.
          volumeMounts:
            - name: jenkins-home
              mountPath: /var/jenkins_home # Persistent Jenkins home directory.
      volumes:
        - name: jenkins-home
          persistentVolumeClaim:
            claimName: jenkins-pvc
```

Apply:
```bash
kubectl apply -f jenkins-deployment.yaml
```

---

## Service YAML

### File: `jenkins-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: jenkins
  annotations:
    cloud.google.com/backend-config: '{"default": "jenkins-backendconfig"}' # Link to BackendConfig.
  labels:
    app: jenkins
spec:
  type: ClusterIP # Internal exposure for Ingress.
  selector:
    app: jenkins
  ports:
    - name: http
      port: 8080
      targetPort: 8080
    - name: agent
      port: 50000
      targetPort: 50000
```

Apply:
```bash
kubectl apply -f jenkins-service.yaml
```

---

## BackendConfig YAML (Health Check Configuration)

### File: `jenkins-backendconfig.yaml`

```yaml
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: jenkins-backendconfig
spec:
  healthCheck:
    type: HTTP
    requestPath: /login # Target a stable endpoint for health checking.
    port: 8080
    checkIntervalSec: 30
    timeoutSec: 10
    healthyThreshold: 1
    unhealthyThreshold: 5
```

Apply:
```bash
kubectl apply -f jenkins-backendconfig.yaml
```

✅ Point the health check to `/login` to avoid HTTP parsing errors seen on Jenkins default root `/`.

---

## Ingress YAML

### File: `jenkins-ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jenkins-ingress
  annotations:
    kubernetes.io/ingress.class: "gce" # Use Google Cloud Load Balancer.
    kubernetes.io/ingress.global-static-ip-name: "jenkins-static-ip" # Static IP reserved for Jenkins.
spec:
  rules:
    - host: jenkins.devops.local
      http:
        paths:
          - path: /*
            pathType: ImplementationSpecific
            backend:
              service:
                name: jenkins
                port:
                  number: 8080
```

Apply:
```bash
kubectl apply -f jenkins-ingress.yaml
```

---

## DNS Configuration

Add the following line to your local `/etc/hosts` file:

```plaintext
34.149.51.186   jenkins.devops.local
```

✅ You can now access Jenkins from your browser at:
```
http://jenkins.devops.local
```

---

## Important Notes

- It can take a few minutes for Jenkins to start and pass the GKE Load Balancer health check.
- Monitor the Jenkins pod logs to retrieve the initial administrator password:
```bash
kubectl logs deployment/jenkins
```

Look for:
```
Please use the following password to proceed to installation...
```

- `fsGroup: 1000` is **essential** to give Jenkins permission to write to `/var/jenkins_home`.

- The custom BackendConfig avoids HTTP parsing errors like:
  ```
  Error parsing HTTP request header
  java.lang.IllegalArgumentException: Invalid character found in the request target
  ```

✅ Using `/login` as health check path resolves this issue.

---

# End of Jenkins Deployment Documentation 🚀

