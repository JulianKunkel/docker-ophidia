FROM mysql:5.6

ADD  liboph/ /usr/lib/mysql/plugin/
COPY *.sql /docker-entrypoint-initdb.d/

RUN apt-get update  \
 && apt-get install -fy \
    libgsl0ldbl \
    libmatheval1 \
 && rm -rf /var/lib/apt/lists/*

