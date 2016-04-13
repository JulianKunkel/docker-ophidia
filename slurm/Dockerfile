FROM ubuntu:14.04
MAINTAINER Guilherme Maluf <guimalufb@gmail.com>

RUN apt-get update  \
 && apt-get install -fy slurm-llnl \
 && rm -rf /var/lib/apt/lists/*

RUN /usr/sbin/create-munge-key \
  && echo "OPTIONS=\"--force --num-threads 1\"" >> /etc/default/munge \
  && mkdir -p /var/run/slurm-llnl/

ADD entrypoint /sbin/
ENTRYPOINT ["/sbin/entrypoint"]
CMD ["node"]
