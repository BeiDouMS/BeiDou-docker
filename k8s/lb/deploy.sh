#!/bin/bash
# BeiDou K8s 部署脚本 (交互式, Kustomize)
#
# 功能:
#   kustomize build → 分离 Namespace/Service → apply 拿 LB IP →
#   envsubst 注入 LoadBalancerIP → apply ConfigMap + Deployment
#   支持资源清理: 完全清理(删 Namespace) / 服务清理(删 Deployment+Service)
#
# 用法:
#   bash deploy.sh              # 交互式菜单选择
#   bash deploy.sh -h           # 显示帮助
#
# 前置: kubectl / envsubst

set -euo pipefail

# ============ 配置 ============
NAMESPACE="maplestory"
DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="${DEPLOY_DIR}/base"
SERVER_DIR="${DEPLOY_DIR}/server"
LB_SVC="beidou-service-lb"
WAIT_TIMEOUT=300          # 等待 LB IP 的超时秒数
POLL_INTERVAL=5           # 轮询间隔秒数

# ============ 颜色 ============
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_CYAN='\033[0;36m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_RED='\033[0;31m'
C_DIM='\033[2m'

# ============ 帮助 ============
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "BeiDou K8s 部署脚本 (交互式)"
  echo ""
  echo "用法: bash deploy.sh"
  echo ""
  echo "交互式菜单选择操作模式:"
  echo "  deploy  - 实际部署到集群"
  echo "  dry-run - 仅渲染预览, 不执行 apply"
  echo "  cleanup - 清理已部署资源"
  echo ""
  echo "清理模式提供两种级别:"
  echo "  完全清理 - 删除整个 ${NAMESPACE} Namespace"
  echo "  服务清理 - 仅删除 Deployment + Service"
  exit 0
fi

# ============ 依赖检查 ============
for cmd in kubectl envsubst awk; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo -e "${C_RED}[ERROR]${C_RESET} 未找到命令: $cmd，请先安装"
    exit 1
  fi
done
for d in "$BASE_DIR" "$SERVER_DIR"; do
  if [[ ! -d "$d" ]]; then
    echo -e "${C_RED}[ERROR]${C_RESET} 找不到目录: $d"
    exit 1
  fi
done

# ============ 交互式菜单 ============
clear
echo -e "${C_BOLD}${C_CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║     BeiDou K8s 部署脚本 (交互式)         ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${C_RESET}"

# ── [1/1] 操作模式 ──
echo ""
echo -e "${C_BOLD}━━━ [1/1] 操作模式 ━━━${C_RESET}"
echo "  1) deploy  - 实际部署到集群 (默认)"
echo "  2) dry-run - 仅渲染预览, 不执行 apply"
echo "  3) cleanup - 清理已部署资源"
echo ""
read -r -p "  请选择 [1-3, 默认=1]: " RUN_CHOICE
case "${RUN_CHOICE:-1}" in
  1) RUN_MODE="deploy";  DRY_RUN=false ;;
  2) RUN_MODE="dry-run"; DRY_RUN=true  ;;
  3) RUN_MODE="cleanup"; DRY_RUN=false ;;
  *) echo -e "  ${C_YELLOW}无效选择, 使用默认值 deploy${C_RESET}"; RUN_MODE="deploy"; DRY_RUN=false ;;
esac
echo -e "  ${C_GREEN}→ 操作: ${RUN_MODE}${C_RESET}"

# ═══════════════════════ 清理分支 ═══════════════════════
if [[ "$RUN_MODE" == "cleanup" ]]; then
  echo ""
  echo -e "${C_BOLD}━━━ 清理选项 ━━━${C_RESET}"
  echo "  1) 完全清理  - 删除 ${NAMESPACE} Namespace 及其中所有资源 (最彻底)"
  echo "  2) 服务清理  - 仅删除 Deployment + Service (保留 namespace/configmap 等)"
  echo "  3) 取消"
  echo ""
  read -r -p "  请选择 [1-3, 默认=3]: " CLEANUP_CHOICE
  case "${CLEANUP_CHOICE:-3}" in
    1) CLEANUP_LEVEL="full" ;;
    2) CLEANUP_LEVEL="service" ;;
    3|*) echo -e "  ${C_YELLOW}已取消清理。${C_RESET}"; exit 0 ;;
  esac

  echo ""
  if [[ "$CLEANUP_LEVEL" == "full" ]]; then
    echo -e "${C_YELLOW}将删除 Namespace '${NAMESPACE}' 及其中所有资源！${C_RESET}"
    echo -e "这将移除: ${C_DIM}Deployment / Service / ConfigMap / Pod ...${C_RESET}"
  else
    echo -e "${C_YELLOW}将删除 Deployment 和 Service (保留 namespace/configmap 等)${C_RESET}"
  fi
  echo ""
  read -r -p "确认清理? 输入 '${NAMESPACE}' 后回车: " CONFIRM_CLEANUP
  if [[ "$CONFIRM_CLEANUP" != "$NAMESPACE" ]]; then
    echo -e "${C_YELLOW}已取消清理。${C_RESET}"
    exit 0
  fi

  echo ""
  if [[ "$CLEANUP_LEVEL" == "full" ]]; then
    echo -e "${C_BOLD}[清理] 删除 Namespace '${NAMESPACE}' ...${C_RESET}"
    kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
    echo -e "  ${C_GREEN}✓ Namespace '${NAMESPACE}' 已删除${C_RESET}"
  else
    echo -e "${C_BOLD}[清理] 删除 Deployment ...${C_RESET}"
    kubectl delete deployment beidou-deployment -n "$NAMESPACE" --ignore-not-found=true 2>/dev/null || true
    echo -e "  ${C_GREEN}✓ Deployment 已删除${C_RESET}"

    echo -e "${C_BOLD}[清理] 删除 Service ...${C_RESET}"
    kubectl delete svc "$LB_SVC" -n "$NAMESPACE" --ignore-not-found=true 2>/dev/null || true
    echo -e "  ${C_GREEN}✓ Service 已删除${C_RESET}"
  fi

  echo ""
  echo -e "${C_BOLD}${C_GREEN}"
  echo "╔══════════════════════════════════════════╗"
  echo "║           清理完成                        ║"
  echo "╚══════════════════════════════════════════╝"
  echo -e "${C_RESET}"
  exit 0
fi

# ═══════════════════════ 部署确认 ═══════════════════════
echo ""
echo -e "${C_BOLD}${C_CYAN}╔══════════════════════════════════════════╗${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}║           配置确认                       ║${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}╠══════════════════════════════════════════╣${C_RESET}"
printf "${C_BOLD}${C_CYAN}║${C_RESET}  %-12s ${C_GREEN}%-24s${C_RESET} ${C_BOLD}${C_CYAN}║${C_RESET}\n" "Namespace:" "${NAMESPACE}"
printf "${C_BOLD}${C_CYAN}║${C_RESET}  %-12s ${C_GREEN}%-24s${C_RESET} ${C_BOLD}${C_CYAN}║${C_RESET}\n" "Mode:"      "${RUN_MODE}"
echo -e "${C_BOLD}${C_CYAN}╚══════════════════════════════════════════╝${C_RESET}"
echo ""
read -r -p "确认部署? [y/N]: " CONFIRM
if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
  echo -e "${C_YELLOW}已取消部署。${C_RESET}"
  exit 0
fi

echo ""
echo -e "${C_CYAN}[配置]${C_RESET} namespace=${NAMESPACE}  dry-run=${DRY_RUN}"

# ============ 构建临时 kustomization ============
TMP_KDIR="$(mktemp -d)"
trap 'rm -rf "$TMP_KDIR"' EXIT

# 计算相对路径
relpath() {
  local target="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath --relative-to="$TMP_KDIR" "$target"
  else
    awk -v t="$target" -v b="$TMP_KDIR" 'BEGIN{
      n=split(t,ta,"/"); m=split(b,ba,"/"); i=1;
      while(i<=n && i<=m && ta[i]==ba[i]) i++;
      out=""; for(j=i;j<=m;j++) out=out"../"; for(j=i;j<=n;j++) out=out ta[j] (j<n?"/":"");
      gsub(/\/$/,"",out); print out
    }'
  fi
}

# 写入临时 kustomization.yaml
cat > "${TMP_KDIR}/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: ${NAMESPACE}
resources:
  - $(relpath "$BASE_DIR")
  - $(relpath "$SERVER_DIR")
EOF

echo ""
echo -e "${C_DIM}[kustomize] 临时目录: ${TMP_KDIR}${C_RESET}"
echo -e "${C_DIM}----- kustomization.yaml -----${C_RESET}"
cat "${TMP_KDIR}/kustomization.yaml" | while IFS= read -r line; do echo -e "${C_DIM}${line}${C_RESET}"; done
echo -e "${C_DIM}------------------------------${C_RESET}"

# ============ kustomize build 全量渲染 ============
echo ""
echo -e "${C_BOLD}[阶段0] kustomize build 渲染 ...${C_RESET}"
RENDERED_ALL="$(kubectl kustomize "$TMP_KDIR" --load-restrictor LoadRestrictionsNone)"

if [[ "$DRY_RUN" == true ]]; then
  echo ""
  echo -e "${C_CYAN}----- 渲染结果 (dry-run, 未注入 LoadBalancerIP) -----${C_RESET}"
  echo "$RENDERED_ALL"
  echo -e "${C_CYAN}----- 渲染结束 -----${C_RESET}"
  echo ""
  echo -e "${C_YELLOW}[dry-run] 完成, 未执行 apply${C_RESET}"
  exit 0
fi

# ============ 按 kind 分离: Namespace/Service 先 apply, 其余等 LB IP ============
# ConfigMap 含 ${LoadBalancerIP} 占位符, 需等待 LB IP 后 envsubst 注入
NS_SVC_FILE="${TMP_KDIR}/ns-svc.yaml"
REMAIN_FILE="${TMP_KDIR}/remain.yaml"
: > "$NS_SVC_FILE"
: > "$REMAIN_FILE"

echo "$RENDERED_ALL" | awk -v RS='---' -v g1="$NS_SVC_FILE" -v g2="$REMAIN_FILE" '
  /kind: Namespace/ || /kind: Service/ { print "---" > g1; print > g1; next }
  { print "---" > g2; print > g2 }
'

# 兜底: 若 awk 未正确分流
if [[ ! -s "$NS_SVC_FILE" ]] && [[ ! -s "$REMAIN_FILE" ]]; then
  echo -e "${C_RED}[ERROR]${C_RESET} 渲染分离失败, 原始输出:"
  echo "$RENDERED_ALL"
  exit 1
fi

# ============ 阶段1: apply Namespace + Service ============
echo ""
echo -e "${C_BOLD}[阶段1] apply Namespace + Service${C_RESET} (创建 LB 以获取 External IP) ..."
kubectl apply -f "$NS_SVC_FILE"
echo -e "  ${C_GREEN}✓ Namespace + Service 已应用${C_RESET}"

# ============ 阶段2: 等待 LB 分配 External IP ============
echo ""
echo -e "${C_BOLD}[阶段2] 等待 LB 分配 External IP${C_RESET} (超时 ${WAIT_TIMEOUT}s) ..."
START=$(date +%s)
LOAD_BALANCER_IP=""
while true; do
  NOW=$(date +%s)
  if (( NOW - START > WAIT_TIMEOUT )); then
    echo ""
    echo -e "${C_RED}[ERROR] 等待 LB IP 超时${C_RESET}"
    echo "  排查: kubectl get svc -n ${NAMESPACE} ${LB_SVC} -o yaml"
    exit 1
  fi
  LOAD_BALANCER_IP=$(kubectl get svc "$LB_SVC" -n "$NAMESPACE" \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  if [[ -z "$LOAD_BALANCER_IP" ]]; then
    LOAD_BALANCER_IP=$(kubectl get svc "$LB_SVC" -n "$NAMESPACE" \
      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  fi
  [[ -n "$LOAD_BALANCER_IP" ]] && break
  ELAPSED=$((NOW-START))
  echo -ne "  ... 等待中 (${ELAPSED}s), ${POLL_INTERVAL}s 后重试\r"
  sleep "$POLL_INTERVAL"
done
echo ""
echo -e "  ${C_GREEN}✓ LB IP = ${LOAD_BALANCER_IP}${C_RESET}"

# ============ 阶段3: envsubst 注入 LoadBalancerIP 到 ConfigMap + Deployment ============
echo ""
echo -e "${C_BOLD}[阶段3] 渲染 ConfigMap + Deployment${C_RESET} (注入 LoadBalancerIP=${LOAD_BALANCER_IP}) ..."
RENDERED_REMAIN=$(LoadBalancerIP="$LOAD_BALANCER_IP" envsubst '${LoadBalancerIP}' < "$REMAIN_FILE")

# ============ 阶段4: apply ConfigMap + Deployment ============
echo ""
echo -e "${C_BOLD}[阶段4] apply ConfigMap + Deployment ...${C_RESET}"
echo "$RENDERED_REMAIN" | kubectl apply -f -
echo -e "  ${C_GREEN}✓ ConfigMap + Deployment 已应用${C_RESET}"

# ============ 完成 ============
echo ""
echo -e "${C_BOLD}${C_GREEN}"
echo "╔══════════════════════════════════════════╗"
echo "║           部署完成                        ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${C_RESET}"
printf "  %-16s ${C_GREEN}%s${C_RESET}\n" "命名空间:"   "${NAMESPACE}"
printf "  %-16s ${C_GREEN}%s${C_RESET}\n" "LB IP:"      "${LOAD_BALANCER_IP}"
echo ""
echo -e "  ${C_DIM}查看状态: kubectl -n ${NAMESPACE} get pods,svc${C_RESET}"
echo -e "  ${C_DIM}查看日志: kubectl -n ${NAMESPACE} logs deploy/beidou-deployment -f${C_RESET}"
echo ""
