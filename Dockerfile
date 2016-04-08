FROM ubuntu:14.04

#RUN useradd -r ophidia -d /usr/local/ophidia
RUN mkdir -p /usr/local/ophidia/{extra,src,oph-server,oph-terminal} \
             /usr/local/ophidia/oph-cluster/{oph-primitives,oph-analytics-framework} \
             /var/www/html/ophidia \
             /usr/local/lib/pkgconfig/

RUN echo "Acquire::http::Proxy \"http://roadrash:3142\";" | sudo tee /etc/apt/apt.conf.d/01proxy

RUN apt-get update && apt-get install -y \
		git \
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
    unzip \
#		libmunge-dev \
#		libreadline-dev \
	 && rm -rf /var/lib/apt/lists/*


### Build dependencies

## gSoap
RUN wget -q http://tenet.dl.sourceforge.net/project/gsoap2/gSOAP/gsoap_2.8.27.zip -O /tmp/gsoap.zip \
    && unzip -qq -d /usr/local/ophidia/src/ /tmp/gsoap.zip && rm /tmp/gsoap.zip
WORKDIR /usr/local/ophidia/src/gsoap-2.8
RUN ./configure --prefix=/usr/local/ophidia/extra && make && make install

## HDF5
RUN wget https://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.8.16.tar.bz2 -qO- \
    | tar xj -C /usr/local/ophidia/extra/
WORKDIR /usr/local/ophidia/extra/hdf5-1.8.16
RUN CC=/usr/bin/mpicc ./configure --prefix=/usr/local/ophidia/extra --enable-parallel \
    && make && make install

## netCDF
RUN wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.4.0.tar.gz -qO- \
    | tar xz -C /usr/local/ophidia/extra/
WORKDIR /usr/local/ophidia/extra/netcdf-4.4.0
RUN CC=/usr/bin/mpicc \
    CPPFLAGS="-I/usr/local/ophidia/extra/include" \
    LDFLAGS="-L/usr/local/ophidia/extra/lib" \
    LIBS=-ldl \
    ./configure --prefix=/usr/local/ophidia/extra --enable-parallel-tests \
    && make && make install

### Ophidia projects
WORKDIR /usr/local/ophidia/src
RUN git clone https://github.com/OphidiaBigData/ophidia-primitives ;\
    git clone https://github.com/OphidiaBigData/ophidia-analytics-framework ;\
    git clone https://github.com/OphidiaBigData/ophidia-server ;\
    git clone https://github.com/OphidiaBigData/ophidia-terminal

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
  && make && make install


WORKDIR /usr/local/ophidia/src/ophidia-terminal
COPY ophidia-terminal-cast.patch /usr/local/ophidia/src/ophidia-terminal/
RUN patch -p1 < ophidia-terminal-cast.patch \
  && ./bootstrap \
  && ./configure --prefix=/usr/local/ophidia/oph-terminal \
  && make && make install

ENTRYPOINT ["/bin/bash"]
