#!/bin/sh
# Linkding wrapper entrypoint for Railway.
#
# - Maps Railway's injected PORT onto LD_SERVER_PORT, which upstream's
#   bootstrap.sh uses for the uwsgi bind (default 9090).
# - Derives LD_CSRF_TRUSTED_ORIGINS from the live public domain so
#   logins and bookmark saves pass Django's CSRF check behind the
#   Railway proxy. Only set when the deployer has not set one already,
#   and only when a public domain exists yet.
set -eu

export LD_SERVER_PORT="${PORT:-9090}"

if [ -z "${LD_CSRF_TRUSTED_ORIGINS:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  export LD_CSRF_TRUSTED_ORIGINS="https://${RAILWAY_PUBLIC_DOMAIN}"
fi

exec ./bootstrap.sh
