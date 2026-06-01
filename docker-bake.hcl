variable "CACHEBUST" {
  default = 1
}

variable "IMAGE_TAG_BACKEND_GHCR" {
  default = "beidou-server:latest"
}

variable "IMAGE_TAG_BACKEND_DOCKER" {
  default = "beidou-server:latest"
}

variable "IMAGE_TAG_FRONTEND_GHCR" {
  default = "beidou-ui:latest"
}

variable "IMAGE_TAG_FRONTEND_DOCKER" {
  default = "beidou-ui:latest"
}

target "backend" {
  name       = "backend-${jre.name}"
  context    = "./nightly"
  dockerfile = "./docker/backend.Dockerfile"
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  matrix = {
    jre = [
      { name = "openj9", image = "ibm-semeru-runtimes:open-21-jre-noble" },
      { name = "temurin", image = "eclipse-temurin:21-jre-alpine" },
    ]
  }
  tags = [
    "${IMAGE_TAG_BACKEND_GHCR}-${jre.name}",
    "${IMAGE_TAG_BACKEND_DOCKER}-${jre.name}",
    jre.name == "temurin" ? "${IMAGE_TAG_BACKEND_GHCR}" : "",
    jre.name == "temurin" ? "${IMAGE_TAG_BACKEND_DOCKER}" : "",
  ]
  args = {
    RUNTIME_JRE_IMAGE = jre.image
    CACHEBUST         = "${CACHEBUST}"
  }
  labels = {
    "org.opencontainers.image.created" = "${timestamp()}"
  }
}

target "frontend" {
  context    = "./nightly"
  dockerfile = "./docker/frontend.Dockerfile"
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  tags = [
    "${IMAGE_TAG_FRONTEND_GHCR}",
    "${IMAGE_TAG_FRONTEND_DOCKER}",
  ]
  args = {
    CACHEBUST = "${CACHEBUST}"
  }
  labels = {
    "org.opencontainers.image.created" = "${timestamp()}"
  }
}

#####################################################################################

variable "IMAGE_TAG_RELEASE_GHCR" {
  default = "beidou-server-all:latest"
}

variable "IMAGE_TAG_RELEASE_DOCKER" {
  default = "beidou-server-all:latest"
}

variable "ARG_RELEASE_VERSION" {
  default = "1.11"
}
# 不需要传入 arch , 让 bake 处理
# variable "ARG_RELEASE_ARCH" {
#   default = "x64"
# }

target "release" {
  name       = "release-${platform_with_alias.alias}"
  context    = "./release"
  dockerfile = "./docker/release.Dockerfile"
  matrix = {
    platform_with_alias = {
      "linux/amd64" = { platform = "linux/amd64", alias = "x64" }
      "linux/arm64" = { platform = "linux/arm64", alias = "arm64" }
    }
  }
  platforms = [platform_with_alias.platform]
  tags = [
    "${IMAGE_TAG_RELEASE_GHCR}",
    "${IMAGE_TAG_RELEASE_DOCKER}"
  ]
  args = {
    RELEASE_VERSION = "${ARG_RELEASE_VERSION}"
    RELEASE_ARCH    = platform_with_alias.alias
  }
  labels = {
    "org.opencontainers.image.created" = "${timestamp()}"
  }
}