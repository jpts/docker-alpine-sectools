FROM golang:alpine AS builder

RUN apk add --no-cache git musl-dev
RUN go get -v -ldflags='-s -w' github.com/genuinetools/amicontained && go get -v -ldflags='-s -w' github.com/genuinetools/reg 

FROM alpine:latest

ENV KUBE_VERSION v1.17.0

COPY --from=builder /go/bin/amicontained /usr/bin/
COPY --from=builder /go/bin/reg /usr/bin/reg

RUN apk add --no-cache jq curl bind-tools docker-cli skopeo openssh-client nmap nmap-ncat

RUN curl -sL "https://storage.googleapis.com/kubernetes-release/release/$KUBE_VERSION/bin/linux/amd64/kubectl" -o /usr/bin/kubectl && chmod +x /usr/bin/kubectl

CMD ["ash"]
