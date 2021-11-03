FROM ubuntu:18.04
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
        dirmngr \
        software-properties-common \
        wget && \
    wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc && \
    add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        gfortran \
        liblapack-dev \
        libblas-dev \
        libcairo2-dev \
        libcurl4-openssl-dev \
        libfontconfig1-dev \
        libssl-dev \
        libv8-dev \
        libxml2-dev \
        r-base

RUN apt-get install -y --no-install-recommends locales && \
        echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
        locale-gen en_US.utf8 && \
        /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN Rscript -e 'install.packages(c("jsonvalidate", "testthat"))'
