
# Docker Compose

- is a tool for defining and running multi-container Docker applications
- Uses a compose (configuration) YAML file   
- A way to document and configure all of the application’s service dependencies (databases, queues, caches, web service APIs, etc)
- Only one single command to create and start containers - `docker compose up` (or `docker-compose up`)

## Use cases

1. **Development environments**   
    When you’re developing software, the ability to run an application in an isolated environment and interact with it is crucial. The Compose command-line tool can be used to create the environment and interact with it.

2. **Automated testing environments**   
    An important part of any Continuous Deployment or Continuous Integration process is the automated test suite. Automated end-to-end testing requires an environment in which to run tests. Docker Compose provides a convenient way to create and destroy isolated testing environments for your test suite.

3. **Single host deployments**   
    To deploy to a remote Docker Engine.

## Using Docker Compose

A three-step process:

1. Define your app’s environment with a `Dockerfile` so it can be reproduced anywhere.
2. Define the services that make up your app in `docker-compose.yml` so they can be run together in an isolated environment.
3. Run `docker compose up` and Compose starts and runs your entire app.

## Structure of `docker-compose.yml`

- The `version` of the compose file (deprecated).
- The `services` which will be built.
- All used `volumes`.
- The `networks` which connect the different services.

[Read more](https://docs.docker.com/compose/compose-file/compose-file-v3/)

## Example: WordPress website

The `docker-compose.yml` file contains:

```yaml
version: '3.3'

services:
   db:
     image: mysql:5.7
     volumes:
       - db_data:/var/lib/mysql
     networks:
       - backend
     environment:
       MYSQL_ROOT_PASSWORD: somewordpress
       MYSQL_DATABASE: wordpress
       MYSQL_USER: wordpress
       MYSQL_PASSWORD: wordpress
   wordpress:
     depends_on:
       - db
     image: wordpress:latest
     ports:
       - "8000:80" # host:container
     networks:
       - backend
     environment:
       WORDPRESS_DB_HOST: db:3306
       WORDPRESS_DB_USER: wordpress
       WORDPRESS_DB_PASSWORD: wordpress
       WORDPRESS_DB_NAME: wordpress
volumes:
    db_data: {}
networks:
  backend:
    driver: bridge
```

## Services configuration in Docker Compose

TODO...

Top-level keys:
- `build`
- `deploy`
- `depends_on`
- `networks`

[Read more](https://docs.docker.com/compose/compose-file/compose-file-v3/#service-configuration-reference)

## Docker Compose commands

- `docker compose up` - Create and start containers.
- `docker compose down` - Stop and remove containers, networks, images, and volumes.
- `docker compose start` - Start services.
- `docker compose stop` - Stop services.
- `docker compose exec` - Execute a command in a running container.
- `docker compose rm` - Remove stopped containers.
- `docker compose up --scale` - Set number of containers for a service.
- ...

## Advanced Docker Compose

* [See production apps with Docker Compose](https://nickjanetakis.com/blog/best-practices-around-production-ready-web-apps-with-docker-compose)

* Dropping the `version` property at the top of the file.

  * Property is deprecated.
  * Only defined in the spec for backward compatibility.

* Avoiding 2 Compose Files for Dev and Prod with an Override File.

  * Use the same `docker-compose.yml` in all environments when possible or run certain containers in development but not in production.
  * Solved with a `docker-compose.override.yml` file.
  * Add this override file to your `.gitignore` file.
  * For developer convenience, add a `docker-compose.override.yml.example` in git which can be copied.
  * To use multiple override files, or an override file with a different name, you can use the `-f` option to specify the list of files (ex. `docker compose -f docker-compose-base.yml -f docker-compose-prod.ymal up`)

* Reducing Service Duplication with Aliases and Anchors

  * Use [YAML’s aliases and anchors](https://yaml.org/spec/1.2/spec.html#id2765878) feature along with [extension fields](https://docs.docker.com/compose/compose-file/compose-file-v3/#extension-fields) from Docker Compose.

  * Extension field start by `x-` and are ignored.

    ```yaml
    x-app: &default-app
      ...
      env_file:
      - ".env"
      ...
    
    web:
      <<: *default-app
      ports:
      - "${DOCKER_WEB_PORT_FORWARD:-127.0.0.1:8000}:8000"
    
    worker:
      <<: *default-app
      command: celery -A "hello.app.celery_app" worker -l "${CELERY_LOG_LEVEL:-info}"
    ```

* Defining your HEALTHCHECK in Docker Compose not your Dockerfile

  * Do not make assumptions about where apps are deployed (Docker Compose, VPS, Kubernetes, Heroku, ..)

  * Usage of Docker is drastically different depending on the platform

  * Kubernetes disable HEALTHCHECK if it finds one in the Dockerfile because it has its own readiness checks

    ```yaml
    web:
        <<: *default-app
        healthcheck:
          test: "${DOCKER_WEB_HEALTHCHECK_TEST:-curl localhost:8000/up}"
          interval: "60s"
          timeout: "3s"
          start_period: "5s"
          retries: 3
    ```

  * Use default and set `export DOCKER_WEB_HEALTHCHECK_TEST=/bin/true` in development.

* Making the most of environment variables

  * Use an `.env` file that’s ignored from version control.

  * Contains a combination of secrets along with anything that might change between development and production.

  * Include an `.env.example` file and commit it to version control with non-secret environment variables.

  * Easy to get up and running in development and CI by copying this file to `.env`.

  * Document the file extensively, eg

    ```yaml
    # Which environment is running? These should be "development" or "production".
    #export FLASK_ENV=production
    #export NODE_ENV=production
    export FLASK_ENV=development
    export NODE_ENV=development
    ```

  * Use `export` in `.env` files to source them in other scripts.
  
  * Also set a default value in case it’s not defined which you can do with `${FLASK_ENV:-production}`.
  
* Publishing ports more securely in production

  ```yaml
  web:
    ports:
      - "${DOCKER_WEB_PORT_FORWARD:-127.0.0.1:8000}:8000"
  ```

  * Restricted to only allow localhost connections by default.

  * Allow less restricted rules in development, eg `export DOCKER_WEB_PORT_FORWARD=8000` in the `.env` file to allow connections from anywhere.

* Taking advantage of Docker’s restart policies.

  ```yaml
  web:
    restart: "${DOCKER_RESTART_POLICY:-unless-stopped}"
  ```

  * Using `unless-stopped` in production ensure that containers come up after rebooting or if they crash in such a way that they can be recovered by restarting.

  * Inappropriate in development mode, set `export DOCKER_RESTART_POLICY=no`.

* Switching up your bind mounts depending on your environment.

  ```yaml
  web:
    volumes:
      - "${DOCKER_WEB_VOLUME:-./public:/app/public}"
  ```

  In development, be less restricted with `export DOCKER_WEB_VOLUME=.:/app` to benefit from code updates without having to rebuild the image.

* Limiting CPU and memory resources of your containers

  ```yaml
  web:
    deploy:
      resources:
        limits:
          cpus: "${DOCKER_WEB_CPUS:-0}"
          memory: "${DOCKER_WEB_MEMORY:-0}"
  ```

  * With `0`, services use as many resources as they need which is effectively the same as not defining these properties.

  * The more complex the targeted platform, the more important it gets, provide information about the app's expectations.

* Log to standard out (stdout).

  * Don't log to a file in the container or use a volume.
  * Centralize log management at the Docker daemon level with `stdout`.
  * Redirect all logs to `journalctl` a 3rd party service.

* Create and respect naming conventions with environment variables.

  * Namespace by concern.
  * Re-use existing names like the one present in a dependent image, eg if using the official PostgreSQL image, re-use `POSTGRES_` names.

* Setting up a health check URL endpoint, for example in Python:

  ```python
  @page.get("/up")
  def up():
      redis.ping()
      db.engine.execute("SELECT 1")
      return ""
  ```

  * eg, use the `200` HTTP status code unless something abnormal happens

  * Integrable with Docker Compose, Kubernetes, or an external monitoring service like Uptime Robot.

* Running your container as a non-root user

  ```
  # These lines are important but I've commented them out to focus going over the other 3 lines.
  # FROM node:14.15.5-buster-slim AS webpack
  # WORKDIR /app/assets
  # RUN mkdir -p /node_modules && chown node:node -R /node_modules /app
  
  USER node
  
  COPY --chown=node:node assets/package.json assets/*yarn* ./
  
  RUN yarn install
  ```

  * Limit the attack surface.

  * Re-use the image user if any, eg the `node` user in the above example, or `useradd --create-home python`.

  * With volume mounted files, `uid` and `gid` are usually preserved between the host and container, using `1000` as the first created user, disable the mounts in CI.

* Customizing where package dependencies get installed

  ```bash
  RUN mkdir -p /node_modules && chown node:node -R /node_modules /app && \
    yarn config set -- --modules-folder /node_modules
  ```

  * This way, dependencies are not volume mounted

* Taking advantage of layer caching

  ```bash
  COPY --chown=node:node assets/package.json assets/*yarn* ./
  RUN yarn install
  COPY --chown=node:node assets .
  ```

  * This way, Docker caches the dependencies in the top layer, and application changes will be much faster to build

* Using build arguments

  ```bash
  ARG NODE_ENV="production"
  ENV NODE_ENV="${NODE_ENV}" \
      USER="node"
  
  RUN if [ "${NODE_ENV}" != "development" ]; then \
    yarn run build; else mkdir -p /app/public; fi
  ```

  * Set environment variables in your image without hard-coding their value

  * Set particular variables depending on the environment

  * Define the build argument in the `docker-compose.yml` file

    ```yaml
    x-app: &default-app
      build:
        context: "."
        target: "app"
        args:
          - "FLASK_ENV=${FLASK_ENV:-production}"
          - "NODE_ENV=${NODE_ENV:-production}"
    ```

  * Leverage `.env` as a single source of truth
