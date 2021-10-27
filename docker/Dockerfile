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
        libcurl4-openssl-dev \
        libv8-dev \
        r-base

RUN Rscript -e 'install.packages(c("jsonvalidate", "testthat"))'
