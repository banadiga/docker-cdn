FROM alpine:3.2
RUN apk add --update nginx && rm -rf /var/cache/apk/*
RUN mkdir -p /tmp/nginx/client-body

COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/default.conf /etc/nginx/conf.d/default.conf
COPY website /usr/share/nginx/html

CMD ["nginx", "-g", "daemon off;"]
