
docker run \
  -p 127.0.0.1:3306:3306 \
  -e MYSQL_ROOT_PASSWORD=my-secret-pw \
  -d \
  --name ping-mariadb \
  mariadb:latest

export MYSQL_HOST=`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ping-mariadb`
export MYSQL_PASSWORD='my-secret-pw'

echo $MYSQL_HOST
echo $MYSQL_PASSWORD

docker run \
  -it \
  --rm \
  mariadb mysql \
    -h$MYSQL_HOST \
    -p3306 \
    -uroot \
    -p$MYSQL_PASSWORD \
    -e "SHOW DATABASES;"
# docker build -f Dockerfile.mariadb -t ping_mariadb:step_2 .
# echo "Test http://localhost:8080/pong"
# docker run -p 8080:8080 ping:step_2