FROM jenkins/jenkins:lts

USER root

# Installer les dépendances nécessaires
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Télécharger et installer kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

USER jenkins


#docker build -t walidbensmida/jenkins-kubectl:latest -f jenkins-with-kubectl.Dockerfile .
#docker push walidbensmida/jenkins-kubectl:latest
