FROM ubuntu:focal

LABEL org.opencontainers.image.source https://github.com/kameshsampath/gloo-security-tutorial

ENV STEP_VERSION=0.16.0

ARG DNS_NAMES=ca.my-acme-ca.svc.cluster.local
ARG PROVISIONER_NAME=mygloodemos@example.com
ARG PASSWORD=mygloodemos

USER root

RUN apt-get update \
    && apt-get install -y curl wget sudo \
    && wget https://github.com/smallstep/cli/releases/download/v${STEP_VERSION}/step-cli_${STEP_VERSION}_amd64.deb \
    && dpkg -i step-cli_${STEP_VERSION}_amd64.deb \
    && wget https://github.com/smallstep/certificates/releases/download/v${STEP_VERSION}/step-ca_${STEP_VERSION}_amd64.deb \
    && sudo dpkg -i step-ca_${STEP_VERSION}_amd64.deb \
    && echo $PASSWORD > /step-password-file \
    && echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && useradd -u 10001 -G users,sudo,root -d /home/user --shell /bin/bash -m user \
    && usermod -p "*" user \
    && sudo chgrp -R 0 ${HOME} \
    && sudo chmod -R g+rwX ${HOME}

USER 10001

EXPOSE 8443
