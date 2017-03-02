FROM alpine:latest
MAINTAINER Bruno Simoes <brunogsimoes@gmail.com>

RUN apk add --update nginx

# Clean up APT when done
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /tmp/nginx/client-body

COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/default.conf /etc/nginx/conf.d/default.conf
COPY website /usr/share/nginx/html

CMD ["nginx", "-g", "daemon off;"]
