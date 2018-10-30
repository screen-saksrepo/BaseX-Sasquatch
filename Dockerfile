FROM basex/basexhttp:9.0.2
ADD repo /srv/basex/repo
ADD webapp /srv/basex/webapp
ADD utils /srv/basex/utils
ADD basex-config /srv/basex/.basex
USER root
RUN ["mkdir", "/home/basex-data"]
RUN ["chown","-R", "basex", "/srv", "/home/basex-data"]
USER basex
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s \
  CMD curl -f http://localhost:8984/ping || exit 1
CMD ["/usr/local/bin/basexhttp"]
