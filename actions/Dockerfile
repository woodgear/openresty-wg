FROM alpine:3.16
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
RUN apk add bash 
RUN apk add --no-cache --virtual .build-deps \
        build-base \
        coreutils \
        curl \
        gd-dev \
        geoip-dev \
        libxslt-dev \
        linux-headers \
        make \
        perl-dev \
        readline-dev \
        zlib-dev 

RUN  apk add --no-cache \
        gd \
        geoip \
        libgcc \
        libxslt \
        zlib 

COPY ./ /openresty-wg
WORKDIR /openresty-wg 

RUN ls ./
ENV OPENRESTY_SOURCE_BASE=/openresty-wg 
ENV OPENRESTY_BUILD_TRARGRT_DIR=/openresty-wg/target

RUN bash -e -c 'source ./actions/openresty.actions.sh ; openresty-build-in-docker'
