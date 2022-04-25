
docker run \
  -p 127.0.0.1:3306:3306 \
  -h ping-mariadb \
  -e MYSQL_ROOT_PASSWORD=my-secret-pw \
  -d \
  --name ping-mariadb \
  mariadb:latest

docker run \
  -it \
  --rm \
  mariadb mysql \
    -h172.17.0.2 \
    -p3306 \
    -uroot \
    -pmy-secret-pw \
    -e "CREATE DATABASE IF NOT EXISTS ping;" \
    -e "CREATE TABLE IF NOT EXISTS ping.history (message CHAR(255));"

# docker build -f Dockerfile.mariadb -t ping_mariadb:step_2 .
# echo "Test http://localhost:8080/pong"
# docker run -p 8080:8080 ping:step_2