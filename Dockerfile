#FROM ubuntu:$UBUNTU_VERSION
FROM ubuntu:22.04

ARG DPDK_STUFF=dpdk-24.03.tar.xz
ARG DPDK_HOME=/dpdk

#ARG UPF_VERSION
ARG UPF_VPP_HOME=/oai-cn5g-upf-vpp

#ARG COLLECTD_VERSION
#ARG COLLECTD_STUFF=collectd-5.12.0.tar.bz2
#ARG COLLECTD_HOME=/collectd

RUN apt-get -qq update \
  && apt-get -qq install --no-install-recommends \
       build-essential \
       ca-certificates \
       libbsd-dev \
       libjansson-dev \
       libnuma-dev \
       libpcap-dev \
       libprotobuf-c-dev \
       libzstd1 \
       libzstd-dev \
       zstd \
       protobuf-c-compiler \
       autoconf \
       automake \
       flex \
       bison \
       vim-tiny \
       sudo \
       git \
       wget \
       libtool \
       make \
       python3-pip \
       python3-pyelftools \
       python3-scapy \
       python3-setuptools \
       xz-utils \
       pciutils \
       net-tools \
       pkgconf \
       libibverbs-dev \
       libmicrohttpd-dev \
       libcurl4-openssl-dev \
       unzip \
  && pip3 install \
       meson \
       ninja

# Copy patches to the container
COPY patches /patches
COPY pfcp /pfcp
COPY scripts /scripts
COPY config /config

RUN apt-get update && apt-get install -y git
ENV GIT_REPO=https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-upf-vpp.git
ENV GIT_TAG=develop
RUN git clone --branch ${GIT_TAG} --single-branch ${GIT_REPO} $UPF_VPP_HOME

RUN cd oai-cn5g-upf-vpp \
  && git checkout develop \
  && for patch in /patches/vpp/external/*.patch; do \
        cp $patch ./scripts/patches/; \ 
     done
ENV PKG_CONFIG_PATH=/usr/local/lib/x86_64-linux-gnu/pkgconfig

RUN cd $UPF_VPP_HOME \
  && for patch in /patches/oai/*.patch; do \
        patch -p1 < $patch; \
     done

# Apply dpdk / vpp custom patches 
RUN cd $UPF_VPP_HOME/scripts/patches \
  && mkdir -p vpp dpdk \
  && mv *.patch vpp/ \
  && cp /patches/dpdk/*.patch dpdk/

RUN cd $UPF_VPP_HOME/build/scripts \
  && ./build_vpp_upf -I -f

RUN cd $UPF_VPP_HOME/vpp \
  && for patch in /patches/vpp/*.patch; do \
        patch -p1 < $patch; \
     done

RUN cd $UPF_VPP_HOME/build/scripts \
  && ./build_vpp_upf -c -V

