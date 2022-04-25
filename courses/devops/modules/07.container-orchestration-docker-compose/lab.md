
# From zero to advanced Docker Compose

## Objectives

1. Create a basic Go webserver
2. Wrap the application inside a container
3. Connect the application to another container
4. Store environment variables inside `.env`
5. Use Docker Compose
6. Control the startup order and persist data
7. Define a health check HTTP endpoint
8. Restart failing containers
9. Use YAML anchors to remove duplication in compose file
10. Leveraging multiple compose files

## Step 1 - Create a basic Go webserver

* If go is not yet present, install it by following the [documentation](https://golang.org/doc/install).

Install on Ubuntu / Debian Linux with the command:
  `command -v go || sudo apt install -y golang-go`

* Create a new directory `step_1`.

* Import the file `step_1/app.go` inside it.

* From the `step_1` directory:

  * Compile the application:

    `go build app.go`

  * Run the application:

    `./app`

* From another terminal, test the application and validate its output:

  ```
  curl http://localhost:8080/pong/step_1
  Message received: pong/step_1
  ```

* Kill the running webserver:

  `kill $(ps aux | grep ' \./app' | awk '{print $2}')`

## Step 2 - Wrap the application inside a container

* Create a new directory `step_2`.

* Import the `app.go` file into it. It remains identical to the `step_1` file. 

* Declare a new `Dockerfile` using a multi-stage build:

  * The first part installs the `go` environment and compiles the application:

    ```dockerfile
    FROM golang:1.16 AS builder
    WORKDIR /go/src/github.com/alexellis/href-counter/
    RUN go get -d -v golang.org/x/net/html  
    COPY app.go .
    RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app app.go
    ```

  * The second part imports the generated Go application and executes it:

    ```dockerfile
    FROM alpine:latest  
    RUN apk --no-cache add ca-certificates
    WORKDIR /root/
    COPY --from=builder /go/src/github.com/alexellis/href-counter/app .
    CMD ["./app"] 
    ```

* Build the image, it is named `ping` with version `step_2`:

  ```bash
  docker build -t ping:step_2 .
  ```

* Start a container from this image:

  ```bash
  docker run \
  	-p 8080:8080 \
    -d \
  	--name ping_app \
  	ping:step_2
  ```

  * The port `8080` is exposed
  * It is detached from the terminal
  * It is named `ping_app`

* Test the application:

  ```bash
  curl http://localhost:8080/pong/step_2
  Message received: pong/step_2
  ```

* Stop and remove the container:

  ```bash
  docker rm -f ping_app
  ```

* Make some change, for example, update the message to `Got new message:`:

  ```bash
  docker build -t ping:step_2 .
  docker run \
  	-p 8080:8080 \
    -d \
  	--name ping_app \
  	ping:step_2
  curl http://localhost:8080/pong/step_2
  docker rm -f ping_app
  ```

## Step 3 - Connect the application to another container

* Create a new directory `step_3`.

* Start the MariaDB database inside a container:

  ```bash
  docker run \
    -p 127.0.0.1:3306:3306 \
    -e MYSQL_ROOT_PASSWORD=my-secret-pw \
    -d \
    --name ping-mariadb \
    mariadb:latest
  ```

* Export its IP address and validate the database, we also declare the user password:

  ```bash
  export MYSQL_HOST=`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ping-mariadb`
  export MYSQL_PASSWORD='my-secret-pw'
  
  echo $MYSQL_HOST
  echo $MYSQL_PASSWORD
  
  docker run \
    -it \
    --rm \
    mariadb \
    mysql \
      -h$MYSQL_HOST \
      -P3306 \
      -uroot \
      -p$MYSQL_PASSWORD \
      -e "SHOW DATABASES;"
  ```

* Import the following files:

  * `step_3/app.go`

    The application is getting more complex, it initializes the database and inserts messages into it.

  * `step_3/go.mod`

    Contains the list of dependency module versions.

  * `step_3/go.sum`

    Contains the checksums of the content of specific module versions.

* Looking at the `step_3/app.go` file, the database connection properties are obtained from environment variables and use default when appropriate:

  ```bash
  cat app.go | grep getEnv
  ```

* Import `Dockerfile`, it is almost identical to `step_2/Dockerfile` with the addition of 2 `COPY` instructions:

  ```dockerfile
  ...
  COPY app.go    .
  COPY go.mod    .
  COPY go.sum    .
  ...
  ```

* Build and run the container:

  ```bash
  docker build -t ping_app:step_3 .
  docker run \
    -p 8080:8080 \
    -d \
    -e MYSQL_HOST=$MYSQL_HOST \
    -e MYSQL_PASSWORD \
    --name ping_app \
    ping_app:step_3
  ```

* Test the application:

  ```bash
  curl http://localhost:8080/pong/step_3/message_1
  curl http://localhost:8080/pong/step_3/message_2
  docker run \
    -it \
    --rm \
    mariadb \
    mysql \
      -h$MYSQL_HOST \
      -P3306 \
      -uroot \
      -p$MYSQL_PASSWORD \
      -e "SELECT * FROM ping.history;"
  ```

* Stop and remove the container and remove the environment variables, we keep the database running:

  ```bash
  docker rm -f ping_app
  unset MYSQL_HOST
  unset MYSQL_PASSWORD
  ```

## Step 4 - Store environment variables inside `.env`

* Create a new directory `step_4`.

* Create an `env.sample` file, it will be committed and serve as an example:

  ```bash
  # Example configuration file,
  # use it as a source of inspiration
  # by moving and modifying its content
  # to the `.env` location.
  
  # IP or domain of the MariaDB server
  # MUST BE REPLACED by the MariaDB container IP
  # for example `docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ping-mariadb`
  MYSQL_HOST=127.0.0.1
  
  # Password of the MariaDB user
  MYSQL_PASSWORD=my-secret-pw
  ```

* Create a local `.env` file, ignored from Git:

  ```bash
  echo -n '' > .env
  echo "MYSQL_HOST=`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ping-mariadb`" >> .env
  echo "MYSQL_PASSWORD=my-secret-pw" >> .env
  cat .env
  ```

* Import the files `app.go`, `go.mod`, `go.sum` and `Dockerfile`. They remain identical to the `step_3` files.

* Build and run the container, now referring to the `.env` file:

  ```bash
  docker build -t ping_app:step_4 .
  docker run \
    -p 8080:8080 \
    -d \
    --env-file .env \
    --name ping_app \
    ping_app:step_4
  ```

* Test the application:

  ```bash
  curl http://localhost:8080/pong/step_4/message_1
  curl http://localhost:8080/pong/step_4/message_2
  export $(cat .env)
  docker run \
    -it \
    --rm \
    mariadb \
    mysql \
      -h$MYSQL_HOST \
      -P3306 \
      -uroot \
      -p$MYSQL_PASSWORD \
      -e "SELECT * FROM ping.history;"
  ```

* Stop and remove the containers, including the database container:

  ```bash
  docker rm -f ping_app ping-mariadb
  ```

## Step 5 - Use Docker Compose

* Create a new directory `step_5`.

* Import the files `app.go`, `go.mod`, `go.sum` and `Dockerfile`. They remain identical to the `step_4` files.

* The `.env` file is different:

  ```bash
  cat <<EOF > .env
  MYSQL_HOST=step_5_db_1
  MYSQL_PASSWORD=my-secret-pw
  MYSQL_ROOT_PASSWORD=my-secret-pw
  EOF
  ```

  * The MariaDB server is now accessible by hostname: `step_5_db_1`

  * The MariaDB image expects the `MYSQL_ROOT_PASSWORD` which could be different from the user password if we connect with another user than `root` (recommended).

* Create the `docker-compose.yml` file with the content:

  ```yml
  services:
    web:
      build: .
      ports:
        - "8080:8080"
      env_file:
        - ".env"
    db:
      image: 'mariadb'
      env_file:
        - ".env"
  ```

* Start the containers:

  ```bash
  docker compose up
  ```

* Chances are that the `web` container crashes because the database is not yet listening on port `3306`:

  * The `docker compose ps` command prints an exit code `2` for the `step_5_web_1` container:

    ```bash
    docker compose ps
    NAME                COMMAND                  SERVICE             STATUS              PORTS
    step_5_db_1         "docker-entrypoint.s…"   db                  running             3306/tcp
    step_5_web_1        "./app"                  web                 exited (2)          
    ```
    
  * The `docker compose logs` command display more details:

    ```bash
    docker compose logs web
    Attaching to step_5_web_1
    web_1  | panic: dial tcp 172.18.0.2:3306: connect: connection refused
    ...
    ```

  * Start the `web` container:

    ```bash
    docker compose start web
    docker compose ps
    NAME                COMMAND                  SERVICE             STATUS              PORTS
    step_5_db_1         "docker-entrypoint.s…"   db                  running             3306/tcp
    step_5_web_1        "./app"                  web                 running             0.0.0.0:8080->8080/tcp, :::8080->8080/tcp
    ```

* Test the application:

  ```bash
  curl http://localhost:8080/pong/step_5/message_1
  curl http://localhost:8080/pong/step_5/message_2
  docker compose exec \
    db \
    mysql \
      -hlocalhost \
      -P3306 \
      -uroot \
      -pmy-secret-pw \
      -e "SELECT * FROM ping.history;"
  ```
  
* Stop and remove the containers and their associated resources:

  ```bash
  # docker compose stop
  # docker compose rm
  # docker network rm step_5_default
  # Or
  docker compose down
  ```

## Step 6 - Control the startup order and persist data

* Create a new directory `step_6`.

* Import the files `app.go`, `go.mod`, `go.sum` and `Dockerfile`. They remain identical to the `step_5` files.

* Modify the `docker-compose.yml` declaration:

  ```yml
  services:
    web:
      build: .
      depends_on:
        - db
      ports:
        - "8080:8080"
      env_file:
        - ".env"
    db:
      image: 'mariadb'
      env_file:
        - ".env"
      volumes:
        - db_data:/var/lib/mysql
  
  volumes:
      db_data: {}
  ```

  * A volume `db_data` persists the MariaDB database.

  * Container `web` depends on container `db`.

  * Container `db` is associated with the `db` hostname.

* Modify the `.env` file to reflect the `db` container hostname:

  ```bash
  cat <<EOF > .env 
  MYSQL_HOST=db
  MYSQL_PASSWORD=my-secret-pw
  MYSQL_ROOT_PASSWORD=my-secret-pw
  EOF
  ```

* Build and create containers:

  ```bash
  docker compose build
  docker compose up --no-start
  ```

* Then, start containers with `docker compose start`:

  * It outputs the log saying the containers are started in the expected order:
  
    ```bash
    [+] Running 2/2
     ⠿ Container step_6_db_1    Started   0.4s
     ⠿ Container step_6_web_1   Started   0.4s
    ```

  * Validate the state of the containers with `docker compose ps`, it outputs:
    
    ```
    NAME                COMMAND                  SERVICE             STATUS              PORTS
    step_6_db_1         "docker-entrypoint.s…"   db                  running             3306/tcp
    step_6_web_1        "./app"                  web                 exited (2)          
    ```
  
  * Why the state of the `web` service is still `Exit 2` while it is started after the `db` service? 

  * Stop and remove the containers, start them again and validate their status.

    ```
    docker compose down
    docker compose up -d
    docker compose ps
    ```
  
  * It outputs:
  
    ```
    NAME                COMMAND                  SERVICE             STATUS              PORTS
    step_6_db_1         "docker-entrypoint.s…"   db                  running             3306/tcp
    step_6_web_1        "./app"                  web                 running             0.0.0.0:8080->8080/tcp, :::8080->8080/tcp
    ```
  
  * The reason for the first `web` service failure is that MariaDB takes some time to start. Even though the `db` service is running, port `3306` is not yet listening, so the `web` service crashes. The second time MariaDB start immediately because the initialization was already completed and saved in the volume.
  
* Check the volume creation:

  ```bash
  docker volume ls | grep step_6
  ```

* Insert some data:

  ```bash
  curl http://localhost:8080/pong/step_6/message_1
  curl http://localhost:8080/pong/step_6/message_2
  ```

* Destroy the container and restart them:

  ```bash
  docker compose stop
  docker compose rm
  docker compose ps
  docker compose create
  docker compose start
  docker compose ps
  ```

* Insert new data and validate that previous data where persisted:

  ```bash
  curl http://localhost:8080/pong/step_6/message_3
  curl http://localhost:8080/pong/step_6/message_4
  docker compose exec \
    db \
    mysql \
      -hlocalhost \
      -P3306 \
      -uroot \
      -pmy-secret-pw \
      -e "SELECT * FROM ping.history;"
  ```

* Stop and remove the containers and their associated resources:

  ```bash
  docker compose down
  docker volume rm step_6_db_data
  ```

## Step 7 - Define health checks

* Create a new directory `step_7`.

* Import the files `.env`, `app.go`, `go.mod`, `go.sum` and `Dockerfile`. They remain identical to `step_6`.

* Modify the `docker-compose.yml` file to define a health check for `db` and the `condition: service_healthy` property to the `web` service dependency:

  ```yaml
  services:
    web:
      build: .
      depends_on:
        db:
          condition: service_healthy
      env_file:
        - ".env"
      ports:
        - "8080:8080"
    db:
      env_file:
        - ".env"
      image: 'mariadb'
      healthcheck:
        test: ["CMD", "mysqladmin" ,"ping", "-h", "localhost"]
        interval: 10s
        timeout: 20s
        retries: 10
  ```
  
* Create and start containers with `docker compose up -d`.

* Now, the `web` service is not starting until `db` is has the `healthy` state. Validate the state with `docker compose ps`, it outputs:

  ```bash
  NAME                COMMAND                  SERVICE             STATUS               PORTS
  step_7_db_1         "docker-entrypoint.s…"   db                  running (healthy)    3306/tcp
  step_7_web_1        "./app"                  web                 running              0.0.0.0:8080->8080/tcp, :::8080->8080/tcp
  ```

* Now let's create a health check for the `web` service. Expose a health check HTTP endpoint for the Go application. Modify the `step_7/app.go` file to contain the following:

  ```go
  ...
  func main() {
      dbInit()
      // Default endpoint
      http.HandleFunc("/", handler)
      // Health check endpoint
      lastcheck := time.Now()
      http.HandleFunc("/healthz", func (w http.ResponseWriter, r *http.Request) {
          duration := time.Now().Sub(lastcheck)
          lastcheck = time.Now()
          if duration.Seconds() > 10 {
              w.WriteHeader(500)
              w.Write([]byte(fmt.Sprintf("error: %v", duration.Seconds())))
          } else {
              w.WriteHeader(200)
              w.Write([]byte("ok"))
          }
      })
      log.Fatal(http.ListenAndServe(":8080", nil))
  }
  ...
  ```

  * The health check HTTP endpoint is `/healthz`
  * The application is considered healthy if the endpoint was called in the last 10 seconds.

* Install `curl` to the `web` service image. It will be required to send health checks. Modify `Dockerfile` to contain the following:

  ```Dockerfile
  ...
  RUN apk --no-cache add curl
  CMD ["./app"]
  ```

* Declare the `healthcheck` property of the `web` service in the `docker-compose.yml` file like this:

  ```yaml
  services:
    web:
      ...
      healthcheck:
        test: curl -f http://localhost:8080/healthz || exit 1
        interval: 20s
        retries: 5
      ...
  ```

  * The `test` command of healtcheck properties could be written either as a string or as a list

* Build, start the containers and validate their status:

  ```bash
  docker compose build
  docker compose up -d
  docker compose ps
  ```
  
  * It now outputs the heath status of services:
    ```
    NAME                COMMAND                  SERVICE             STATUS              PORTS
    step_7_db_1         "docker-entrypoint.s…"   db                  running (healthy)   3306/tcp
    step_7_web_1        "./app"                  web                 running (starting)  0.0.0.0:8080->8080/tcp, :::8080->8080/tcp
    ```
  
  * After a few minutes the `web` service becomes unhealthy. Why? 
    ```
    NAME                COMMAND                  SERVICE             STATUS              PORTS
    step_7_db_1         "docker-entrypoint.s…"   db                  running (healthy)   3306/tcp
    step_7_web_1        "./app"                  web                 running (unhealthy) 0.0.0.0:8080->8080/tcp, :::8080->8080/tcp
    ```
  
  * Tune `healthcheck.interval` to reflect the application behaviour and make the `web` service healthy.

* Stop and remove the containers and their associated resources:

  ```
  docker compose down
  ```

## Step 8 - Restart failing containers

* Create a new directory `step_8`.

* Import the files `.env`, `app.go`, `go.mod`, `go.sum`, `docker-compose.yml` and `Dockerfile` from `step_5` into `step_8`.

* Modify the `step_8/.env` file to reflect the new hostname of container `db`:

```bash
cat <<EOF > .env 
MYSQL_HOST=db
MYSQL_PASSWORD=my-secret-pw
MYSQL_ROOT_PASSWORD=my-secret-pw
EOF
```

* Run `docker compose build && docker compose up -d`

* Run `docker compose logs web`. What happened to the web service?

* Run `docker compose ps`. What is the state of the web service?

The logs and the current state of the web service explain that:
  * The DB service wasn't ready when the web service tried to connect to it.
  * The web service went down due to the DB connection error (Exit 2).
  * The web service didn't get restarted.

* Update `step_8/docker-compose.yml` to include a [suitable restart policy](https://docs.docker.com/config/containers/start-containers-automatically/):

  ```yml
  services:
    web:
      build: .
      ports:
        - "8080:8080"
      env_file:
        - ".env"
      restart: unless-stopped # Restart policy added
    db:
      image: 'mariadb'
      env_file:
        - ".env"
  ```

* Run `docker compose build && docker compose up -d`. 

* Run `docker compose ps`. What does the terminal output suggest?

* Run `docker compose stop web`. Based on the restart policy, do you think the web service will restart? Check with it `docker compose ps`.

* How could we ensure that services are always restarted regardless of the reason they go down?

* Why might you want to avoid restarting containers?

* Remove the resources created in this step:

```bash
docker compose down
```

## Step 9 - Use YAML anchors to remove duplication in compose file

* YAML anchors enable values or mappings to be defined once and referenced multiple times throughout a compose file:

  * Easily duplicate YAML content across your document.
  * Update all references to an anchor with a single modification to the anchor.
  * Reduce compose file line count.
  * Use descriptive names for anchors to communicate their function when referenced.

* Create a new directory `step_9`.

* Import the files `.env`, `app.go`, `go.mod`, `go.sum`, `docker-compose.yml` and `Dockerfile`. They remain identical to `step_8`.

* Run `docker compose build && docker compose up -d`. 

* Update the `step_9/docker-compose.yml` file as follows:

  ```yml
  x-env_file: &env_file # x- prefix mandatory for anchoring yaml mappings
    env_file: 
      - ".env"
  services:
    web:
      build: .
      depends_on:
        - db
      <<: *env_file # Merges the env_file mapping, inset to the << symbol.
      ports:
        - "8080:8080"
      restart: unless-stopped
    db:
      <<: *env_file # Here too
      image: 'mariadb'
  ```

* Run `docker compose up -d` again. Does Docker Compose modifies the existing containers? Why?

* Remove created resources in this step:

  ```bash
  docker compose down
  ```

## Step 10 - Leveraging multiple compose files

* Docker Compose reads two files by default: a `docker-compose.yml` file, and an optional `docker-compose.override.yml` file. The `docker-compose.override.yml` file can be used to store overrides of the existing services or define new services.

* Create a new directory `step_10`.

* Import the files `.env`, `app.go`, `go.mod`, `go.sum`, `docker-compose.yml` and `Dockerfile`. They remain identical to `step_9`.

* Remove `ports` and volume configuration from `step_10/docker-compose.yml`. Modify it to:

  ```yml
  x-env_file: &env_file
    env_file: 
      - ".env"
  services:
    web:
      build: .
      depends_on:
        - db
      <<: *env_file
      restart: unless-stopped
    db:
      <<: *env_file
      image: 'mariadb'
  ```

* Create a new file named `docker-compose.override.yml` and add the below contents:

  ```yml
  services:
    web:
      ports:
        - 8080:8080
    db:
      volumes:
        - db_data:/var/lib/mysql
  volumes:
      db_data: {}
  ```

* Run `docker compose up -d` and verify that:

  * the DB volume defined exists:

    ```bash
    docker volume ls | grep step_10_db_data
    ```

  * the `web` service is listening on `localhost:8080`:
    
    ```bash
    curl http://localhost:8080/pong
    Value inserted: pong
    ```

* Remove created resources:

  ```bash
  docker compose down
  docker volume rm step_10_db_data
  ```

* To use multiple override files, or an override file with a different name, you can use the `-f` option of the `docker-compose` command to specify the list of files.

* Create a new file named `docker-compose-dev.yml` which stores development configurations and add the below contents:

  ```yml
  services:
    web:
      ports:
        - 8080:8080
    db:
      volumes:
        - db_data_dev:/var/lib/mysql
  volumes:
      db_data_dev: {}
  ```

* Create a new file named `docker-compose-prod.yml` which stores production configurations and add the below contents:

  ```yml
  services:
    web:
      ports:
        - 80:8080
    db:
      volumes:
        - db_data_prod:/var/lib/mysql
  volumes:
      db_data_prod: {}
  ```

* These compose files enable us to launch:

  * a **development** environment where container port is mapped to the host port `8080` for the `web` service, and a development DB volume is used by the `db` service.

  * a **production** environment where container port is mapped to the host port `80` for the `web` service, and a production DB volume is used by the `db` service.

* To contextualize the environment, call `docker-compose` with multiple `--file <file>` (`-f <file>`) arguments in order of priority. The various compose files are merged with the ones on the right taking precedence over the ones on the left.

* Run `docker compose -f docker-compose.yml -f docker-compose-dev.yml up -d` to launch a development environment:

  * Verify that the development volume defined in `docker-compose-dev.yml` exists:

    ```bash
    docker volume ls | grep step_10_db_data_dev
    ```

  * Verify that the `web` service is listening on `localhost:8080`:
    
    ```bash
    curl http://localhost:8080/pong
    Value inserted: pong
    ```

* Run `docker compose -f docker-compose.yml -f docker-compose-prod.yml up -d` to launch a production environment:

  * Verify that the development volume defined in `docker-compose-dev.yml` exists:

    ```bash
    docker volume ls | grep step_10_db_data_prod
    ```

  * Verify that the `web` service is listening on `localhost:80`:
    
    ```bash
    curl http://localhost:80/pong
    Value inserted: pong
    ```
  
* Remove the resources created in this step:

  ```bash
  docker compose ps
  docker volume rm step_10_db_data_dev
  docker volume rm step_10_db_data_prod
  ```
