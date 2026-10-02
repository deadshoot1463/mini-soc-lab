#!/bin/bash
# Attendre que MariaDB soit prêt
sleep 5

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS dvwa;
CREATE USER IF NOT EXISTS 'dvwa'@'localhost' IDENTIFIED BY 'dvwa';
GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwa'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "[init-db] Base de données DVWA initialisée."
