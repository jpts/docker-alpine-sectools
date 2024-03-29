FROM golang:alpine as builder

RUN apk add --no-cache git musl-dev curl upx jq tar
RUN go get -ldflags='-s -w' github.com/fullstorydev/grpcurl/cmd/grpcurl \
 && GO111MODULE=on go get -ldflags='-s -w' github.com/jpbetz/auger

# go get -ldflags='-s -w' github.com/etcd-io/etcd/etcdctl \
# add kubeaudit
# add eksctl
# tkg
# rke cli
# conmachine
# bolt browser
# old kubectl
# krew plugins; rakess
# nse scripts
# https://github.com/cyberark/kubeletctl/releases/download/v1.8/kubeletctl_linux_amd64
#curl https://github.com/cyberark/kubeletctl/releases/download/v1.8/kubeletctl_linux_amd64 -L -o /usr/local/bin/kubeletctl
# proot

WORKDIR /github

RUN VER=$(curl -s https://api.github.com/repos/projectcalico/calicoctl/releases/latest | jq -r '.name') \
 && curl -sL "https://github.com/projectcalico/calicoctl/releases/download/$VER/calicoctl-linux-amd64" -o calicoctl \
 && chmod +x calicoctl

RUN URL=$(curl -s https://api.github.com/repos/istio/istio/releases/latest | jq -r '.assets[].browser_download_url | select(test("ctl.*x-amd64.tar.gz$"))') \
 && curl -sL "$URL" | tar xzf - \
 && chmod +x istioctl

RUN URL=$(curl -s https://api.github.com/repos/linkerd/linkerd2/releases/latest | jq -r '.assets[].browser_download_url | select(endswith("x-amd64"))') \
 && curl -sL "$URL" -o linkerd \
 && chmod +x linkerd

RUN VER=$(curl -s https://api.github.com/repos/helm/helm/releases | jq '.[].tag_name | select(startswith("v2"))' | jq -sr '.|first') \
 && curl -sL "https://get.helm.sh/helm-$VER-linux-amd64.tar.gz" | tar xzf - --strip-components=1 linux-amd64/helm \
 && chmod +x helm \
 && mv helm helm2

RUN VER=$(curl -s https://api.github.com/repos/helm/helm/releases | jq '.[].tag_name | select(startswith("v3"))' | jq -sr '.|first') \
 && curl -sL "https://get.helm.sh/helm-$VER-linux-amd64.tar.gz" | tar xzf - --strip-components=1 linux-amd64/helm \
 && chmod +x helm \
 && mv helm helm3

RUN curl -sL "https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz" | tar xzf - \
 && chmod +x oc

RUN URL=$(curl -s https://api.github.com/repos/etcd-io/etcd/releases/latest | jq -r '.assets[].browser_download_url | select(contains("linux-amd64"))') \
 && curl -sLO "$URL" \
 && tar xf etcd*.tar* --strip-components=1 --no-same-owner --wildcards 'etcd-*/etcdctl' \
 && chmod +x etcdctl \
 && rm etcd*.tar*

RUN URL=$(curl -s https://api.github.com/repos/IBM/cloud-pak-cli/releases/latest | jq -r '.assets[].browser_download_url | select(endswith("x-amd64.tar.gz"))') \
 && curl -sL "$URL" | tar xzf - \
 && chmod +x cloudctl-linux-amd64 \
 && mv cloudctl-linux-amd64 cloudctl

RUN URL=$(curl -s https://api.github.com/repos/cyberark/kubeletctl/releases/latest | jq -r '.assets[].browser_download_url | select(endswith("x_amd64"))') \ 
 && curl -sL "$URL" -o kubeletctl \
 && chmod +x kubeletctl

WORKDIR /bins

ENV UPX "-1 -qq"

RUN upx -o etcdctl /github/etcdctl \
 && upx -o grpcurl /go/bin/grpcurl \
 && upx -o auger /go/bin/auger \
 && upx -o calicoctl /github/calicoctl \
 && upx -o istioctl /github/istioctl \
 && upx -o linkerd /github/linkerd \
 && upx -o helm2 /github/helm2 \
 && upx -o helm3 /github/helm3 \
 && upx -o oc /github/oc \
 && upx -o cloudctl /github/cloudctl \
 && upx -o kubeletctl /github/kubeletctl

FROM docker.io/jpts/sectools:slim

COPY --from=builder /bins/* /usr/bin/

RUN apk add --no-cache libc6-compat aws-cli vim

CMD ["ash"]
