# Dockerfile: https://hub.docker.com/r/goacme/lego/
FROM goacme/lego:v5.4

# Define version argument and label
ARG VERSION
LABEL version="${VERSION}"

# Install necessary packages
RUN apk update && apk add --no-cache \
    # crond needs root, so install dcron and cap package and set the capabilities 
    # on dcron binary https://github.com/inter169/systs/blob/master/alpine/crond/README.md
    dcron libcap \
    openssh-client

# Add non-root user and run container as non-root
RUN addgroup -S lego && adduser -S lego -s /bin/sh -D -u 1000 -G lego

# Fix crond to run as non-root
# https://stackoverflow.com/a/63110882/11830912
RUN chown lego:lego /usr/sbin/crond && \
    setcap cap_setgid=ep /usr/sbin/crond

# Give execution rights on the cron job and apply cron job
COPY assets/cronjob /var/spool/cron/crontabs/lego
RUN chown -R lego:lego /var/spool/cron/crontabs/lego && chmod -R 640 /var/spool/cron/crontabs/lego

COPY assets/ /app/
RUN chmod +x /app/*.sh; \
    mkdir -p /letsencrypt /ssh; \
    chmod -R 550 /letsencrypt /app; \
    chown -R lego:lego /letsencrypt /app /ssh

# This is the only signal from the docker host that appears to stop crond
STOPSIGNAL SIGKILL

# switch user and set entrypoint 
USER lego
ENTRYPOINT ["/app/entrypoint.sh"]