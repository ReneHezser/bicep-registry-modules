FROM mcr.microsoft.com/dotnet/runtime-deps:latest as build

ARG TARGETOS=linux
ARG TARGETARCH=amd64
ARG RUNNER_VERSION=
ARG RUNNER_CONTAINER_HOOKS_VERSION=
ARG DOCKER_VERSION=27.3.1
ARG BUILDX_VERSION=0.18.0

RUN apt update -y && apt install curl jq unzip openssl -y
WORKDIR /actions-runner
RUN export RUNNER_ARCH=${TARGETARCH} \
  && if [ "$RUNNER_VERSION" = "" ]; then export RUNNER_VERSION_LATEST=$(curl -s -i https://github.com/actions/runner/releases/latest | grep location: | sed 's#.*tag/v##' | sed 's/\r//'); \
  export RUNNER_VERSION=$RUNNER_VERSION_LATEST; fi \
  && if [ "$RUNNER_ARCH" = "amd64" ]; then export RUNNER_ARCH=x64 ; fi \
  && echo "Using runner version $RUNNER_VERSION" \
  && curl -f -L -o runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-${TARGETOS}-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
  && tar xzf ./runner.tar.gz \
  && rm runner.tar.gz

RUN if [ "$RUNNER_CONTAINER_HOOKS_VERSION" = "" ]; then export RUNNER_CONTAINER_HOOKS_VERSION_LATEST=$(curl -s -i https://github.com/actions/runner-container-hooks/releases/latest | grep location: | sed 's#.*tag/v##' | sed 's/\r//'); \
  export RUNNER_CONTAINER_HOOKS_VERSION=$RUNNER_CONTAINER_HOOKS_VERSION_LATEST; fi \
  && echo "Using runner container hooks version $RUNNER_CONTAINER_HOOKS_VERSION" \
  && curl -f -L -o runner-container-hooks.zip https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip \
  && unzip ./runner-container-hooks.zip -d ./k8s \
  && rm runner-container-hooks.zip

RUN export RUNNER_ARCH=${TARGETARCH} \
  && if [ "$RUNNER_ARCH" = "amd64" ]; then export DOCKER_ARCH=x86_64 ; fi \
  && if [ "$RUNNER_ARCH" = "arm64" ]; then export DOCKER_ARCH=aarch64 ; fi \
  && curl -fLo docker.tgz https://download.docker.com/${TARGETOS}/static/stable/${DOCKER_ARCH}/docker-${DOCKER_VERSION}.tgz \
  && tar zxvf docker.tgz \
  && rm -rf docker.tgz \
  && mkdir -p /usr/local/lib/docker/cli-plugins \
  && curl -fLo /usr/local/lib/docker/cli-plugins/docker-buildx \
  "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-${TARGETARCH}" \
  && chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx

FROM mcr.microsoft.com/azure-powershell:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_MANUALLY_TRAP_SIG=1
ENV ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1
ENV ImageOS=ubuntu22

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends \
  sudo \
  lsb-release \
  && rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos "" --uid 1001 runner \
  && groupadd docker --gid 123 \
  && usermod -aG sudo runner \
  && usermod -aG docker runner \
  && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers \
  && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers

WORKDIR /home/runner

COPY --chown=runner:docker --from=build /actions-runner .
COPY --from=build /usr/local/lib/docker/cli-plugins/docker-buildx /usr/local/lib/docker/cli-plugins/docker-buildx

RUN install -o root -g root -m 755 docker/* /usr/bin/ && rm -rf docker
USER root
RUN apt-get update && apt-get install -y curl jq && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN curl -LsS https://aka.ms/InstallAzureCLIDeb | bash && rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh
USER runner
ENTRYPOINT ["/home/runner/entrypoint.sh"]
