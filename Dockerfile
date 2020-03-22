FROM debian:latest


# Install System packages
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install openssh-server vsftpd sudo
ADD set_root_pw.sh /set_root_pw.sh
ADD run.sh /run.sh
RUN chmod +x /*.sh
RUN mkdir -p /var/run/sshd \
  && sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config \
  && sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && touch /root/.Xauthority \
  && true

## Set a default user. Available via runtime flag `--user docker`
## Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
## User should also have & own a home directory, but also be able to sudo
RUN useradd docker \
        && passwd -d docker \
        && mkdir /home/docker \
        && chown docker:docker /home/docker \
        && addgroup docker staff \
        && addgroup docker sudo \
        && true

EXPOSE 22

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -yq git wget
# Get Go language
RUN \
  cd /tmp && \
  wget -nv https://dl.google.com/go/go1.14.1.linux-amd64.tar.gz && \
  tar -xvf go1.14.1.linux-amd64.tar.gz && \
  mv go /usr/local
# Add Variables to ./profile
RUN echo 'export GOROOT=/usr/local/go' >> ~/.profile
RUN echo 'export GOPATH=$HOME/go'  >> ~/.profile
RUN echo 'export GOBIN=$GOPATH/bin' >> ~/.profile
RUN echo 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH'  >> ~/.profile
# Current env Variables 
ENV GOROOT=/usr/local/go
ENV GOPATH=$HOME/go
ENV GOBIN=$GOPATH/bin
ENV PATH=$GOPATH/bin:$GOROOT/bin:$PATH
# Get Packages
RUN go version
RUN go get -u google.golang.org/grpc
RUN go get -u github.com/golang/protobuf/protoc-gen-go
RUN go get -u github.com/go-delve/delve/cmd/dlv
RUN go get -u github.com/stretchr/testify
RUN go get -u go.mongodb.org/mongo-driver/mongo
RUN go get -u github.com/go-sql-driver/mysql
RUN go get -u github.com/gorilla/mux

# Install Editors
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -yq spell nano vim

# Install C compiler and Tools

RUN apt-get update && DEBIAN_FRONTEND=noninteractive \
    apt-get install -yq build-essential manpages-dev man-db libx11-dev \
	gcc libyaml-dev whois libjson-c-dev valgrind automake libtool \
	libyaml-doc gettext binutils-doc gawk mawk pkg-config \
	autoconf curl make g++ unzip zip apt-utils libboost-all-dev \
	libpthread-stubs0-dev libgflags-dev libc++-dev

# Install Cmake

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -yq cmake

# # Python 2.0 and 3
 
RUN apt-get update && DEBIAN_FRONTEND=noninteractive \
    apt-get install -yq python3 python3-pip python python-pip

# XGboost 
RUN \
	cd /tmp \
    && git clone --recursive https://github.com/dmlc/xgboost \
    && cd xgboost \
    && mkdir build \
    && cd build \
    && cmake .. \
	&& make -j$(nproc) \
	&& make install
	
RUN pip3 install xgboost

# Protocol Buffers C++ 
# oficial Protobuffer Generator from Google
# This is the slowest Progrma to compile
RUN \
	cd /tmp	\
    && wget -nv https://github.com/protocolbuffers/protobuf/releases/download/v3.11.4/protobuf-cpp-3.11.4.tar.gz \
    && tar -xvf protobuf-cpp-3.11.4.tar.gz \
    && cd protobuf-3.11.4 \
    && ./configure \
    && make  \
    && make check  \
    && make install \
    && ldconfig


# C version
# This is protobuf-c, a C implementation
RUN \
    cd /tmp \
    && git clone --recursive https://github.com/protobuf-c/protobuf-c.git \
    && cd protobuf-c \
    && ./autogen.sh \
    && ./configure \ 
    && make  \ 
    && make check \ 
    && make install \
	&& ldconfig

# Perl updates

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -yq libtask-kensho-all-perl

RUN cpan -i App::cpanminus
RUN cpanm -i CPAN
RUN cpanm -i Log::Log4perl
RUN cpanm -i Text::Levenshtein
RUN cpanm -i Text::Levenshtein::XS 
RUN cpanm -i Text::Levenshtein::Damerau::PP
RUN cpanm -i Text::Levenshtein::Damerau::XS
#RUN cpanm -i Task::Kensho
RUN cpanm -i YAML::XS
RUN cpanm -i JSON::XS
RUN cpanm -i JSON
RUN cpanm -i Params::ValidationCompiler
RUN cpanm -i Moo
RUN cpanm -i Moose
RUN cpanm -i Getopt::Long::Descriptive
RUN cpanm -i Data::Format::Pretty::Console 
RUN cpanm -i Types::Standard
RUN cpanm -i Carp::Always
RUN cpanm -i Deep::Hash::Utils
RUN cpanm -i Modern::Perl


# Cleanning up

RUN \
	cd /tmp \
	&& rm -R * \
	&& cd ~ \
	&& rm -R .cpanm 

RUN apt-get clean

CMD ["/run.sh"]