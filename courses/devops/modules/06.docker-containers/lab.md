
# Lab

Containers with Docker

## Objectives 

1. Install Docker
2. Write a `Dockerfile` and build a Docker image
3. Run a Docker container with multiple options
4. Share your Docker container with a classmate
5. Run multiple containers in one network
6. Use Docker Storage
7. Build and run a multiple container application with Docker Compose

## Useful links

- [Dockerfile best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

## Resources

**[`lab/hello-world-docker`](lab/hello-world-docker) directory contains:**
- `server.js` - the code for a simple "Hello World" [Node.js](https://nodejs.org/) web app
- `package.json` - describes the Node.js web app and its dependencies
- `Dockerfile` - describes the previous Node.js web app as a Docker container

**[`lab/hello-world-docker-compose`](lab/hello-world-docker-compose) directory contains:**
- `server.js` - the code for a simple "Hello World" [Node.js](https://nodejs.org/) web app
- `dbClient.js` - the module that creates a connection to Redis.
- `package.json` - describes the Node.js web app and its dependencies
- `Dockerfile` - describes the previous Node.js web app as a Docker container
- `docker-compose.yaml` - describes Docker Compose configuration

## 1. Install Docker

Before you can start the lab, you have to:
1. Install [Docker Desktop](https://www.docker.com/get-started) following the instructions depending on your OS.
2. Make sure your docker installation is working properly by running the following command in a terminal:
   ```
   docker run hello-world
   ```

## 2. Write a Dockerfile and build a Docker image

1. Open [`lab/hello-world-docker`](lab/hello-world-docker) directory and check out the `server.js`, `package.json` and `Dockerfile` files
2. Check out the explanations for each line in the Dockerfile from [the documentation](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#dockerfile-instructions) 
3. Build the docker container   
  1. Open a terminal (CMD or PowerShell for Windows)
  2. Navigate to the [`lab/hello-world-docker`](lab/hello-world-docker) directory in the cloned repository
  3. Run the following command:
     ```
     docker build -t hello-world-docker .
     ```
     - Don't forget the `.` at the end of the command. It is here to tell Docker it should look for the `Dockerfile` in the current directory. 
     - `-t` tag - to build a container with the name you want (here `hello-world-docker`)
4. Check if your Docker container appears in the local Docker images:
   ```
   docker images
   ```

## 3. Run a Docker container with multiple options

1. Run the container with the following command:   
   ```
   docker run -p 12345:8080 -d hello-world-docker
   ```
   1. `-p` maps a port on your local machine to a port inside the container
   2. `-d` makes the container run in the background
2. Check if the container is running (and save the container ID) with the following command:
   ```
   docker ps
   ```
3. Open your web browser and go to `http://localhost:12345`
4. Print the logs of the container with:
   ```
   docker logs <CONTAINER_ID>
   ```
   where `CONTAINER_ID` - is the ID of the container.
3. Stop the container with:
   ```
   docker stop <CONTAINER_ID>
   ```

## 4. Share your Docker container with a classmate

1. Modify the message printed in the `server.js` (you can add your name for example)
2. Rebuild the Docker container (with a different name) with this modified code and see if you can run it, then navigate to the web app in your browser
3. Register on [Docker Hub](https://hub.docker.com/)
4. Tag your container with the following command:
   ```
   docker tag hello-world-docker <DOCKER_ACCOUNT_NAME>/<CUSTOM_IMAGE_NAME>
   ```
   where `DOCKER_ACCOUNT_NAME` - is your account on Docker Hub, `CUSTOM_IMAGE_NAME` - is the custom name of the image.
5. Log in to Docker Hub from your terminal:
   ```
   docker login
   ```
6. Push the docker image to Docker Hub:
   ```
   docker push <DOCKER_ACCOUNT_NAME>/<CUSTOM_IMAGE_NAME>
   ```
7. See if you can find the image in your [repositories](https://hub.docker.com/repositories) in the Docker Hub
8. Ask a classmate to retrieve your Docker container and run it:
   ```
   docker pull <DOCKER_ACCOUNT_NAME>/<CUSTOM_IMAGE_NAME>
   docker run -p 12345:8080 -d <DOCKER_ACCOUNT_NAME>/<CUSTOM_IMAGE_NAME>
   ```

## 5. Run multiple containers in one network

0. Read [Networking overview](https://docs.docker.com/network/) and [the Bridge network driver](https://docs.docker.com/network/bridge/)

1. Navigate to the [`lab/hello-world-docker-compose`](lab/hello-world-docker-compose) directory and check out the `dbClient.js`, `server.js`, `package.json` and `Dockerfile` files. This application requires Redis database and uses `REDIS_HOST` and `REDIS_PORT` [environment variables](https://en.wikipedia.org/wiki/Environment_variable) to connect to it.

  Build a Docker image inside this directory with the name of your choice (`<CUSTOM_IMAGE_NAME>`).

  Run a container with the following command:
  
  ```
  docker run -p 12345:8080 <CUSTOM_IMAGE_NAME>
  ```
  
  Do you see an error related to the Redis connection?
  
2. Let's start Redis now. Open a new terminal window and run:

  ```
  docker run -p 6379:6379 redis
  ```

3. Try to start the application container one more time:

  ```
  docker run -p 12345:8080 <CUSTOM_IMAGE_NAME>
  ```

  Do you still see the same error? This is because you must create a network and connect both containers to it.
  
4. Create a bridge network:

  ```
  docker network create my-net
  ```

  By default, it uses the [bridge driver](https://docs.docker.com/network/bridge/) for the network being created. 
  
  You can list all the existing Docker networks on your host:
  
  ```
  docker network ls
  ```
  
  And you can inspect the network with the command:
  
  ```
  docker network inspect my-net
  ```

5. Connect a running Redis container to a network:
  
  ```
  docker network connect <NETWORK> <REDIS_CONTAINER>
  ```
  
  - `<NETWORK>` - ID or name of a network  
  - `<REDIS_CONTAINER>` - ID or name of a Redis container  
  
  Inspect the container and find the attached network.

6. Test if the Redis container is "pingable" from another container, for example like this:

  ```
  docker run --network my-net <CUSTOM_IMAGE_NAME> ping <REDIS_CONTAINER>
  ```
  
  - `<REDIS_CONTAINER_ID>` - Redis container ID
  - `<CUSTOM_IMAGE_NAME>` - the image created above
  
  You must see the output similar to this, saying it can successfully communicate by a container ID (which is used as the hostname):
  
  ```
  PING 97073cebc7ea (172.21.0.2) 56(84) bytes of data.
  64 bytes from 97073cebc7ea.my-net (172.21.0.2): icmp_seq=1 ttl=64 time=0.235 ms
  64 bytes from 97073cebc7ea.my-net (172.21.0.2): icmp_seq=2 ttl=64 time=0.109 ms
  ```

6. Now, you need to start the container with the options:

  - `--network <NETWORK>` - to connect to a network
  - `--env REDIS_HOST=<REDIS_CONTANER>` - to provide an environment variable to your application with a hostname of the Redis container
  - `-p <HOST_PORT>:<CONTAINER_PORT>` - to expose the application to outside

  The full command looks like this:
  
  ```
  docker run -p <HOST_PORT>:<CONTAINER_PORT> --network <NETWORK> --env REDIS_HOST=<REDIS_CONTANER> <CONTAINER_IMAGE_NAME>
  ```
  
  The error of connection to Redis must disappear and you will be able to open your application in a browser.
    
## 6. Use Docker Storage

0. Learn [the different types of Docker mounts](https://docs.docker.com/storage/#choose-the-right-type-of-mount). 

1. Navigate to the [`lab/hello-world-docker-compose`](lab/hello-world-docker-compose) directory and check out the `dbClient.js`, `server.js`, `package.json` and `Dockerfile` files.

  Build a Docker image inside this directory with the name of your choice (`<CUSTOM_IMAGE_NAME>`).

2. Create a bridge network as in the previous part 5.

3. **Use Volumes.**
  
  Run a Redis container with the option `-v` and `--network`:
  
  ```
  docker run -p 6379:6379 -v <VOLUME_NAME>:<CONTAINER_PATH> --network <NETWORK> redis
  ```
  
  - `<VOLUME_NAME>` - the name of the volume, choose anyone for example `my-volume`.
  - `<CONTAINER_PATH>` - full path to the storage location inside the container.
  
  > Hint. Redis container stores its data in the `/data` directory (refer to documentation - https://hub.docker.com/_/redis).
  
  Run an application container by connecting it to the same network and providing an environment variable like in the previous part 5:

  ```
  docker run -p <HOST_PORT>:<CONTAINER_PORT> --network <NETWORK> --env REDIS_HOST=<REDIS_CONTANER> <CONTAINER_IMAGE_NAME>
  ```

  Visit `http://localhost:<HOST_PORT>` in your web browser and hit refresh a couple of times. Then, remove the container and start it again. What happened to the counter? Why?

4. **Use Bind mounts.**
  
  Run a Redis container with the option `-v` and `--network`:

  ```
  docker run -p 6379:6379 -v <VOLUME_NAME>:<CONTAINER_PATH> --network <NETWORK> redis
  ```

  - `<HOST_PATH>` - full path to where you want to mount a directory on your computer (you can also use `pwd` to access the current directory, eg.: `"$(pwd)"/path_to`).
  - `<CONTAINER_PATH>` - full path to the storage location inside the container.
  
  Run an application container by connecting it to the same network and providing an environment variable like in the previous part 5:

  ```
  docker run -p <HOST_PORT>:<CONTAINER_PORT> --network <NETWORK> --env REDIS_HOST=<REDIS_CONTANER> <CONTAINER_IMAGE_NAME>
  ```

  Visit `http://localhost:<HOST_PORT>` in your web browser, then check your storage directory `<HOST_PATH>`. Do you see any files and folders?
  
  Run one more container with a different `HOST_PORT`, then test how both containers are sharing one directory.
  
  Anyone who has write permissions to `<HOST_PATH>` can affect container storage. Create any file inside `<HOST_PATH>` on your computer and find the same file from inside of a container using the `docker exec ...` command.

## 7. Build and run a multiple container application with Docker Compose

Are you not yet tired of running too many heavy `docker` commands to make things work? It is time to learn Docker Compose!

1. Docker Compose should be included in your Docker installation (on Windows and Mac at least). If not, install it using the official [instructions](https://docs.docker.com/compose/install/).

2. Navigate to the [`lab/hello-world-docker-compose`](lab/hello-world-docker-compose) directory and check out the `dbClient.js`, `server.js`, `package.json` and `Dockerfile` files.

3. Build the Docker image inside this directory with the name of your choice

4. Fill the missing part of the `docker-compose.yaml` file to make it use the container you just built. You can take inspiration from [that example](index.md#docker-compose-example).

5. Start the containers with `docker-compose up`

6. Visit `http://localhost:5000` in your web browser and hit refresh a couple of times

7. Stop the containers by running `CTRL+C` in the previous terminal

8. Delete the containers with:
   ```
   docker-compose rm
   ```

9. Start the containers again   
  1. What happened to the counter? Why?
  2. Delete the containers again

10. Make the necessary changes in the Docker compose file so that when you delete and create the containers again the counter keeps its value.

## Bonus tasks

1. Run WordPress with MySQL using Docker Compose
