FROM docker:24
RUN apk add --no-cache python3 py3-pip curl bash git
RUN curl -sSL https://sdk.cloud.google.com | bash -s -- --disable-prompts
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
RUN curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 \
    && chmod +x /usr/local/bin/argocd
ENV PATH=$PATH:/root/google-cloud-sdk/bin