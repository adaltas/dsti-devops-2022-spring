
# Lab

Container orchestration with Kubernetes

## Objectives

1. Install Minikube
2. Learn to use `kubectl` commands
3. Learn to expose a Kubernetes service to the outside
4. Learn to scale up and down a Kubernetes deployment
5. Run a multiple pod application in Kubernetes
6. Deploy an app using Manifest yaml files
7. Use `emptyDir` storage
8. Use `hostPath` storage
9. Use PersistentVolume

## 1. Install Minikube

[Install Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) following the instructions depending on your OS.

Start Minikube with:
```
minikube start
```

Verify that everything is OK with:
```
minikube status
```

## 2. Learn to use `kubectl` commands

1. Open a terminal

2. Run a `deployment` with one `pod` with the following command:
   ```
   kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1
   ```
   `gcr.io/google-samples/kubernetes-bootcamp:v1` is a Docker image of a basic Node.js web application.
   
3. List all the running pods with:
   ```
   kubectl get pods
   ```
   Wait until Pod readiness reaches 1/1 and save the Pod name somewhere
   
4. Display the pod logs with:
   ```
   kubectl logs $POD_NAME
   ```
   
5. Run a command inside the pod with:
   ```
   kubectl exec $POD_NAME -- cat /etc/os-release
   ```
   
6. Open a shell inside the pod with:
   ```
   kubectl exec -ti $POD_NAME bash
   ```
   
7. List the content of the directory you are in and try to find the JavaScript source code file

8. Make sure that the web app is responding inside the container by querying it with `curl`

   > **Hint.** The port on which the app responds is defined in the `/server.js` JavaScript file
   
9. Are you able to query the web app outside of the pod (from your local machine)?

## 3. Learn to expose a Kubernetes service to the outside

1. Expose the deployment you created in the first part of the lab with:
   ```
   kubectl expose deployments/$DEPLOYMENT_NAME --type="NodePort" --port $PORT_NUMBER
   ```
   
   > **Hint.** You need to replace `$DEPLOYMENT_NAME` with the actual name of the `deployment` as well as `$PORT_NUMBER`
   
2. Find out on which port the service has been attached with:
   ```
   kubectl get services
   ```
3. Get the IP of your Minikube VM with:
   ```
   minikube ip
   ```
4. Using the answers of questions 2 and 3, open your web browser and try to reach the web app.

> **Note!** If you are using Docker driver in Minikube, you must create a tunnel to the cluster node (that is running as a Docker container). Run the command (replace `$SERVICE_NAME` with your service name):

```
minikube service $SERVICE_NAME
```

## 4. Learn to scale up and down a Kubernetes deployment

1. Scale up your deployment to a total number of 5 pods with:
  ```
  kubectl scale deployments/kubernetes-bootcamp --replicas=5
  ```

2. Make sure that you have 5 pods running using one of the commands we have seen in part 2 of the lab. Which command did you use?

3. Open the exposed service through your web browser again.
   Force refresh a couple of times using `CTRL+F5`
   What is happening? Why?
   
4. Scale down again your deployment to 2 pods and confirm the other 3 are not running anymore.

## 5. Run a multiple pod application in Kubernetes

1. Prepare to hit `CTRL+F5` on your browser multiple times right after launching the following command:
2. Update the Docker image used by the `deployment` with:
   ```
   kubectl set image deployments/$DEPLOYMENT_NAME kubernetes-bootcamp=jocatalin/kubernetes-bootcamp:v2
   ```
3. What happened to the web page?
4. Update the Docker image used by the `deployment` again by setting the image to `jocatalin/kubernetes-bootcamp:v3`
5. List all of the running pods, what is happening here?
6. Cancel the previous operation by running:
   ```
   kubectl rollout undo deployments/kubernetes-bootcamp
   ```
7. Roll back the service to the image we first chose in part 2 of the lab.

## 6. Deploy an app using Manifest yaml files

1. Clean up what you did in the previous part with:
   ```
   kubectl delete service $SERVICE_NAME
   kubectl delete deployment $DEPLOYMENT_NAME
   ```
2. Using the [deployment documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/), fill out the blank (`TO COMPLETE #1`) in [`./lab/bootcamp/deployment.yaml`](./lab/bootcamp/deployment.yaml) to define a deployment based on the one we ran in part 2.
3. Once you completed the file, go to the `./lab/bootcamp` directory and run:
   ```
   kubectl apply -f deployment.yaml
   ```
   Are the pods running?
4. Using the [service documentation](https://kubernetes.io/docs/concepts/services-networking/service/), fill out the blank in [`./lab/bootcamp/service.yaml`](./lab/bootcamp/service.yaml)
5. Once you completed the file, run:
   ```
   kubectl apply -f service.yaml
   ```
   Can you access the service through your web browser?
6. Fill out `TO COMPLETE #2` inside [`./lab/bootcamp/deployment.yaml`](./lab/bootcamp/deployment.yaml) to create 3 replicas of your app.
7. Once you completed the file, run:
   ```
   kubectl apply -f deployment.yaml
   ```
   Force refresh on the browser a couple of times. Are you hitting different replicas?

## 7. Use `emptyDir` storage

1. Complete the [`./lab/emptyDir/deployment.yml`](./lab/emptyDir/deployment.yml) file.

References:
- `emptyDir` usage - https://kubernetes.io/docs/concepts/storage/volumes/#emptydir
- Nginx Docker image usage - https://hub.docker.com/_/nginx

> **Hint.** Nginx will start an HTTP web server and respond with the content of HTML files located in `/usr/share/nginx/html` directory.

2. Run a pod applying configuration:

```
kubectl apply -f ./lab/emptyDir/deployment.yml
```

3. Enter to a container and `curl` localhost

List all the pods and find a name of a created pod

```
kubectl get pods
```

Enter to the container:

```
kubectl exec -it <POD_NAME> bash
```

Run `curl localhost` (or `curl localhost/index.html`, because by default of Nginx will point to `index.html` if you do not specify the filename)

It will output the page of the 403 error if there is no `index.html` file to respond with:

```html
<html>
<head><title>403 Forbidden</title></head>
<body>
<center><h1>403 Forbidden</h1></center>
<hr><center>nginx/1.19.2</center>
</body>
</html>
```

Or it outputs the content of the file `index.html` if there is one:

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
   body {
       width: 35em;
       margin: 0 auto;
       font-family: Tahoma, Verdana, Arial, sans-serif;
   }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

4. Create `index.html` file with some content **inside a container**

Being inside the container, run:
```
echo 'Hello from Kubernetes storage!' > /usr/share/nginx/html/index.html
```

Now, by running `curl localhost` it will output:

```
Hello from Kubernetes storage!
```

5. Verify

- When a **Pod is removed** from a node for any reason, the data in the `emptyDir` is deleted forever.   
 You can remove a pod using Kubernetes Dashboard that is started with `minikube dashboard` command or `kubectl delete pod/<POD_NAME>`.

- When a **container in a Pod is removed**, Kubernetes will create a new container and will mount the existing `emptyDir` volume to it.   
 Learn the Container ID with the command `kubectl describe pod/<POD_NAME>`. Then you can enter to Minikube Node with `minikube ssh` and manually remove the container with `docker rm -f CONTAINER_ID`.

## 8. Use `hostPath` storage

1. Complete the [`./lab/hostPath/deployment.yml`](./lab/hostPath/deployment.yml) file.

Use `/mnt/hostPath/` folder as the path on your virtual node file system.

References:
- `hostPath` usage - https://kubernetes.io/docs/concepts/storage/volumes/#hostpath

2. Run a pod applying configuration:

```
kubectl apply -f ./lab/hostPath/deployment.yml
```

Ensure that `curl localhost` responds with 403 error (step 3 in the previous task).

3. Create `/mnt/hostPath/index.html` file with some content **inside a VM**

Enter the VM with `minikube ssh` command. Then run:

```
sudo mkdir /mnt/hostPath
sudo chmod -R 777 /mnt/hostPath
sudo echo 'Hello from Kubernetes storage!' > /mnt/hostPath/index.html
```

Make sure you have successfully written to file: `cat /mnt/hostPath/index.html`

Run `curl localhost` from the container (not from the VM). It will output:

```
Hello from Kubernetes storage!
```

4. Verify

- When a **Pod is removed** from a node for any reason, the data in the `hostPath` will still remain.
- When multiple replicas of a **Pod** are created, they all bind to the same volume.   
 You can configure many replicas using `spec.replicas` parameter in the deployment configuration yaml file.

## 9. Use PersistentVolume

Reference to this tutorial and reproduce all of the steps - https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/

## Bonus tasks

1. Configure a Pod to use Secret - https://kubernetes.io/docs/concepts/configuration/secret/
2. Configuring Redis using a ConfigMap - https://kubernetes.io/docs/tutorials/configuration/configure-redis-using-configmap/
