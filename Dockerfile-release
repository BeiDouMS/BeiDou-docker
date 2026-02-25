# 使用基础镜像
FROM ubuntu:20.04 AS builder

# 安装需要的工具（curl, jq）
RUN apt-get update && \
    apt-get install -y curl jq && \
    apt-get clean

ARG GITHUB_OWNER=BeiDouMS
ARG GITHUB_REPO=BeiDou-Server

ARG RELEASE_PREFIX_GIT_TAG=Release
# 根据传入的参数中的版本号取 release 中的 tar.gz
ARG RELEASE_VERSION
# arm64 x64 根据架构搜索  xxxx.tar.gz
ARG RELEASE_ARCH

RUN curl -s https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/tags/${RELEASE_VERSION} \
    | jq -r '.assets[] | select(.name | endswith("'${RELEASE_ARCH}'.tar.gz")) | .browser_download_url' \
    | xargs -n 1 curl -fsSL -o latest_release.tar.gz

RUN mkdir -p /opt/server_unzip

RUN tar -xzvf latest_release.tar.gz -C /opt/server_unzip --strip-components=1

# alpine好像缺点东西
FROM ubuntu:20.04

ENV LANG=C.UTF-8

ENV LC_ALL=C.UTF-8

COPY --from=builder /opt/server_unzip /opt/server_backup

COPY entrypoint-release.sh /

RUN chmod +x entrypoint-release.sh

VOLUME /opt/server

EXPOSE 8686 8484 7575 7576 7577

ENTRYPOINT ["/entrypoint-release.sh"]