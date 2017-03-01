FROM ubuntu:trusty

EXPOSE 80

CMD while true; do ( echo "HTTP/1.0 200 Ok"; echo; echo `hostname` ; echo "(pong)" ) | nc -l 80; done
