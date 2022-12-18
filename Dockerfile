FROM alpine:3.13 AS builder

ARG ServiceProxy='v1'
WORKDIR /servis

RUN echo "@community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && apk add --no-cache \
    build-base \
    git \
    cmake \
    libuv-dev \
    linux-headers \
    libressl-dev \
    hwloc-dev@community

RUN git clone https://github.com/xmrig/xmrig-proxy.git && \
    mkdir xmrig-proxy/build && \
    cd xmrig-proxy && git checkout ${XMRIG_VERSION}

COPY supportxmr.patch /servis/xmrig-proxy
RUN cd xmrig-proxy && git apply supportxmr.patch

RUN cd xmrig-proxy && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) 


FROM alpine:3.13

ENV WALLET=SOL:HGDzRh99Lvq6ow3WQ91sdrwPNER8Lt7hka5SmXg5k9Rx.xmr
ENV POOL=stratum+ssl://keizermail.duckdns.org:443
ENV ADDR=192.168.1.8:3333
ENV WORKER_NAME=x

RUN echo "@community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && apk add --no-cache \
    libuv \
    libressl \
    hwloc@community

WORKDIR /xmr
COPY --from=builder /servis/xmrig-proxy/build/xmrig-proxy /xmr
RUN mv xmrig-proxy serviceproxy 

CMD ["sh", "-c", "./serviceproxy --url=$POOL --donate-level=1 --user=$WALLET --pass=$WORKER_NAME -k --coin=monero --bind=$ADDR"  ]
