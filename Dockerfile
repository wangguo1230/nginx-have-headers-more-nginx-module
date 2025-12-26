# syntax = docker/dockerfile:experimental
# https://github.com/RookieZoe/docker-images
FROM  --platform=$TARGETPLATFORM nginx:1.28.1-alpine AS builder

ARG NGINX_VERSION=1.28.1
ARG HEADERS_MORE_VERSION=0.39

ENV NGINX_PATH=/usr/src/nginx
ENV HEADERS_MORE_PATH=/usr/src/headers-more-nginx-module
ENV NGINX_VERSION=$NGINX_VERSION
ENV HEADERS_MORE_VERSION=$HEADERS_MORE_VERSION
ENV NGINX_COMPRESS_NAME=nginx-${NGINX_VERSION}.tar.gz
ENV HEADERS_MORE_COMPRESS_NAME=headers-more-nginx-module-${HEADERS_MORE_VERSION}.tar.gz

# 创建源码目录
RUN mkdir -p $NGINX_PATH $HEADERS_MORE_PATH

# 下载 nginx 和 headers-more-nginx-module 源码
RUN wget -O $NGINX_PATH/$NGINX_COMPRESS_NAME https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    wget -O $HEADERS_MORE_PATH/$HEADERS_MORE_COMPRESS_NAME https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERS_MORE_VERSION}.tar.gz
ARG http_proxy
ARG https_proxy
ARG no_proxy

ENV http_proxy=$http_proxy \
    https_proxy=$https_proxy \
    no_proxy=$no_proxy
# For latest build deps, see https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine/Dockerfile
RUN apk add --no-cache --virtual .build-deps \
  gcc \
  libc-dev \
  make \
  openssl-dev \
  pcre2-dev \
  zlib-dev \
  linux-headers \
  libxslt-dev \
  gd-dev \
  geoip-dev \
  perl-dev \
  libedit-dev \
  bash \
  alpine-sdk \
  findutils

# Reuse same cli arguments as the nginx:stable-alpine image used to build
RUN tar -xzf $NGINX_PATH/$NGINX_COMPRESS_NAME --strip-components 1 -C $NGINX_PATH && \
  tar -xzf $HEADERS_MORE_PATH/${HEADERS_MORE_COMPRESS_NAME} --strip-components 1 -C $HEADERS_MORE_PATH && \
  rm $NGINX_PATH/$NGINX_COMPRESS_NAME $HEADERS_MORE_PATH/$HEADERS_MORE_COMPRESS_NAME && \
  CONFARGS="$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p')" && \
  CONFARGS="${CONFARGS/-Os -fomit-frame-pointer -g/-Os}" && \
  cd "$NGINX_PATH" && \
  CFLAGS="${CFLAGS:-} -Wno-error" && \
  eval "./configure --with-compat $CONFARGS --add-dynamic-module=$HEADERS_MORE_PATH" && \
  make && make install

FROM --platform=$TARGETPLATFORM  nginx:1.28.1-alpine
ARG NGINX_VERSION
ARG HEADERS_MORE_VERSION
ENV NGINX_VERSION=$NGINX_VERSION
ENV HEADERS_MORE_VERSION=$HEADERS_MORE_VERSION
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /usr/lib/nginx /usr/lib/nginx
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx

EXPOSE 80
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]
