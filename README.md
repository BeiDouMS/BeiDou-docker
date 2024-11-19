# 通过Docker部署BeiDouMS
### 先决条件
* 已安装 Docker && Docker-compose 

### 示例

使用稳定版

```shell
# 使用稳定的构建（github release） 

# ghcr.io/BeiDouMS/beidou-server-all:<版本号>

git clone https://github.com/BeiDouMS/beidou-docker && cd beidou-docker
# 初始化文件
sudo docker create --name temp-beidou ghcr.io/BeiDouMS/beidou-server-all:v1.5 && sudo docker cp temp-beidou:/opt/server beidou-server-release && sudo docker rm temp-beidou
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
# ghcr.io/BeiDouMS/beidou-ui:nightly
# ghcr.io/BeiDouMS/beidou-server:nightly

git clone https://github.com/BeiDouMS/beidou-docker && cd beidou-docker

# 初始化文件
sudo docker create --name temp-beidou ghcr.io/BeiDouMS/beidou-server:nightly  && sudo docker cp temp-beidou:/opt/server beidou-server-nightly && sudo docker rm temp-beidou
# 使得配置适配容器数据库
sed -i 's/localhost:3306/beidou-db:3306/g' ./beidou-server-nightly/application.yml

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

若有连接问题 检查 `application.yml` 中的 ip配置