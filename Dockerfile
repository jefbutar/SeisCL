FROM nvidia/cuda:9.2-devel-centos7
MAINTAINER Gabriel Fabien-Ouellet <gabriel.fabien-ouellet@polymtl.ca>

RUN yum -y install epel-release
RUN yum-config-manager --enable epel 
RUN yum -y install hdf5-devel \
    && yum -y install make \
    && yum -y install git 
ENV CUDA_PATH /usr/local/cuda

RUN mkdir SeisCL
COPY src SeisCL
RUN cd SeisCL \
    && make all api=cuda nompi=1 H5CC=gcc

ENV PATH="/SeisCL:${PATH}"