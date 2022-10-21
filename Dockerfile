# syntax = docker/dockerfile:experimental
# https://github.com/RookieZoe/docker-images
FROM  nginx:1.22.1-alpine AS builder

ARG NGINX_VERSION=1.22.1
ARG HEADERS_MORE_VERSION=0.34
ARG NGINX_SOURCE=package/nginx-1.22.1.tar.gz

ARG HEADERS_MORE_SOURCE=package/headers-more-nginx-module-0.34.tar.gz

ENV NGINX_PATH=/usr/src/nginx
ENV HEADERS_MORE_PATH=/usr/src/headers-more-nginx-module
ENV NGINX_VERSION=$NGINX_VERSION
ENV HEADERS_MORE_VERSION=$HEADERS_MORE_VERSION
ENV NGINX_COMPRESS_NAME=nginx-1.22.1.tar.gz
ENV HEADERS_MORE_COMPRESS_NAME=headers-more-nginx-module-0.34.tar.gz

COPY $NGINX_SOURCE $NGINX_PATH/$NGINX_COMPRESS_NAME
COPY $HEADERS_MORE_SOURCE $HEADERS_MORE_PATH/$HEADERS_MORE_COMPRESS_NAME

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
  CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') && \
  CONFARGS=${CONFARGS/-Os -fomit-frame-pointer -g/-Os} && \
  cd $NGINX_PATH && \
  CFLAGS=${CFLAGS:-} && \
  CFLAGS="$CFLAGS -Wno-error" ./configure \
  --with-compat $CONFARGS \
  --add-dynamic-module=$HEADERS_MORE_PATH && \
  make && make install

FROM  nginx:1.22.1-alpine
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
