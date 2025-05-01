# Utilise l'image officielle Maven avec JDK 17 comme base
FROM maven:3.9-eclipse-temurin-17

# Passe en mode superutilisateur pour installer des paquets
USER root

# Met à jour les paquets et installe Docker CLI
RUN apt-get update && \
    apt-get install -y docker.io && \
    rm -rf /var/lib/apt/lists/*

# Crée un utilisateur 'jenkins' avec un répertoire personnel
RUN useradd -m -d /home/jenkins -s /bin/bash jenkins

# Passe à l'utilisateur 'jenkins' pour les étapes suivantes
USER jenkins

# Définit le répertoire de travail par défaut
WORKDIR /home/jenkins

#docker build -t tondockerhub/jenkins-agent-maven-docker .
#docker push tondockerhub/jenkins-agent-maven-docker
