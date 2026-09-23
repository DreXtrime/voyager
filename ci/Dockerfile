FROM docker:24
RUN apk add --no-cache python3 py3-pip curl bash git
RUN curl -sSL https://sdk.cloud.google.com | bash -s -- --disable-prompts
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
ENV PATH=$PATH:/root/google-cloud-sdk/bin