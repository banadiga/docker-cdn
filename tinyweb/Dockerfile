FROM alpine:latest
MAINTAINER Bruno Simoes <brunogsimoes@gmail.com>

RUN apk add --update netcat-openbsd && rm -rf /var/cache/apk/*

EXPOSE 80

CMD while true; do ( echo "HTTP/1.0 200 Ok"; echo; echo `hostname` ) | nc -l 80; done
