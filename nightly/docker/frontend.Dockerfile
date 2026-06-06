FROM alpine AS codestage

RUN apk add --no-cache git

WORKDIR /opt/repository

ARG CACHEBUST=1

RUN git clone https://github.com/BeiDouMS/BeiDou-Server --depth 1

FROM node:20 AS builder

ARG TARGETARCH

#arm 架构 optipng 编译有问题 所以这里使用预装的 optipng
RUN if [ "$TARGETARCH" = "arm64" ]; then \ 
    apt-get update && \
    apt-get install -y --no-install-recommends \
    optipng build-essential ca-certificates pkg-config libpng-dev zlib1g-dev python3 make gcc g++; \
    fi

WORKDIR /opt/ui

# for caching
COPY --from=codestage /opt/repository/BeiDou-Server/gms-ui/package.json ./
# for caching
COPY --from=codestage /opt/repository/BeiDou-Server/gms-ui/yarn.lock ./

# arm 架构 optipng 编译有问题 所以这里使用预装的 optipng
RUN yarn global add yarn@v1.22.10 && \
    if [ "$TARGETARCH" = "amd64" ]; then \
    yarn install --frozen-lockfile; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
    yarn install --frozen-lockfile --ignore-scripts && \
    PLATFORM="linux-arm" && \
    mkdir -p node_modules/optipng-bin/vendor/$PLATFORM && \
    ln -sf /usr/bin/optipng node_modules/optipng-bin/vendor/$PLATFORM/optipng; \
    else \
    yarn install --frozen-lockfile; \
    fi

COPY --from=codestage /opt/repository/BeiDou-Server/gms-ui/ ./

RUN yarn build --outDir ./dist

FROM nginx:alpine

COPY --from=builder /opt/ui/dist/ /usr/share/nginx/html/

COPY ./nginx-ui.conf /etc/nginx/conf.d/default.conf

EXPOSE 8686
