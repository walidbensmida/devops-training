# Utilise une image Java légère
FROM openjdk:17-jdk-slim

# Définir le répertoire de travail
WORKDIR /app

# Copier le fichier JAR dans le conteneur
COPY target/devops-training-0.0.1-SNAPSHOT.jar app.jar

# Exposer le port sur lequel l'application s'exécute
EXPOSE 8081

# Commande pour exécuter l'application
ENTRYPOINT ["java", "-jar", "app.jar"]
