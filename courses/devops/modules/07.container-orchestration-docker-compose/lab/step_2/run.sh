docker build -t ping:step_2 .
echo 'Run `curl http://localhost:8080/pong/step_2`'
echo 'Print `Message received: pong/step_2!`'
docker run -p 8080:8080 ping:step_2
