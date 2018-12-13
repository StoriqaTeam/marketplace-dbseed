FROM debian:stable-slim

RUN apt-get update \
  && apt-get install -y curl gnupg2 ca-certificates apt-transport-https \
  && curl -s https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" >> /etc/apt/sources.list.d/pgdg.list \
  && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
  && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list \
  && apt-get update \
  && apt-get install -y postgresql-client-10 kubectl \
  && apt-get purge -y wget \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/ \
  && mkdir /root/dump

COPY conf /root/conf
COPY sql /root/sql
COPY dbseed.sh /root/dbseed.sh

WORKDIR /root

ENTRYPOINT /root/dbseed.sh sync
