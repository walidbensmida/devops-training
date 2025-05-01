# Documentation - Deployment of Jenkins on Google Kubernetes Engine (GKE) with Static IP and Persistent Storage

---

## Required Jenkins Files (with Key Line-by-Line Explanation)

> 🛑 **Important:** Do not delete the PersistentVolumeClaim (`jenkins-pvc`) in your `delete.sh` script, or Jenkins will lose all saved state (admin config, job history, etc.)

If you include this line:

```bash
kubectl delete pvc jenkins-pvc
```

you are wiping all persistent data. Remove it to preserve Jenkins state across redeployments.

Here is a list of the key Jenkins-related files used in this setup:

```yaml
# acid/jenkins/jenkins-casc.yaml
# systemMessage: Affiche un message dans l'interface Jenkins
# users: crée un compte admin à partir des variables d'environnement
# credentials: définit les identifiants DockerHub et kubeconfig via variables env
# location.url: définit l'URL externe de Jenkins
jenkins:
  systemMessage: "Jenkins configured with JCasC 🎉"
  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: ${ADMIN_USER}
          password: ${ADMIN_PASSWORD}
  authorizationStrategy:
    loggedInUsersCanDoAnything:
      allowAnonymousRead: false

credentials:
  system:
    domainCredentials:
      - credentials:
          - usernamePassword:
              id: dockerhub-credentials
              username: ${DOCKERHUB_USER}
              password: ${DOCKERHUB_PASSWORD}
          - file:
              id: kubeconfig-gke
              fileName: kubeconfig
              secretBytes: ${KUBECONFIG_BASE64}

unclassified:
  location:
    url: http://jenkins.devops.local
```

```yaml
# acid/jenkins/jenkins-casc-secrets.yaml
# Ce fichier injecte les variables utilisées dans le jenkins-casc.yaml (admin, dockerhub, kubeconfig)
apiVersion: v1
kind: Secret
metadata:
  name: jenkins-casc-secrets
  namespace: default
type: Opaque
stringData:
  ADMIN_USER: admin
  ADMIN_PASSWORD: Admin1234
  DOCKERHUB_USER: yourdockerhubuser
  DOCKERHUB_PASSWORD: yourdockerhubpassword
  KUBECONFIG_BASE64: <base64-encoded kubeconfig on one line>
```

```yaml
# acid/jenkins/jenkins-casc-configmap.yaml (optional)
# Sert à monter le fichier de configuration JCasC dans le conteneur Jenkins si pas d'URL Git
apiVersion: v1
kind: ConfigMap
metadata:
  name: jenkins-casc-config
  namespace: default
  labels:
    app: jenkins
  annotations:
    jenkins.io/configuration-as-code: "true"
data:
  jenkins.yaml: |
    <copie ici le contenu de jenkins-casc.yaml>
```

```groovy
// acid/jenkins/Jenkinsfile
// Pipeline complet pour : cloner le code, builder l'app, construire/pusher l'image Docker et déployer sur GKE
pipeline {
    agent {
        docker {
            image 'maven:3.9-eclipse-temurin-17'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        REPOSITORY_URL = 'https://github.com/tonuser/devops-training.git'
        DOCKER_IMAGE = 'tondockerhub/devops-training:latest'
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        KUBECONFIG_CREDENTIALS_ID = 'kubeconfig-gke'
        DEPLOYMENT_FILE = 'acid/k8s/devops-training/deployment.yaml'
    }

    stages {
        stage('Checkout') {
            steps {
                git "${REPOSITORY_URL}"
            }
        }
        stage('Build App') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE} ."
            }
        }
        stage('Push Docker Image') {
            steps {
                withDockerRegistry([credentialsId: "${DOCKER_CREDENTIALS_ID}", url: '']) {
                    sh "docker push ${DOCKER_IMAGE}"
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS_ID}", variable: 'KUBECONFIG')]) {
                    sh """
                        kubectl apply -f ${DEPLOYMENT_FILE}
                        kubectl rollout restart deployment devops-training
                    """
                }
            }
        }
    }
}
```

```yaml
# acid/k8s/jenkins/jenkins-deployment.yaml (excerpt)
# Déploiement de Jenkins avec chargement auto du JCasC depuis GitHub
# CASC_JENKINS_CONFIG : URL publique Git vers le jenkins-casc.yaml
# envFrom : injecte les variables sensibles via un secret Kubernetes
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      containers:
        - name: jenkins
          image: jenkins/jenkins:lts
          env:
            - name: CASC_JENKINS_CONFIG
              value: https://raw.githubusercontent.com/<your-username>/<your-repo>/main/acid/jenkins/jenkins-casc.yaml
          envFrom:
            - secretRef:
                name: jenkins-casc-secrets
          volumeMounts:
            - name: jenkins-home
              mountPath: /var/jenkins_home
      volumes:
        - name: jenkins-home
          emptyDir: {}
```

---

Here is a list of the key Jenkins-related files used in this setup:

| File                          | Location            | Purpose                                                        |
| ----------------------------- | ------------------- | -------------------------------------------------------------- |
| `jenkins-casc.yaml`           | `acid/jenkins/`     | Main JCasC configuration file (no secrets)                     |
| `jenkins-casc-secrets.yaml`   | `acid/jenkins/`     | Kubernetes Secret for admin, DockerHub credentials, kubeconfig |
| `jenkins-casc-configmap.yaml` | `acid/jenkins/`     | Optional ConfigMap to mount JCasC file if not using GitHub URL |
| `Jenkinsfile`                 | `acid/jenkins/`     | Pipeline definition for CI/CD builds                           |
| `jenkins-deployment.yaml`     | `acid/k8s/jenkins/` | Kubernetes deployment of Jenkins configured to use JCasC       |

These files allow full Jenkins automation, secure credential management, and reproducible pipeline setup.

---

## Objective

Deploy a fully functional Jenkins instance on GKE with:

* Static IP address
* Persistent Volume Claim (PVC) for Jenkins data
* Jenkins configured via Configuration-as-Code (JCasC)
* All secrets managed via Kubernetes Secrets
* Optionally reference a remote GitHub link for the JCasC YAML

---

## Simplified Jenkins Configuration-as-Code (JCasC) with Remote YAML (GitHub)

Instead of mounting the JCasC YAML inside the pod, you can directly tell Jenkins to fetch the config file from a public GitHub URL.

This is useful for development/testing environments where you want to iterate fast without redeploying Kubernetes resources.

---

## Example setup using GitHub URL

You can also choose to mount the configuration file locally using a ConfigMap. In that case, instead of setting a GitHub URL, the file is bundled into a ConfigMap and mounted in the Jenkins container.

### 🤔 Why copy `jenkins-casc.yaml` into the ConfigMap?

Kubernetes ConfigMaps do not support references to external files. That means:

* You cannot tell Kubernetes “go read `jenkins-casc.yaml` from disk.”
* Instead, you must copy the **raw contents** of the file **into the `data:` field** of the ConfigMap.

This makes the configuration file available as a mounted file inside the Jenkins pod (e.g. `/var/jenkins_home/casc/jenkins.yaml`).

So, if you choose the ConfigMap strategy, you're not maintaining two files — you're just embedding one file (`jenkins-casc.yaml`) inside another (`jenkins-casc-configmap.yaml`) for Kubernetes to understand.

You can also choose to mount the configuration file locally using a ConfigMap. In that case, instead of setting a GitHub URL, the file is bundled into a ConfigMap and mounted in the Jenkins container.

This is why in the ConfigMap example, we copy the content of `jenkins-casc.yaml` inside the `jenkins-casc-configmap.yaml` file — because Kubernetes needs the configuration **embedded directly** to make it accessible to the Jenkins container as a file.

1. Push your `jenkins-casc.yaml` to a **public GitHub repo** (or a private one with proper credentials).

2. Use this in your Jenkins deployment:

```yaml
env:
  - name: CASC_JENKINS_CONFIG
    value: https://raw.githubusercontent.com/<your-username>/<your-repo>/main/acid/jenkins/jenkins-casc.yaml
```

Replace `<your-username>`, `<your-repo>`, and the branch name (`main`) appropriately.

---

## ⚠️ Notes

* If the YAML contains placeholders like `${ADMIN_PASSWORD}`, you'll still need to use Kubernetes Secrets or define them manually in Jenkins.
* If the repo is private, Jenkins must be able to authenticate (via SSH key or token).

---

## Benefits of this approach

✅ You don't need to create a ConfigMap
✅ You can update the config live just by pushing to GitHub
✅ Ideal for local dev and iterative changes

---

## Summary: Two ways to load JCasC

Both approaches achieve the same goal — Jenkins will be auto-configured on startup.

| Method                | Use case                         | Setup                                                                                                    |
| --------------------- | -------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Volume from ConfigMap | More secure, stable environments | Use `jenkins-casc-configmap.yaml`, copy content of `jenkins-casc.yaml` inside it, and mount it as a file |
| GitHub URL            | Dev, fast iteration              | Set `CASC_JENKINS_CONFIG` to raw GitHub URL                                                              |

| Method                | Use case                         | Setup                                              |
| --------------------- | -------------------------------- | -------------------------------------------------- |
| Volume from ConfigMap | More secure, stable environments | Use `jenkins-casc-configmap.yaml` + mount into pod |
| GitHub URL            | Dev, fast iteration              | Set `CASC_JENKINS_CONFIG` to raw GitHub URL        |

---

You can now choose the method that best fits your workflow.

# End of Jenkins Deployment with Secrets and JCasC ✅

---

## 📒 Useful kubectl Commands Cheat Sheet

Here are useful `kubectl` commands you’ll likely need regularly:

### 🔍 Get Jenkins initial admin password

```bash
kubectl exec deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
```

### 🧠 View all running pods

```bash
kubectl get pods
```

### 🔎 Inspect logs from Jenkins pod

```bash
kubectl logs deployment/jenkins
```

### 📂 Apply a manifest

```bash
kubectl apply -f <file.yaml>
```

### ❌ Delete a manifest

```bash
kubectl delete -f <file.yaml>
```

### 💾 List PersistentVolumeClaims (PVCs)

```bash
kubectl get pvc
```

### 🛠️ Check service endpoints (e.g. for Jenkins, Vault, etc.)

```bash
kubectl get svc
```

### 🌐 Check ingress status and IP

```bash
kubectl get ingress
```

You can copy/paste these in a terminal or keep them as a cheat sheet.
