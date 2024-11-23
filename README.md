
<h2 align="center">
  <img height="160" width="240" src="https://github.com/BeiDouMS/BeiDou-Server/blob/master/gms-ui/src/assets/logo.png?raw=true" alt="BeiDouMS / BeiDou-Server">
  <br>
  BeiDou Docker
  <br>
  <br>


[![Docker Image Version](https://img.shields.io/docker/v/sleepnap/beidou-server-all?style=for-the-badge&label=beidou-server-all)](https://hub.docker.com/r/sleepnap/beidou-server-all)
[![Docker Image Version](https://img.shields.io/docker/v/sleepnap/beidou-server?style=for-the-badge&label=beidou-server)](https://hub.docker.com/r/sleepnap/beidou-server)
[![Docker Image Version](https://img.shields.io/docker/v/sleepnap/beidou-ui?style=for-the-badge&label=beidou-ui)](https://hub.docker.com/r/sleepnap/beidou-ui)

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/BeiDouMS/BeiDou-docker/release.yaml?style=for-the-badge&label=release%20build)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/BeiDouMS/BeiDou-docker/nightly.yaml?style=for-the-badge&label=nightly%20build)

</h2>

<br>

# 通过Docker部署BeiDouMS
### 先决条件
* 已安装 Docker && Docker-compose 

### 示例

使用稳定版

```shell
# 使用稳定的构建（github release） 

# docker.io 源
# sleepnap/beidou-server-all:<版本号>

# ghcr.io 源
# ghcr.io/beidoums/beidou-server-all:<版本号>

git clone https://github.com/BeiDouMS/BeiDou-docker && cd BeiDou-docker
# 初始化文件
sudo docker create --name temp-beidou ghcr.io/beidoums/beidou-server-all:v1.5 && sudo docker cp temp-beidou:/opt/server beidou-server-release && sudo docker rm temp-beidou
# 使得配置适配容器数据库
sed -i 's/localhost:3306/beidou-db:3306/g' ./beidou-server-release/application.yml
# 一键创建容器并启动
sudo docker compose -f docker-compose-release.yml up -d
# 关闭服务
sudo docker compose -f docker-compose-release.yml stop
# 开启服务(需要创建过)
sudo docker compose -f docker-compose-release.yml start
# 重启服务
sudo docker compose -f docker-compose-release.yml restart
# 查看日志
sudo docker compose -f docker-compose-release.yml logs --tail 500


# 服务器配置文件位置
# beidou-server-nightly/application.yml

# 脚本位置
# beidou-server-nightly/scripts
# beidou-server-nightly/scripts-zh-CN

# wz位置
# beidou-server-nightly/wz
# beidou-server-nightly/wz-zh-CN
```


使用尝鲜版
 
```shell
# 要使用最新的构建 (每日定时构建)  

# docker.io 源
# sleepnap/beidou-ui:nightly
# sleepnap/beidou-server:nightly

# ghcr.io 源
# ghcr.io/beidoums/beidou-ui:nightly
# ghcr.io/beidoums/beidou-server:nightly

git clone https://github.com/BeiDouMS/BeiDou-docker && cd BeiDou-docker

# 先修改 docker-compose-nightly.yml 中的 数据库,ip 设置 ...
# 若要访问管理页面， 还需设置app.vue

sudo docker compose -f docker-compose-nightly.yml up -d
sudo docker compose -f docker-compose-nightly.yml stop
sudo docker compose -f docker-compose-nightly.yml start
sudo docker compose -f docker-compose-nightly.yml restart
sudo docker compose -f docker-compose-nightly.yml logs --tail 500

# 服务器配置文件位置
# beidou-server-nightly/application.yml

# 脚本位置
# beidou-server-nightly/scripts
# beidou-server-nightly/scripts-zh-CN

# wz位置
# beidou-server-nightly/wz
# beidou-server-nightly/wz-zh-CN
```


### 若有连接问题 检查 `application.yml` 中的 ip 配置 

### 镜像名解释

`beidou-server-all:<version>` 为带有版本号的稳定版

`beidou-server:nightly` , `beidou-ui:nightly` 是每日五点基于最新代码构建的尝鲜版，前后端分开打包，需要一起安装，推荐使用 `docker-compose`
