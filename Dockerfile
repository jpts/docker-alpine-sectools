FROM golang:alpine AS builder

RUN apk add --no-cache git musl-dev curl upx 
RUN go get -ldflags='-s -w' github.com/genuinetools/amicontained \
 && go get -ldflags='-s -w' github.com/genuinetools/reg 

RUN curl -sL "https://storage.googleapis.com/kubernetes-release/release/v1.17.3/bin/linux/amd64/kubectl" -o /tmp/kubectl && chmod +x /tmp/kubectl

RUN upx -f -o /amicontained /go/bin/amicontained \
 && upx -f -o /reg /go/bin/reg \
 && upx -f -o /kubectl /tmp/kubectl

FROM alpine:latest

COPY --from=builder /amicontained /usr/bin/amicontained
COPY --from=builder /reg /usr/bin/reg
COPY --from=builder /kubectl /usr/bin/kubectl

RUN apk add --no-cache jq curl bind-tools docker-cli skopeo openssh-client nmap nmap-ncat

CMD ["ash"]
