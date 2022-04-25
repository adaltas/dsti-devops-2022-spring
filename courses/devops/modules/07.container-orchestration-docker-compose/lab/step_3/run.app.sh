
export MYSQL_HOST=`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ping-mariadb`
export MYSQL_PASSWORD='my-secret-pw'

echo $MYSQL_HOST
echo $MYSQL_PASSWORD

docker build -t ping_app:step_3 .
docker run \
  -p 8080:8080 \
  -d \
  -e MYSQL_HOST=$MYSQL_HOST \
  -e MYSQL_PASSWORD \
  --name ping_app \
  ping_app:step_3
echo 'Run `curl http://localhost:8080/pong/step_3`'
echo 'Print `Message received: pong/step_3!`'