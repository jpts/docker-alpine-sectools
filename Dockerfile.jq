FROM golang:alpine AS builder

RUN apk add --no-cache git musl-dev curl upx gcc
RUN go get -ldflags='-s -w' -race github.com/genuinetools/amicontained \
 && go get -ldflags='-s -w' github.com/genuinetools/reg

RUN VER=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt) \
 && curl -sL "https://storage.googleapis.com/kubernetes-release/release/$VER/bin/linux/amd64/kubectl" -o kubectl \
 && chmod +x kubectl

WORKDIR /bins

ENV UPX "-1 -qq"

RUN upx -o amicontained /go/bin/amicontained \
 && upx -o reg /go/bin/reg \
 && upx -o kubectl /go/kubectl \
 && upx -o oc /go/oc

FROM alpine:latest

RUN mkdir /tools
COPY --from=builder /bins/* /usr/bin/

RUN apk add --no-cache \
    libc6-compat file iproute2 \
    curl bind-tools tcpdump socat \
    docker-cli skopeo \
    openssh-client openssl nmap nmap-ncat

RUN apk add --no-cache jq \
 && mv /usr/bin/jq /usr/bin/jqj

CMD ["ash"]
