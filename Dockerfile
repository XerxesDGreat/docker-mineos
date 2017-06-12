FROM openjdk:8
MAINTAINER Yuji ODA

# Installing Dependencies
RUN apt-get update && \
    apt-get install -y curl && \
    curl -sL https://deb.nodesource.com/setup_4.x | bash - && \
    apt-get -y install nodejs && \
    apt-get -y install supervisor rdiff-backup screen git build-essential ca-certificates-java

# Installing MineOS scripts
RUN mkdir -p /usr/games /var/games/minecraft; \
    git clone git://github.com/hexparrot/mineos-node.git /usr/games/minecraft; \
    cd /usr/games/minecraft; \
    git config core.filemode false; \
    chmod +x service.js mineos_console.js generate-sslcert.sh webui.js; \
    npm install; \
    ln -s /usr/games/minecraft/mineos_console.js /usr/local/bin/mineos

# Customize server settings
RUN sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' /etc/supervisor/supervisord.conf
ADD mineos.conf /usr/games/minecraft/mineos.conf
ADD supervisor_conf.d/mineos.conf /etc/supervisor/conf.d/mineos.conf
ADD supervisor_conf.d/sshd.conf /etc/supervisor/conf.d/sshd.conf
RUN mkdir /var/games/minecraft/ssl_certs; \
    mkdir /var/games/minecraft/log; \
    mkdir /var/games/minecraft/run; \
    mkdir /var/run/sshd

# Add start script
ADD start.sh /usr/games/minecraft/start.sh
RUN chmod +x /usr/games/minecraft/start.sh

# Add minecraft user and change owner files.
RUN useradd -s /bin/bash -d /usr/games/minecraft -m minecraft; \
    usermod -G sudo minecraft; \
    sed -i 's/%sudo.*/%sudo   ALL=(ALL:ALL) NOPASSWD:ALL/' /etc/sudoers; \
    chown -R minecraft:minecraft /usr/games/minecraft /var/games/minecraft

# Cleaning
RUN apt-get clean

VOLUME /var/games/minecraft
WORKDIR /usr/games/minecraft
EXPOSE 22 8443 25565

ENTRYPOINT ["./start.sh"]
