# CDN with HAProxy, Consul and Nginx

This project contains scripts to automatically deploy a cdn that serves content with nginx. 

# HAProxy with Consul

Consul provides both a DNS and HTTP interface for doing service discovery. Using consul-haproxy allows applications to route to a local HAProxy instance which can perform the rich routing and load balancing. The load balancer is reconfigured automatically anytime the underlying service changes ensuring an up-to-date configuration.

### Installation

This script requires virtualbox and docker-machine to be pre-installed.

First, we have to create a virtual machine where we will deploy the CDN. In the example, we create a virtual machine called `cdn`. You can use a different name for the VM or skip the commands if you already have one.

```sh
make create-vm VM_NAME=cdn
```

Once done, we have to connect our Docker Client to the Docker Engine running on this virtual machine. Please change the token `cdn` with the name of your virtual machine.

```sh
eval $(docker-machine env cdn)
```

To install and configure HAProxy, Registrator and Consul type (do not change cdn with the name of your machine):

```sh
make cdn
```

Once done, you will find the admin URLs (HAProxy and Consul) in your terminal. The default user:password is admin:password. 

### Setup a demo

You can verify the deployment by installing two demo webservers. But first, we have to connect our Docker Client to the Docker Engine running on this virtual machine (in case you missed the previous steps). Please change the token `cdn` with the name of your virtual machine.

```sh
eval $(docker-machine env cdn)
```

After you can execute:

```sh
make demo
```

Once executed, you will find the entry point URL in your terminal. If you refresh the URL you will see that content changes reflecting the name of the webserver that handled the request.

### Setup a nginx node

Now we create a minimalist Nginx server based on Alpine linux (6 MB). But first, we have to connect our Docker Client to the Docker Engine running on this virtual machine (in case you missed the previous steps). Please change the token `cdn` with the name of your virtual machine.

```sh
eval $(docker-machine env cdn)
```

Add the content to be server by nginx to the folder `nginx/website` and add a new nginx server to the CDN. Replace the `web` with the url path prefix for the group of servers serving the website and `demo` with the name for the nginx container (keep it unique).


```sh
make webserver ENTRYPOINT=web SERVERNAME=demo 
```

You can access your website using the following URL pattern http://machine-ip/web. Repeat the same step with different SERVERNAME params to create more nodes.