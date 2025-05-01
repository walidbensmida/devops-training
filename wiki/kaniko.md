# DevOps Training — Jenkins + Kaniko on GKE

This project demonstrates a complete CI/CD pipeline using **Jenkins** and **Kaniko** on **Google Kubernetes Engine (GKE)** to build and push Docker images without requiring Docker access (no Docker socket).

---

## ✅ Features

* Jenkins deployed on GKE with Configuration as Code (JCasC)
* Vault integration for secret management
* Docker image built using Kaniko inside a Kubernetes Job
* Secure DockerHub authentication via Kubernetes Secret
* Multi-stage Dockerfile for Maven build and Java app packaging
* Full pipeline defined in a declarative Jenkinsfile

---

## \:whale: Dockerfile (multi-stage)

```Dockerfile
# Stage 1: Build the JAR
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Final runtime image
FROM eclipse-temurin:17-jdk
WORKDIR /app
COPY --from=build /app/target/devops-training-0.0.1-SNAPSHOT.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

---

## \:rocket: Jenkinsfile (pipeline)

```groovy
pipeline {
  agent any

  environment {
    REPOSITORY_URL = 'https://github.com/walidbensmida/devops-training.git'
    KANIKO_YAML = 'acid/k8s/jenkins/kaniko-job.yaml'
  }

  stages {
    stage('Git Checkout') {
      steps {
        git url: "${REPOSITORY_URL}", branch: 'main'
      }
    }

    stage('Build & Push Image with Kaniko') {
      steps {
        sh 'kubectl delete job build-and-push-kaniko --ignore-not-found'
        sh "kubectl apply -f ${KANIKO_YAML}"
        sh 'kubectl wait --for=condition=complete --timeout=180s job/build-and-push-kaniko'
        sh 'kubectl logs job/build-and-push-kaniko'
      }
    }
  }
}
```

---

## \:lock: DockerHub Secret (required for push auth)

```bash
kubectl create secret docker-registry dockerhub-secret \
  --docker-username=walidbensmida \
  --docker-password=YOUR_PERSONAL_ACCESS_TOKEN \
  --docker-email=walidbensmida@hotmail.fr \
  -n default
```

> The secret is mounted in the Kaniko pod at `/kaniko/.docker/config.json` via volumeMounts.

---

## \:factory: Kaniko Job YAML

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: build-and-push-kaniko
spec:
  backoffLimit: 0
  template:
    spec:
      containers:
        - name: kaniko
          image: gcr.io/kaniko-project/executor:latest
          args:
            - "--dockerfile=Dockerfile"
            - "--context=git://github.com/walidbensmida/devops-training.git#refs/heads/main"
            - "--destination=walidbensmida/devops-training:latest"
            - "--verbosity=info"
          volumeMounts:
            - name: kaniko-secret
              mountPath: /kaniko/.docker
              readOnly: true
      restartPolicy: Never
      volumes:
        - name: kaniko-secret
          secret:
            secretName: dockerhub-secret
            items:
              - key: .dockerconfigjson
                path: config.json
```

---

## ✅ Final Result

Once configured:

* Jenkins triggers the pipeline on commit or manually
* Kaniko builds the app from Git source
* Docker image is pushed to DockerHub: `walidbensmida/devops-training:latest`
* All build steps are Kubernetes-native, secure and Docker-free

You're now fully CI/CD-ready with Jenkins + Kaniko on GKE!
