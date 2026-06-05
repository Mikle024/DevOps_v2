# Docker Swarm

**Docker Swarm** is an orchestration tool that comes with *Docker*. Orchestration involves managing containers distributed across multiple nodes within a cluster. Orchestration allows you to achieve:
- automatic balancing of containers between nodes;
- higher system scalability (adding new nodes and redistributing load);
- restart "failing" deployed software modules or perform *disaster recovery*; in other words, the orchestration tool maintains high *availability* of the system;
- security of traffic between different nodes within the cluster;
- and most importantly, it combines the entire complex application structure with a microservice architecture into a single entity with a single entry point. This encapsulates all the complexity and interacts with the user in the same manner as a monolith.

Working with Docker Swarm is easy. Simply divide nodes into two groups: managers and work nodes or *workers*. Then, execute several commands.

The managers are the nodes that distribute tasks to the worker nodes and ensure a consistent state of execution. The tasks themselves correspond to services — replica sets of a Docker image. There can be more than one replica of a single Docker image. One task corresponds to one replica. Thus, managers distribute tasks to workers equal to the sum of the replicas of all running services, balancing them by workload. When a task is assigned to a worker, a container corresponding to the service image is started on that worker.

When nodes are combined into a swarm, their Docker engines communicate via a special overlay network, which enables correct orchestration. The overlay network driver creates a distributed network between the Docker engines. This network overlays the host-specific networks, enabling containers connected to it (including Swarm service containers) to securely exchange data when encryption is enabled. Docker transparently handles routing each packet to and from each specific Docker engine host and container.

To designate a node as a manager, run the command: `docker swarm init --advertise-addr [ip address of the machine to send to the overlay network]`. This generates a join token for the workers of this manager. You can save this token using the command `docker swarm join-token`.

To connect a worker to a manager, use the command: `docker swarm join --token [token] [manager's ip address]`.

To deploy all the services of an application at once, use the Compose file and the command: `docker stack deploy`. However, since each service's task can eventually be delegated to any worker, the images must be "reachable" from any node. This means that all images must be loaded into an available Docker registry (e.g., a personal registry on Docker Hub). Then, all service images in the Compose file must be replaced with the images that were loaded into the selected Docker registry.

