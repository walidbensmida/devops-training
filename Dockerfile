# Étape de construction
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package

# Étape finale
FROM eclipse-temurin:17-jdk
WORKDIR /app
COPY --from=build /app/target/devops-training-0.0.1-SNAPSHOT.jar .
CMD ["java", "-jar", "devops-training-0.0.1-SNAPSHOT.jar"]
