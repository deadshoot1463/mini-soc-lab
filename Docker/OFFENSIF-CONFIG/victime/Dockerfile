FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

# ─── Dépendances système ───────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    apache2 \
    php \
    php-mysqli \
    php-gd \
    libapache2-mod-php \
    openssh-server \
    bind9 \
    bind9utils \
    vsftpd \
    mariadb-server \
    wget \
    curl \
    unzip \
    procps \
    net-tools \
    supervisor \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ─── SSH : root avec mot de passe faible (lab) ────────────────────────────────
RUN echo 'root:root' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    mkdir -p /var/run/sshd

# ─── HTTP : DVWA ──────────────────────────────────────────────────────────────
RUN wget -q https://github.com/digininja/DVWA/archive/refs/heads/master.zip -O /tmp/dvwa.zip && \
    unzip -q /tmp/dvwa.zip -d /tmp && \
    mv /tmp/DVWA-master /var/www/html/dvwa && \
    cp /var/www/html/dvwa/config/config.inc.php.dist /var/www/html/dvwa/config/config.inc.php && \
    chown -R www-data:www-data /var/www/html/dvwa && \
    rm /tmp/dvwa.zip

RUN sed -i "s/\$_DVWA\[ 'db_password' \] = 'p\@ssw0rd'/\$_DVWA[ 'db_password' ] = 'dvwa'/" \
        /var/www/html/dvwa/config/config.inc.php && \
    sed -i "s/\$_DVWA\[ 'db_user' \]     = 'dvwa'/\$_DVWA[ 'db_user' ]     = 'dvwa'/" \
        /var/www/html/dvwa/config/config.inc.php

# Répertoires pour énumération (gobuster / dirb)
RUN mkdir -p /var/www/html/admin \
             /var/www/html/backup \
             /var/www/html/secret \
             /var/www/html/.git && \
    printf '%s\n' '<!DOCTYPE html><html><head><title>Admin</title></head><body><h1>Raincourt Admin</h1><p>Panel interne — acces restreint.</p><a href="/dvwa/">Ouvrir DVWA</a></body></html>' \
      > /var/www/html/admin/index.html && \
    printf '%s\n' '<!DOCTYPE html><html><head><title>Backup</title></head><body><h1>Backups</h1><pre>db_dump_2024.sql\nusers.csv\nsecrets.env</pre></body></html>' \
      > /var/www/html/backup/index.html && \
    echo "SECRET_KEY=s3cr3t_raincourt_lab_2026" > /var/www/html/secret/config.txt && \
    echo "ref: refs/heads/main" > /var/www/html/.git/HEAD

RUN a2enmod rewrite && \
    (a2enmod php8.2 || a2enmod php8.1 || true) && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf

# ─── FTP : vsftpd accès anonyme ───────────────────────────────────────────────
COPY vsftpd.conf /etc/vsftpd.conf
RUN mkdir -p /var/ftp/pub && \
    echo "FLAG{ftp_anonymous_access}" > /var/ftp/pub/flag.txt && \
    echo "passwords_backup.txt: admin:admin123, user:password" > /var/ftp/pub/passwords_backup.txt && \
    chown -R ftp:ftp /var/ftp && \
    chmod 755 /var/ftp

# ─── DNS : Bind9 (zone victime.local) ─────────────────────────────────────────
COPY named.conf.local /etc/bind/named.conf.local
COPY db.victime.local /etc/bind/db.victime.local

# ─── MariaDB : init DVWA ──────────────────────────────────────────────────────
COPY init-db.sh /docker-entrypoint-initdb.d/init-db.sh
RUN chmod +x /docker-entrypoint-initdb.d/init-db.sh

# ─── Site vitrine SOC-RUN ─────────────────────────────────────────────────────
COPY index.html /var/www/html/index.html
RUN chown www-data:www-data /var/www/html/index.html

# ─── Supervisor ───────────────────────────────────────────────────────────────
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80 22 53/udp 53/tcp 21 40000-40100

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
