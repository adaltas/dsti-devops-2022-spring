
export MYSQL_HOST=`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ping-mariadb`
export MYSQL_PASSWORD='my-secret-pw'

echo -n '' > .env
echo "MYSQL_HOST=`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ping-mariadb`" >> .env
echo "MYSQL_PASSWORD=my-secret-pw" >> .env

docker build -t ping_app:step_4 .
docker run \
  -p 8080:8080 \
  -d \
  --env-file .env \
  --name ping_app \
  ping_app:step_4
echo 'Run `curl http://localhost:8080/pong/step_4`'
echo 'Print `Message received: pong/step_4!`'