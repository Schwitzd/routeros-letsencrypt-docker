# Let's Encrypt for RouterOS Webserver/API

This Docker container automatically renews certificates from Let's Encrypt, copies them to a MikroTik device running RouterOS, and activates them in the web server, API and OpenVPN server.

There are two approaches:

1. Run the container directly in the MikroTik router (if the feature is available)
1. Run the container elsewhere

Docker Hub: [schwitzd/routeros-letsencrypt](https://hub.docker.com/r/schwitzd/routeros-letsencrypt)

## Getting Started

* Follow the [Mikortik documentation](https://help.mikrotik.com/docs/display/ROS/Container#Container-Containerconfiguration) to enable the container feature, in the repository [IaC-HomeRouter](https://github.com/Schwitzd/IaC-HomeRouter) I did it with Terraform
* Map a SSH private key file for login into RouterOS
* Map a volume/folder to store persistent authorization information between container restarts
* Configure environment variables to control the automation process

## Environment Variables

Name | Default | Description
--- | --- | ---
`ROUTEROS_USER` | _(none)_ | User with policies `ssh, write, ftp, read`
`ROUTEROS_HOST` | _(none)_ | RouterOS IP or Hostname
`ROUTEROS_SSH_PORT` | `22` | RouterOS SSH Port
`ROUTEROS_PRIVATE_KEY` | _(none)_ | Private Key file to connect to RouterOS (set permissions to 0400!)
`ROUTEROS_DOMAIN` | _(none)_ | Domainname for catch up certs from LEGO Client. Usually the **first** Domain you set in the LEGO_DOMAINS variable
`LEGO_STAGING` | `1` |  Whether to use production or staging LetsEncrypt endpoint. `0` for production, `1` for staging
`LEGO_KEY_TYPE` | `ec384` | Type of key
`LEGO_DOMAINS` | _(none)_ | Domains (delimited by ';' )
`LEGO_EMAIL_ADDRESS` | _(none)_ | Email used for registration and recovery contact.
`LEGO_PROVIDER` | _(none)_ | Valid values for DNS providers can be found in the official LEGO documentation: [https://go-acme.github.io/lego/dns/](https://go-acme.github.io/lego/dns/)
`LEGO_DNS_TIMEOUT` | `10` | Set the DNS timeout value to a specific value in seconds
`LEGO_ARGS` | _(none)_ | Send arguments directly to lego, e.g. `"--dns.disable-cp"` or `"--dns.resolvers 1.1.1.1"`
`<KEY/TOKEN_FROM_PROVIDER>` | _(none)_ | See [Configuration of DNS Providers](https://go-acme.github.io/lego/dns/)
`SET_ON_WEB` | true | Set the new certificate on the WebServer
`SET_ON_API` | true | Set the new certificate on the API
`SET_ON_OVPN` | false | Set the new certificate on the OpenVPN Server
`SET_ON_HOTSPOT` | false | Set the new certificate for the HotSpot/CaptivePortal
`SET_ON_REVERSE_PROXY` | false | Set the new certificate for the Reverse Proxy
`REVERSE_PROXY_DOMAINS` | _(none)_ | A comma-separated list of Reverse Proxy domains (SNI) to which the certificate will apply
`HOTSPOT_PROFILE_NAME`| _(none)_ | HotSpot/CaptivePortal profile name

## SSH Setup

* Generate SSH key pair
* Upload public key to RouterOS
* Add User/Group and import public SSH key
* Pass private key into the container store

## Example

### Within MikroTik

```sh
# Add environment variables
/container/envs/add name=lego_envs key=LEGO_STAGING value="0"
/container/envs/add name=lego_envs key=LEGO_PROVIDER value="cloudflare"
/container/envs/add name=lego_envs key=LEGO_DOMAINS value="mydomain.tld"
/container/envs/add name=lego_envs key=LEGO_EMAIL_ADDRESS value="admin@mydomain.tld"
/container/envs/add name=lego_envs key=CLOUDFLARE_DNS_API_TOKEN value="<TOKEN>"
/container/envs/add name=lego_envs key=ROUTEROS_USER value="letsencrypt"
/container/envs/add name=lego_envs key=ROUTEROS_HOST value="router.mydomain.tld"
/container/envs/add name=lego_envs key=ROUTEROS_PRIVATE_KEY value="/ssh/id_ed25519"
/container/envs/add name=lego_envs key=ROUTEROS_DOMAIN value="mydomain.tld"

# Create mount points
/container/mounts/add name=lego-ssh src=/usb1/containers/lego/ssh dst=/ssh
/container/mounts/add name=lego-letsencrypt src=/usb1/containers/lego/data dst=/letsencrypt

# Create container
/container/add remote-image=schwitzd/routeros-letsencrypt:latest interface=veth1 root-dir=usb1/containers/lego/root mounts=lego-ssh,lego-letsencrypt envlist=lego_envs dns=<dns_server> logging=yes start-on-boot=yes
```

### Docker Compose

```yml
services:
  app:
    image: foorschtbar/routeros-letsencrypt
    environment:
      - LEGO_STAGING=0
      - LEGO_PROVIDER=cloudflare
      - LEGO_DOMAINS=mydomain.tld   # or *.mydomain.tld for a wildcard cert.
      - LEGO_EMAIL_ADDRESS=admin@mydomain.tld
      - CLOUDFLARE_DNS_API_TOKEN=<TOKEN>
      - ROUTEROS_USER=letsencrypt
      - ROUTEROS_HOST=router.mydomain.tld
      - ROUTEROS_PRIVATE_KEY=/ssh/id_ed25519
      - ROUTEROS_DOMAIN=mydomain.tld # or *.mydomain.tld for a wildcard cert.
    volumes:
      - ./data:/letsencrypt # To store Let's Encrypt authorization
      - ./ssh/ssh           # To store RouterOS ssh private key
    restart: unless-stopped
```

TO DO: use docker compose secrets

## Credits

Inspired & forked from [routeros-letsencrypt-docker](https://github.com/foorschtbar/routeros-letsencrypt-docker)
