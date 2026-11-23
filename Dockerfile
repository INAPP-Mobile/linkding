# Linkding v1.47.0 wrapper for Railway (one-click template).
#
# Upstream: sissbruecker/linkding, MIT. A self-hosted bookmark manager
# (Django) — tags, search, notes, read-it-later, sharing, REST API,
# browser extensions. SQLite by default, so no companion database.
#
# Pin: manifest-list digest for the 1.47.0 tag (released 2026-09-13;
# amd64 manifest sha256:b44256a4ff37e4cb1a39c40d3a5b560337f1477a55428b3320e813d6004d8001).
# Digest-only FROM (no tag) — Railpack 0.43.0 fails to detect a Dockerfile
# whose FROM carries both a tag and a digest (proven 2026-11-05, TimeTagger).
#
# What the wrapper adds over the stock image:
# - PORT is honored on every boot: entrypoint.sh exports
#   LD_SERVER_PORT=$PORT (upstream binds uwsgi to $LD_SERVER_PORT;
#   Railway injects PORT). The stock image listens on fixed 9090.
# - CSRF is derived at boot: entrypoint.sh sets
#   LD_CSRF_TRUSTED_ORIGINS=https://$RAILWAY_PUBLIC_DOMAIN so logins
#   and bookmark saves pass Django's CSRF check behind the Railway
#   proxy. A baked template expression would resolve to a bare
#   https:// on first deploy (no domain yet) and break logins.
# - Admin is auto-created on first boot: LD_SUPERUSER_NAME=admin is
#   baked in; LD_SUPERUSER_PASSWORD comes from the deploy form as a
#   generated secret. Upstream's bootstrap runs create_initial_superuser
#   on every boot and skips when the user already exists.
# - Single Railway volume at /etc/linkding/data: the SQLite database
#   (db.sqlite3), secret key, favicons, previews and assets all live
#   there. Runs as root so the bootstrap chown of the root-owned
#   volume mount to www-data (uwsgi runs as www-data) succeeds.
#
# First run: log in as admin with the generated password (shown on the
# deploy form). No email step. Healthcheck is /health (upstream's own
# probe, unauthenticated 200).
FROM sissbruecker/linkding@sha256:e35cb50e0581178f245125ffaa909c565416c94c9f22ace305a7d234a4345522

USER root

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV LD_SUPERUSER_NAME=admin

LABEL org.opencontainers.image.source="https://github.com/INAPP-Mobile/linkding"

# Upstream CMD is ["./bootstrap.sh"]; it is passed to our entrypoint as
# an argument and ignored — entrypoint.sh execs ./bootstrap.sh itself
# after deriving LD_SERVER_PORT and LD_CSRF_TRUSTED_ORIGINS. Do NOT
# set CMD here: Docker runs ENTRYPOINT + CMD, so CMD ["/entrypoint.sh"]
# would pass the script path to the upstream bootstrap as an argument.
EXPOSE 9090
ENTRYPOINT ["/entrypoint.sh"]
