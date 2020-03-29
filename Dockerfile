FROM golang:alpine AS builder

RUN apk add --no-cache git musl-dev curl upx 
RUN go get -ldflags='-s -w' github.com/genuinetools/amicontained \
 && go get -ldflags='-s -w' github.com/genuinetools/reg \
 && go get -ldflags='-s -w' github.com/etcd-io/etcd/etcdctl 

RUN VER=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt) \
 && curl -sL "https://storage.googleapis.com/kubernetes-release/release/$VER/bin/linux/amd64/kubectl" -o kubectl \
 && chmod +x kubectl

RUN curl -sL "https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz" | tar xzf - \
 && chmod +x oc

ENV UPX "-f --brute -qq"

RUN upx -o /amicontained /go/bin/amicontained \
 && upx -o /reg /go/bin/reg \
 && upx -o /etcdctl /go/bin/etcdctl \
 && upx -o /kubectl /go/kubectl \
 && upx -o /oc /go/oc

FROM alpine:latest

COPY --from=builder /amicontained /usr/bin/amicontained
COPY --from=builder /reg /usr/bin/reg
COPY --from=builder /etcdctl /usr/bin/etcdctl
COPY --from=builder /kubectl /usr/bin/kubectl
COPY --from=builder /oc /usr/bin/oc

RUN apk add --no-cache jq curl bind-tools docker-cli skopeo openssh-client nmap nmap-ncat

CMD ["ash"]
