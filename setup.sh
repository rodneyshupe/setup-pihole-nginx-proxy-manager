#!/usr/bin/env bash

function confirm() {
    local prompt="$1"
    read -p "$prompt [Y/n] " answer
    case "$answer" in
        Y|y|"")
            return 0;;
        N|n)
            echo "Exiting."
            exit 1;;
        *)
            echo "Invalid response."
            confirm "$prompt";;
    esac
}

function get_port() {
    local default_port=${1:-8000}
    local port
    while true; do
        read -p "Enter port new number [$default_port]: " port
        port=${port:-$default_port}
        if [[ "$port" =~ ^[0-9]+$ ]]; then
            if [ "$port" -eq 80 ] || [ "$port" -eq 81 ] || [ "$port" -eq 443 ]; then
                echo "Port 80, 81 and 443 are not allowed."
            else
                if lsof -i :"$port" >/dev/null 2>&1; then
                    echo "Port $port is in use. Please choose another port."
                else
                    echo "Selected port: $port"
                    read -p "Is this the correct port? [Y/n] " answer
                    case "$answer" in
                        Y|y|"")
                            break;;
                        N|n)
                            continue;;
                        *)
                            echo "Invalid response.";;
                    esac
                fi
            fi
        else
            echo "Invalid port number. Please enter a number."
        fi
    done
}

function install_docker() {
    sudo apt install -y docker.io docker-compose
    sudo systemctl start docker

    sudo groupadd docker
    sudo usermod -aG docker ${USER}

    sudo gpasswd -a pi docker
    sudo gpasswd -a $USER docker

    sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
    sudo chmod g+rwx "$HOME/.docker" -R

    echo "Need to relogin"
    su -s ${USER}

    #docker run hello-world
}

function change_lighttpd_config() {
    # Set port to use
    port=${1:-8000}

    config_file='/etc/lighttpd/external.conf'

    sudo service lighttpd stop

    # Change config file
    grep 'server.port := ' $config_file >/dev/null \
        && sudo sed -i -e "s/server.port :=.*$/server.port := $port/" $config_file \
        || { echo "server.port := $port" | sudo tee -a $config_file >/dev/null; }

    sudo service lighttpd start
}

function install_npm() {
    mkdir -p $HOME/.config/nginx-proxy-manager/data
    mkdir -p $HOME/.config/nginx-proxy-manager/letsencrypt

    cat >$HOME/.config/nginx-proxy-manager/docker-compose.yml <<EOF
version: "3"
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    container-name: nginx-proxy-manager
    restart: unless-stopped
    ports:
      # These ports are in format <host-port>:<container-port>
      - '80:80' # Public HTTP Port
      - '443:443' # Public HTTPS Port
      - '81:81' # Admin Web Port
      # Add any other Stream port you want to expose
      # - '21:21' # FTP

    # Uncomment the next line if you uncomment anything in the section
    # environment:
      # Uncomment this if you want to change the location of 
      # the SQLite DB file within the container
      # DB_SQLITE_FILE: "/data/database.sqlite"

      # Uncomment this if IPv6 is not enabled on your host
      # DISABLE_IPV6: 'true'

    volumes:
      - $HOME/.config/nginx-proxy-manager/data:/data
      - $HOME/.config/nginx-proxy-manager/letsencrypt:/etc/letsencrypt
EOF

    docker-compose -f $HOME/.config/nginx-proxy-manager/docker-compose.yml up -d
}


if ! $(docker-compose -v >/dev/null 2>&1) ; then
    echo "Docker needs to be installed."
    echo ""
    confirm "Do you want to continue?"
    install_docker
    echo ""
    confirm "Reboot required. Do you want to continue?"
    sudo shutdown --reboot now
else
    echo "Pi-hole interface needs to be moved to a port other than the default of 80."

    port=$(get_port)
    echo

    echo "About to move Pi-Hole administration to port $port"
    confirm "Do you want to continue?"

    change_lighttpd_config $port
    echo

    echo "About to install the container for Nginx Proxy Manager"
    confirm "Do you want to continue?"
    install_npm
fi
