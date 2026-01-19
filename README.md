
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

[视频教程](https://www.bilibili.com/video/BV12j6WYDEuQ/)

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

# 先修改 docker-compose-nightly.yml 中的 ip 设置 ...
# 若要访问管理页面， 还需设置app.vue
# 目前不用提供 nginx-ui.conf 了 

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


### 常见问题
- 选人后断开连接问题 检查 `compose.yml` 或 `application.yml` 中的 ip 配置， 前者优先级更高
- 修改 `compose.yml` 之后要使用 docker compose up -d 重建，并非简单重启
- 升级版本，游戏内容没变，镜像的行为没有对文件进行覆盖，建议更改目录后重建容器

### 关于 IP 设置
- 客户端的 `config.ini` 里 配置的地址是用于连接 8484 (登录服务器) 一般不会有问题
- `compose.yml` 里的三个地址是根据用户登录 8484 (登录服务器) 时候，根据 对于服务端来说客户端的地址类别 选择 一个IP 发送给客户端 告诉客户端 频道服务器 的地址， 所以 复杂的网络环境 或者 不正确的配置 往往会导致选人界面退出
- 地址类别 一般你可以在服务器的日志里用户登录时看到 如果 127 开头 则路由至 localhost ， 如果是 ABC三类内网地址 则路由至 LAN， 否则 WAN
- 桥接模式 docker 会做 源地址伪装 ， 所以 ip 基本是 172.x.x.x ， 会触发 LAN ， 这块 有动手能力想解决的 可以切换成 `host` 或者 `macvlan`

### 镜像名解释

`beidou-server-all:<version>` 为带有版本号的稳定版

`beidou-server:nightly` , `beidou-ui:nightly` 是每日五点基于最新代码构建的尝鲜版，前后端分开打包，需要一起安装，推荐使用 `docker-compose`
