FROM ubuntu:14.04
MAINTAINER Guilherme Maluf <guimalufb@gmail.com>

RUN useradd -r ophidia -d /usr/local/ophidia
RUN mkdir -p /usr/local/ophidia/src \
             /var/www/html/ophidia \
             /usr/local/lib/pkgconfig

RUN echo "Acquire::http::Proxy \"http://roadrash:3142\";" | sudo tee /etc/apt/apt.conf.d/01proxy

RUN apt-get update && apt-get install -y \
		guile-2.0-dev \
		libcurl4-openssl-dev \
		libgsl0-dev \
		libgtk2.0-dev \
		libhdf5-dev \
		libjansson-dev \
		libmatheval-dev \
		libmysqld-dev \
		libssh2-1-dev \
		libssl-dev \
		libxml2 \
		libxml2-dev \
		mpich \
		wget \
    build-essential \
    byacc \
    dh-autoreconf \
    flex \
    libbison-dev \
    libgraphviz-dev \
    libmysql-cil-dev \
    libreadline-dev \
    unzip \
    slurm-llnl \
    openssh-server \
  && rm -rf /var/lib/apt/lists/*

### Build dependencies

## gSoap
RUN wget -q http://tenet.dl.sourceforge.net/project/gsoap2/gSOAP/gsoap_2.8.27.zip -O /tmp/gsoap.zip \
    && unzip -qq -d /usr/local/ophidia/src/ /tmp/gsoap.zip && rm /tmp/gsoap.zip
WORKDIR /usr/local/ophidia/src/gsoap-2.8
RUN ./configure --prefix=/usr/local/ophidia/extra && make && make install

## HDF5
RUN wget https://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.8.16.tar.bz2 -qO- \
    | tar xj -C /usr/local/ophidia/src/
WORKDIR /usr/local/ophidia/src/hdf5-1.8.16
RUN CC=/usr/bin/mpicc ./configure --prefix=/usr/local/ophidia/extra --enable-parallel \
    && make && make install

## netCDF
RUN wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.4.0.tar.gz -qO- \
    | tar xz -C /usr/local/ophidia/src/
WORKDIR /usr/local/ophidia/src/netcdf-4.4.0
RUN CC=/usr/bin/mpicc \
    CPPFLAGS="-I/usr/local/ophidia/extra/include" \
    LDFLAGS="-L/usr/local/ophidia/extra/lib" \
    LIBS=-ldl \
    ./configure --prefix=/usr/local/ophidia/extra --enable-parallel-tests \
    && make && make install
###

### Ophidia projects
WORKDIR /usr/local/ophidia/src
COPY ophidia-primitives ./ophidia-primitives
COPY ophidia-analytics-framework ./ophidia-analytics-framework
COPY ophidia-server ./ophidia-server
COPY ophidia-terminal ./ophidia-terminal

WORKDIR /usr/local/ophidia/src/ophidia-primitives
RUN ln -s /usr/lib/x86_64-linux-gnu/pkgconfig/libmatheval.pc /usr/local/lib/pkgconfig/libmatheval.pc \
 && ./bootstrap \
 && ./configure --prefix=/usr/local/ophidia/oph-cluster/oph-primitives \
 && make && make install


WORKDIR  /usr/local/ophidia/src/ophidia-analytics-framework
COPY ophidia-analytics-framework_netcdf_vars.patch /usr/local/ophidia/src/ophidia-analytics-framework/
RUN patch -p1 < ophidia-analytics-framework_netcdf_vars.patch \
 && ./bootstrap \
 && ./configure  --prefix=/usr/local/ophidia/oph-cluster/oph-analytics-framework \
                 --enable-parallel-netcdf --with-netcdf-path=/usr/local/ophidia/extra/ \
                 --with-web-server-path=/var/www/html/ophidia --with-web-server-url=http://127.0.0.1/ophidia \
 && make && make install


WORKDIR /usr/local/ophidia/src/ophidia-server
COPY ophidia-server_ubuntu-makefile-libs.patch /usr/local/ophidia/src/ophidia-server/
RUN  patch -p1 < ophidia-server_ubuntu-makefile-libs.patch \
  && ./bootstrap \
  && ./configure --prefix=/usr/local/ophidia/oph-server \
                 --with-soapcpp2-path=/usr/local/ophidia/extra \
                 --enable-webaccess --with-web-server-path=/var/www/html/ophidia \
                 --with-web-server-url=http://127.0.0.1/ophidia \
  && make && make install \
  && cp -r /usr/local/ophidia/src/ophidia-server/authz /usr/local/ophidia/oph-server/ \
  && mkdir /usr/local/ophidia/oph-server/authz/sessions


WORKDIR /usr/local/ophidia/src/ophidia-terminal
COPY ophidia-terminal-cast.patch /usr/local/ophidia/src/ophidia-terminal/
RUN patch -p1 < ophidia-terminal-cast.patch \
  && ./bootstrap \
  && ./configure --prefix=/usr/local/ophidia/oph-terminal \
  && make && make install

####

RUN ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa \
  && cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys \
  && echo 'Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null' > /root/.ssh/config \
  && sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

## Slurm
RUN /usr/sbin/create-munge-key \
  && echo "OPTIONS=\"--force --num-threads 1\"" >> /etc/default/munge \
  && mkdir -p /var/run/slurm-llnl/
COPY slurm.conf /etc/slurm-llnl/

RUN apt-get purge -fy \
		wget \
    build-essential \
    byacc \
    dh-autoreconf \
    flex \
    unzip \
 && apt-get clean autoclean && apt-get autoremove -fy

RUN rm -rf /usr/local/ophidia/src /var/lib/{apt,dpkg,cache,log}/

WORKDIR /etc/ssl/private/
RUN openssl genrsa -out rootCA.key 2048 \
  && openssl req -x509 -new -nodes -key rootCA.key \
     -sha256 -days 1024 -out rootCA.pem \
     -subj "/C=BR/ST=MG/L=BH/O=BigSea/OU=Speed/CN=*" \
  && openssl genrsa -out server.key 2048 \
  && openssl req -new -key server.key -out server.csr \
     -subj "/C=BR/ST=MG/L=BH/O=BigSea/OU=Speed/CN=*" \
  && openssl x509 -req -in server.csr \
     -CA rootCA.pem -CAkey rootCA.key -CAcreateserial \
     -out server.crt -days 500 -sha256 \
  && cat server.key server.crt > server.pem

WORKDIR /usr/local/ophidia

ENV PATH=$PATH:/usr/local/ophidia/oph-cluster/oph-analytics-framework/bin:/usr/local/ophidia/oph-terminal/bin:/usr/local/ophidia/extra/bin:/usr/local/ophidia/oph-server/bin
ADD entrypoint /sbin/
ENTRYPOINT ["/sbin/entrypoint"]
CMD ["server"]
