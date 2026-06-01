# Initial Docker support thanks to xinyifly
# Optimisation performed by wejrox

ARG RUNTIME_JRE_IMAGE=eclipse-temurin:21-jre-alpine

FROM alpine AS codestage

RUN apk add --no-cache git

WORKDIR /opt/repository

ARG CACHEBUST=1

RUN git clone https://github.com/BeiDouMS/BeiDou-Server --depth 1

FROM maven:3.9.6-amazoncorretto-21 AS builder

WORKDIR /opt/build

COPY --from=codestage /opt/repository/BeiDou-Server/pom.xml                 ./pom.xml
COPY --from=codestage /opt/repository/BeiDou-Server/gms-server/pom.xml      ./gms-server/pom.xml

RUN mvn dependency:resolve -B --no-transfer-progress

COPY --from=codestage /opt/repository/BeiDou-Server/gms-server/src          ./gms-server/src

RUN mvn package -B -DskipTests --no-transfer-progress

RUN mkdir result && mv ./gms-server/target/BeiDou.jar ./result/BeiDou.jar

COPY --from=codestage /opt/repository/BeiDou-Server/gms-server/src/main/resources/application.yml ./result/application.yml
COPY --from=codestage /opt/repository/BeiDou-Server/gms-server/wz ./result/wz
COPY --from=codestage /opt/repository/BeiDou-Server/gms-server/wz-zh-CN ./result/wz-zh-CN
COPY --from=codestage /opt/repository/BeiDou-Server/gms-server/scripts ./result/scripts
COPY --from=codestage /opt/repository/BeiDou-Server/gms-server/scripts-zh-CN ./result/scripts-zh-CN

FROM $RUNTIME_JRE_IMAGE

COPY --from=builder /opt/build/result /opt/server_backup

COPY entrypoint-nightly.sh /

RUN chmod +x /entrypoint-nightly.sh

VOLUME /opt/server

# Default exposure, although not required if using docker compose.
# This exposes the login server, and channels.
# Format for channels: WWCC, where WW is 75 plus the world number and CC is 75 plus the channel number (both zero indexed).
EXPOSE 8686 8484 7575 7576 7577

ENTRYPOINT ["/entrypoint-nightly.sh"]