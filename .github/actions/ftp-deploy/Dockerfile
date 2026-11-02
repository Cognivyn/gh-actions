FROM alpine:3.21

LABEL org.opencontainers.image.authors="S Saha"
LABEL org.opencontainers.image.source="https://github.com/Cognivyn/gh-actions"
LABEL org.opencontainers.image.description="FTP Deploy Action Container"

RUN apk add --no-cache \
    lftp \
    ca-certificates \
    bash

COPY --chmod=755 src/main.sh /usr/local/bin/ftp-deploy

ENTRYPOINT ["ftp-deploy"]
