FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive

# Miroir HTTPS cassé (kalimirror.velden.media) → force un miroir HTTP stable
# + désactive la vérif SSL apt (lab uniquement) au cas où un redirect HTTPS reste.
RUN set -eux; \
    rm -f /etc/apt/sources.list /etc/apt/sources.list.d/*; \
    printf '%s\n' \
      'Types: deb' \
      'URIs: http://kali.download/kali' \
      'Suites: kali-rolling' \
      'Components: main contrib non-free non-free-firmware' \
      'Signed-By: /usr/share/keyrings/kali-archive-keyring.gpg' \
      > /etc/apt/sources.list.d/kali.sources; \
    printf '%s\n' \
      'Acquire::Retries "5";' \
      'Acquire::http::Timeout "60";' \
      'Acquire::https::Timeout "60";' \
      'Acquire::https::Verify-Peer "false";' \
      'Acquire::https::Verify-Host "false";' \
      > /etc/apt/apt.conf.d/99-lab-insecure-https

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    iputils-ping \
    net-tools \
    curl \
    wget \
    dnsutils \
    netcat-openbsd \
    tcpdump \
    gobuster \
    dirb \
    nikto \
    hydra \
    nmap \
    dnsrecon \
    python3 \
    ftp \
    lftp \
    wordlists \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN gunzip -f /usr/share/wordlists/rockyou.txt.gz 2>/dev/null || true

COPY dns-flood.sh /usr/local/bin/dns-flood.sh
COPY siem-tests.sh /usr/local/bin/siem-tests.sh
RUN chmod +x /usr/local/bin/dns-flood.sh /usr/local/bin/siem-tests.sh

WORKDIR /root
ENV VICTIME_IP=10.30.10.20
CMD ["/bin/bash"]
