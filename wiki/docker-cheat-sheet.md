# Docker Cheat Sheet

Voici une liste rapide des commandes Docker essentielles, accompagnées d'explications et d'exemples.

## Images Docker

### `docker pull`
Télécharge une image Docker depuis un registre.

```bash
docker pull [image:tag]
```
Exemple :
```bash
docker pull ubuntu:latest
```

### `docker images`
Liste les images Docker locales.

```bash
docker images
```

### `docker build`
Construit une image à partir d'un Dockerfile.

Options courantes :
- `-t` : Assigne un tag (nom et version) à l'image.

Exemple :
```bash
docker build -t mon_image:latest .
```

### `docker rmi`
Supprime une image locale.

Options :
- `-f` : Force la suppression même si l'image est utilisée.

Exemple :
```bash
docker rmi -f mon_image:latest
```

## Conteneurs Docker

### `docker run`
Crée et lance un nouveau conteneur.

Options courantes :
- `-d` : Lance le conteneur en arrière-plan (détaché).
- `-p` : Mappe un port local vers un port du conteneur.
- `--name` : Donne un nom au conteneur.

Exemple :
```bash
docker run -d -p 80:80 --name mon_nginx nginx
```

### `docker ps`
Liste les conteneurs en cours d'exécution.

Options :
- `-a` : Affiche tous les conteneurs (en cours ou arrêtés).

Exemple :
```bash
docker ps -a
```

### `docker stop`
Arrête un conteneur.

```bash
docker stop [conteneur_id ou nom]
```
Exemple :
```bash
docker stop mon_nginx
```

### `docker start`
Relance un conteneur arrêté.

```bash
docker start [conteneur_id ou nom]
```
Exemple :
```bash
docker start mon_nginx
```

### `docker rm`
Supprime un conteneur.

Options :
- `-f` : Force la suppression d'un conteneur actif.

Exemple :
```bash
docker rm -f mon_nginx
```

## Gestion avancée

### `docker exec`
Exécute une commande à l'intérieur d'un conteneur en cours d'exécution.

Options :
- `-it` : Démarre une session interactive.

Exemple :
```bash
docker exec -it mon_nginx bash
```

### `docker logs`
Affiche les logs d'un conteneur.

Options :
- `-f` : Affiche les logs en continu.

Exemple :
```bash
docker logs -f mon_nginx
```

## Réseaux Docker

### `docker network ls`
Liste tous les réseaux Docker.

```bash
docker network ls
```

### `docker network create`
Crée un nouveau réseau Docker.

```bash
docker network create mon_reseau
```

### `docker network connect`
Connecte un conteneur à un réseau existant.

```bash
docker network connect mon_reseau mon_nginx
```

---

