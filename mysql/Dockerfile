FROM mysql:5.6
MAINTAINER Guilherme Maluf <guimalufb@gmail.com>

ADD  liboph/ /usr/lib/mysql/plugin/

RUN apt-get update  \
 && apt-get install -fy \
    libgsl0ldbl \
    libmatheval1 \
 && rm -rf /var/lib/apt/lists/*

