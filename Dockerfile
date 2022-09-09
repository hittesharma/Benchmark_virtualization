# FROM gcc:9.2.0 as compiler
# 
# COPY forksum.c /forksum.c
# RUN gcc -o forksum forksum.c
# 
FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive
RUN set -eux && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        bc \
        sysbench \
        iperf3 && \
    apt-get install -y \
        make \
        gcc && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/lib/cc

COPY --chown=root:root benchmark.sh /var/lib/cc/benchmark.sh
# Why need the uncompiled file for the benchmark.sh!
# The design is really broke here!
COPY --chown=root:root forksum.c /var/lib/cc/forksum.c
# COPY --chown=root:root --from=compiler /forksum /var/lib/cc/forksum

WORKDIR /var/lib/cc/
CMD [ "/var/lib/cc/benchmark.sh" ]