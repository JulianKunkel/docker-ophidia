Running Ophidia Cluster
----------------------
This is a small doc on how to run a Ophidia cluster with docker containers.
We define a MySQL container with Ophidia libraries and Ophidia container with slurm, munge and everything needed

### Requirements
Make sure you have the following packages
* [docker](https://docs.docker.com/ "docker")
* [docker-compose](https://docs.docker.com/compose/overview/ "docker-compose")

Clone this repository and sync Ophidia repositories
```bash
$ git clone https://github.com/eubr-bigsea/docker-ophidia.git
$ cd docker-ophidia
$ git submodule update --init
```

### Building containers
They are not yet on docker.hub, so you must build them.

```bash
$ docker build -t bigsea/ophidia .
$ docker build -t bigsea/ophidia_mysql mysql
```

### Running Ophidia

#### mysql container
Ophidia needs a MySQL instance with a set of specific libraries
```bash
$ docker run --name oph_mysql -d \
  --volume ${PWD}/mysql/initdb:/docker-entrypoint-initdb.d \
  --env MYSQL_ROOT_PASSWORD=root \
  bigsea/ophidia-mysql
```
More info and features about this container can be found on [MySQL official container docs](https://hub.docker.com/_/mysql/)

