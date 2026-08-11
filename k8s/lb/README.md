# 采用LB的方式在K8S中进行邪修部署

## 前言

效果：启动脚本，在K8S中部署完成后会自动分配一个 `EXTERNAL-IP` ，客户端直接填入这个 `EXTERNAL-IP` 就可以玩游戏



这个方式必须已经在集群中安装 LoadBalancer 实现

这个方式必须已经在集群中安装 LoadBalancer 实现

这个方式必须已经在集群中安装 LoadBalancer 实现



## 前置条件

- Kubernetes 集群已就绪
- **集群已安装 LoadBalancer 实现 ( MetalLB / 云厂商 LB 等 )**
- 本机已安装 `kubectl`、`envsubst`、`awk`，且 `kubectl` 已经配置完成，能够连接到集群
- 已经单独部署 `mysql 8`，且未禁用 ` MyISAM  ` 引擎



## 局限

+ 没有对挂载进行配置



## 目录结构

```
lb/
├── deploy.sh                   # 交互式部署脚本
├── base/                       # 基础资源
│   ├── kustomization.yaml
│   ├── namespace.yaml           # Namespace: maplestory
│   └── service-lb.yaml         # LoadBalancer Service (TCP 8686/8484/7575-7577)
└── server/                      # 服务资源
    ├── kustomization.yaml
    ├── server-configmap.yaml    # ConfigMap (MySQL 连接 / JWT / WAN_HOST 等)
    └── deployment.yaml          # BeiDou Server Deployment
```



## 使用方式

+ 1）修改 `server/server-configmap.yaml` 中**数据库的连接配置**

+ 2）进入脚本根目录，直接启动脚本进行部署

  + ```shell
    cd k8s/lb
    bash deploy.sh
    ```

+ 3）查看分配的 `IP`，将其填到游戏客户端的配置文件 `config.ini` 中，配置文件字段：`ServerIP_Address`

  + 3.1）查看方式1：脚本执行过程中已经打印

    + ```shell
      [阶段2] 等待 LB 分配 External IP (超时 300s) ...
      
        ✓ LB IP = 192.###.###.###
      ```

  + 3.2）查看方式2：使用 `kubectl` 查看 `svc`，字段 `EXTERNAL-IP`

    + ```shell
      kubectl -n maplestory get svc beidou-service-lb
      ```



### 配置参数说明

#### ConfigMap (server-configmap.yaml)

| 配置项                             | 说明                                                | 必填   |
| ---------------------------------- | --------------------------------------------------- | ------ |
| `MYBATIS_FLEX_DATASOURCE_URL`      | MySQL 连接串                                        | **是** |
| `MYBATIS_FLEX_DATASOURCE_USERNAME` | MySQL 用户名                                        | **是** |
| `MYBATIS_FLEX_DATASOURCE_PASSWORD` | MySQL 密码                                          | **是** |
| `GMS_SERVICE_WAN_HOST`             | 公网地址 (运行时由脚本自动注入 `${LoadBalancerIP}`) | 否     |
| `GMS_SERVICE_LAN_HOST`             | 内网地址 (运行时由脚本自动注入 `${LoadBalancerIP}`) | 否     |
| `GMS_SERVICE_LOCALHOST`            | 本地地址 (127.0.0.1)                                | 否     |
| `JWT_SECRET`                       | JWT 密钥 (**生产环境务必自行生成**)                 | 否     |
| `SPRINGBOOT_API-DOCS_ENABLED`      | API 文档开关                                        | 否     |
| `SPRINGBOOT_SWAGGER_UI_ENABLED`    | Swagger UI 开关                                     | 否     |



#### 生成 JWT 密钥

```bash
openssl rand -hex 10
```

```powershell
-join ((1..10) | ForEach { '{0:x2}' -f (Get-Random -Maximum 256) })
```





### 脚本交互式菜单

| 选项 | 说明 |
|------|------|
| `deploy`  | 实际部署到集群 |
| `dry-run` | 仅渲染预览, 不执行 apply |
| `cleanup` | 清理已部署资源 (完全清理 / 服务清理) |



### 脚本帮助

```bash
bash deploy.sh -h
```



## 脚本运行流程说明

脚本通过 Kustomize 渲染资源, 分阶段 apply:

1. **阶段0** `kustomize build` 全量渲染
2. **阶段1** apply `Namespace + Service` (创建 LB 以获取 External IP)
3. **阶段2** 等待 LB 分配 External IP (默认超时 300s)
4. **阶段3** `envsubst` 注入 `LoadBalancerIP` 到 `ConfigMap`
5. **阶段4** apply `ConfigMap + Deployment`

> ConfigMap 中 `${LoadBalancerIP}` 占位符会在阶段3 被替换为实际 LB IP。



## 清理

```bash
bash deploy.sh
# 选择 cleanup → 完全清理 (删 Namespace) / 服务清理 (保留 Namespace+ConfigMap)
```



## 常用排查命令

```bash
# 查看资源状态
kubectl -n maplestory get pods,svc

# 查看服务日志
kubectl -n maplestory logs deploy/beidou-deployment -f

# 查看 LB IP
kubectl -n maplestory get svc beidou-service-lb
```



## 环境参考

| 组件 | 版本 |
| :--- | :--- |
| 操作系统 | Debian GNU/Linux 12 (bookworm) |
| 容器运行时 | containerd 2.2.0 |
| 容器编排 | Kubernetes 1.35.6 |
| 网络插件 | Calico 3.32 |
| 负载均衡 | MetalLB v0.16.0 |
| 数据库 | MySQL 8.4.11 |


