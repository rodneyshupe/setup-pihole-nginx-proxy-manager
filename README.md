# Install Nginx Proxy Manager on Pi-hole server

This script will install a docker container for [Nginx Proxy Manager](https://nginxproxymanager.com/) on the same server you are running Pi-hole.

## Install

To execute this script you can either [download](https://raw.githubusercontent.com/rodneyshupe/setup-pihole-nginx-proxy-manager/main/setup.sh) and execute the script. or just execute the following:

```sh
curl https://raw.githubusercontent.com/rodneyshupe/setup-pihole-nginx-proxy-manager/main/setup.sh | bash
```

### Notes

* This implementation uses `docker-compose` so if it is not installed when you run the script it will prompt you to install it first, then reboot.  Once that is complete you will need to execute the script again.
* As Nginx Proxy Manager needs to run on port 80/443 this will conflict with Pi-hole's admin interface.  To get around that you need to move it to another port.  If this has not already been done the script will prompt for the new port and then move on to the installation.
