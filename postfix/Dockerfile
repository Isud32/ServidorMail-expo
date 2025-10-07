FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y postfix procps mailutils && apt-get clean
# minimal postfix config will be provided at runtime (copy main.cf)
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
VOLUME ["/data/mail_in"]
EXPOSE 25
CMD ["/usr/local/bin/docker-entrypoint.sh"]








