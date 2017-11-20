Running Ophidia Cluster
----------------------
This is a small doc on how to run a Ophidia cluster with docker containers.
We define a MySQL container with Ophidia libraries and Ophidia container with
slurm, munge and everything needed

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

#### Quick way
`docker-run` is a small bash script with full Ophidia stack and configuration
```bash
$ ./docker-run all
```

#### Ophidia MySQL container
Ophidia needs a MySQL instance with a set of specific libraries
```bash
$ docker run --name oph_mysql -d \
  --volume ${PWD}/mysql/initdb:/docker-entrypoint-initdb.d \
  --env MYSQL_ROOT_PASSWORD=root \
  bigsea/ophidia_mysql
```
More info and features about this container can be found on [MySQL official
container docs](https://hub.docker.com/_/mysql/)

#### Ophidia Server container
This is a fat container with slurm, munge, apache and whole ophidia stack
```bash
$ docker run -d --name oph-server --hostname oph-server \
    --volume ${PWD}/slurm.conf:/etc/slurm-llnl/slurm.conf \
    --volume ${PWD}/conf/authz:/usr/local/ophidia/oph-server/authz \
    --volume ${PWD}/conf/oph-server/ophidiadb.conf:/usr/local/ophidia/oph-server/etc/ophidiadb.conf \
    --volume ${PWD}/conf/oph-server/rmanager.conf:/usr/local/ophidia/oph-server/etc/rmanager.conf \
    --volume ${PWD}/conf/oph-server/server.conf:/usr/local/ophidia/oph-server/etc/server.conf \
    --volume ${PWD}/conf/oph-analytics-framework/oph_configuration:/usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/oph_configuration \
    --volume ${PWD}/conf/oph-analytics-framework/oph_dim_configuration:/usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/oph_dim_configuration \
    --volume ${PWD}/conf/oph-analytics-framework/oph_soap_configuration:/usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/oph_soap_configuration \
    --link oph-mysql:mysql \
    bigsea/ophidia
```
All ophidia config files are hosted on `conf` directory and mapped inside the container.

More info on how to use, [install and configure](http://ophidia.cmcc.it/documentation/admin/configure/index.html) Ophidia can be found [here](http://ophidia.cmcc.it/documentation/)

#### Ophidia Terminal container
```bash
$ docker run -ti --rm --name oph-term \
    --link oph-server:oph-server \
    bigsea/ophidia term
```
Environment variables can also be defined on `term`
```
$ docker run -ti --rm --name oph-term \
    --link oph-server:oph-server \
		--env OPH_SERVER_HOST=172.17.0.10 \
		--env OPH_SERVER_PORT=11732 \
		--env OPH_USER=oph-test \
		--env OPH_PASSWD=abcd \
    bigsea/ophidia term
```

Run a shell inside the ophidia server container:
```
docker exec -it oph-server bash
```

Follow the logfile:
```
tail -f /var/log/oph_server
```

# Examples
## Creation of NetCDF containers

## PyOphidia

```bash
$ ./docker-run python
```
