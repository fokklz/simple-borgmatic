FROM ghcr.io/borgmatic-collective/borgmatic

LABEL maintainer='fokklz'

RUN apk add --no-cache rclone 

ENV BORG_STORAGE_TYPE="b2"
ENV BORG_REMOTE_PATH=""
ENV BORG_B2_ACCOUNT=""
ENV BORG_B2_KEY=""

ENV DOCKERCLI="true"
ENV STOP_BEFORE_BACKUP=""
# ENV BEFORE_EVERYTHING=""
# ENV BEFORE_BACKUP=""
# ENV AFTER_BACKUP=""
# ENV AFTER_EVERYTHING=""

COPY ./scripts/ /scripts/
COPY ./entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh /scripts/*.sh

ENTRYPOINT ["/entrypoint.sh"]