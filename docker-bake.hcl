# group "default" {
#   targets = [
#     "frontend",
#     "backend"
#   ]
# }
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