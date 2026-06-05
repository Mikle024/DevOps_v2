# Docker

## Reminder about Docker

Remember that **Docker** is the de facto standard for containerization tools in IT. Containerization naturally evolved from the concept of virtualizing application runtime environments, encapsulating all necessary dependencies within a separate entity. Before containers existed, the problem of inconsistent program execution due to environment configuration and dependency version differences was solved by virtualizing several machines on one computer. In other words, several virtual machines were created on the same physical machine.

Virtual machines emulate a computer using software by allocating resources from the host operating system — the physical machine on which the virtual machines run. Note that allocating resources means they will no longer be available to the host until the virtual machine is disabled and destroyed. A virtual machine is an abstraction of a real machine with all its implications. It has virtual devices and, most importantly, its own complete operating system with a kernel. An operating system is a complex program that takes a long time to run and requires many resources. The host must have special software installed — a **hypervisor**, such as VirtualBox — which allocates resources to the operating systems of the virtual machines. As you might guess, this approach is very costly. Docker and the concept of containerization solve these problems. Separate containers use the host operating system kernel directly. They do not require a full OS or a hypervisor and use host resources dynamically — only as much as needed at any given time. Containers are much faster to run and can "stand up" on the same host in much larger quantities than virtual machines.

None of the above means that Docker containers are improved virtual machines or can safely be used as replacements. Virtual machines still perform their function since Docker containers give up many properties of real machines to achieve maximum lightness. They are not complete abstractions of real machines. For example, they don't have their own OS kernel, so you can't run a container with a Windows application on a Linux machine. However, MacOS automatically uses a virtual machine with a Linux kernel to run Docker containers, so there is nothing to worry about.

Docker has a client-service architecture. Rather than using a hypervisor, the service — **Docker Engine** — provides a REST API for creating and managing containers.

Use the command `docker` in the console to view the available basic commands.

To run a container with an application, first create a *Dockerfile* and place it in the application directory. A Dockerfile is a text file with instructions that tell the **Docker Engine** service what *image* to create using that application. These instructions usually include: 

1. The OS crippled version (corresponding to the host kernel, of course).
2. The runtime environment corresponding to the programming language in which the application is written (python, jre...).
3. Necessary libraries.
4. Application files copied from the host.
5. Environment variables.

This information is usually enough to create a container image, which is a template for building containers with this application. The image itself is not the target executable file, but rather the basis from which any Docker engine can create a Docker container, which is guaranteed to run the containerized application in the same way. The image can be added to the **Docker Hub** *registry* and used to run the container on any other machine, just like the source code on *GitHub* or *GitLab*.

Available instructions for Dockerfile:

1. *FROM* — the image that will be inherited when the new image is created.
2. *WORKDIR* — working directory, all commands will be executed from this directory.
3. *COPY* and *ADD* allow you to add new files and directories inside the container.
4. *RUN* — commands that will be executed in bash when building the image.
5. *ENV* sets environment variables.
6. *EXPOSE* tells **docker engine** which port the container will listen on during runtime.
7. *USER* — the user with whose rights the commands are run.
8. *CMD* and *ENTRYPOINT* allow you to define the commands that will be executed in bash when you run the container

The Dockerfile consists of a sequence of instructions. Each instruction creates a separate **layer** — a set of modified files within the image after the instruction is applied. All layers are cached, which optimizes image building because unchanged layers are simply removed from the cache. It is important to remember that **the instructions in the Dockerfile should be listed from the least to the most likely to modify files**.

The most common mistake is installing application dependencies and third-party project libraries after the source code has been fully copied. Then, every small change in the code will prevent the layer responsible for installing the libraries from being cached and cause it to be executed every time the image is built. However, if you first copy into the image only the files needed to install the dependencies, and then copy the program's source code after installing the dependencies, the cached layer with dependencies will be usable.

Container images have different tags, which are usually names indicating the version of the image. These tags can be either words or numbers. The reserved tag *latest* is created automatically and indicates the latest version of the layer.

Use the `docker image` command to get information about available image commands.

Usually a simple *Dockerfile* does the following:

1. Is inherited from some base image with an operating system and a preinstalled runtime environment (such an image can be found on Docker Hub) (command FROM).
2. Optionally creates a user so that the program is not executed "from root" (USER instruction).
3. Sets the remaining necessary dependencies (by RUN and possibly COPY instructions).
4. Copies the executable code of the program (COPY instruction).
5. Runs the application (CMD or ENTRYPOINT instruction).
6. Specifies the listening port (EXPOSE instruction).

Then, the container is built and run based on the created image. That's it! The program runs inside the container.
 
Use the `docker container` command to find out about the available container commands.

The most important advantage of Docker containers is that they can be shared easily. There are two ways to do this:

1. Save the image as an archive (`docker save` command).
2. Use your repository on the Docker Hub (`docker push` command).

## Docker Compose

**Docker Compose** is a tool for managing multi-container applications. It allows you to run and configure the interaction of different application modules allocated into services. A service is a stable concept for a single containerizable entity. Note that Docker Compose is a separate tool from the standard Docker engine package.

Deploying a multi-container application normally involves the following steps:

1. Write a multiservice application (this step has already been completed!).
2. Write a Dockerfile for each containerized service.
3. Write a Compose file in which each service is defined.
4. Build and run containers with the commands `docker-compose build` and `docker-compose up`.

The Compose file is written in YAML format and has the following structure:

```yaml
version: "3.8"                  # Docker Compose version
services:                       # a block describing each individual service
    gateway:                    # the name of any service can be arbitrary, but usually reflects its essence
        build: "./gateway"      # the path of the Dockerfile of this service
        ports:                  # port mapping
            - 8080:8080         # host: container
        environment:            # environment variables list
            SHOP_URL: https://shop
            SHOP_PORT: 8081
        command: <shell cmd>    # some command that will run instead of the CMD Dockerfile 
    shop:
        build: "./shop"
        <...>
    db:
        image: "postgres:15.1-alpine"   # instead of building a new image, you can use a ready-made public one, for example, for the database.
        volume:                         # volume is the memory outside the container for persistent data storage. Here the volume for that particular service is specified
            - shop_db:/var/lib/postgresql/data
    <...>                       # there can be any number of services  
volumes:                        # volume definition
    shop_db:   
```

Note that when run through Docker Compose, the names "gateway", "shop", and "db" will be resolved to the corresponding container host names. This occurs because, when you start containers with Docker Compose, a new virtual network is created containing as many hosts as the microservices defined in the Docker Compose file. This network also includes a DNS server that maps service names in the internal virtual network to IP addresses.

A common problem occurs when a dependent container is started before the container it depends on. For example, a database usually takes much longer to run than an ordinary service. In such cases, special `wait-for` shell scripts must be run before running the dependent application in a command or entrypoint. These shell scripts are freely available; one example is the `docker compose wait for it shell script`.

Use the commands `docker-compose`, `docker-compose build --help` and `docker-compose up --help` to find out about the available options and commands.