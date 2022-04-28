
# Exam instructions

You will receive 30 **multiple and single choice questions** (MCQ). To prepare, you must review all of the course modules and continue working on your project for practice.

There will be 2 types of questions:

1. Familiarity with the core CLI commands of the tools and understanding of configurations.
2. Understanding the passed concepts.

Good luck!

## Example questions

### Question 1

You have the following `docker-compose.yml` file:

```yaml
services:
  web:
    build: .
    ports:
      - "3000:5000"
  redis:
    image: redis
    volumes:
      - my-vol:/data
volumes:
  my-vol:
```

Choose correct option(s):

* [ ] A: On Docker host, the `my-vol` folder contains Redis container data.
* [ ] B: On Docker host, the Docker area contains Redis container data.
* [ ] C: In `web` container, the Web application is accessible at `localhost:3000`.
* [ ] D: In `redis` container, the Web application is accessible at `web:5000`

### Question 2

Which command(s) delete(s) a running container?

* [ ] A: `docker kill $CONTAINER`
* [ ] B: `docker rmi $CONTAINER`
* [ ] C: `docker rm -f $CONTAINER`
* [ ] D: `docker rm $CONTAINER`

### Question 3

The Manifesto for Agile Software Development DOES NOT include the following item(s):

* [ ] A: Processes and tools over individuals and interactions
* [ ] B: Working software over comprehensive documentation
* [ ] C: Customer collaboration over contract negotiation
* [ ] D: Following a plan over responding to change

### Question 4

What Ansible does provide?

* [ ] A: Cloud provisioning
* [ ] B: Configuration management
* [ ] C: Container orchestration
* [ ] D: Application deployment
