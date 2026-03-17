#!/bin/sh

export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_DIR=/etc/ssl/certs

exec python3 /usr/share/siproxylin/main.py "$@"
