FROM ubuntu:18.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install \
        r-base \
        libcurl4-openssl-dev \
        libv8-dev && \
        Rscript -e 'install.packages(c("jsonvalidate", "testthat"))'
