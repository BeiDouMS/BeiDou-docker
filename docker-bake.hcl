# group "default" {
#   targets = [
#     "frontend",
#     "backend"
#   ]
# }

target "backend" {
  name = "backend-${jre.name}"
  context    = "."
  dockerfile = "./nightly/backend.Dockerfile"
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  matrix = {
    jre = [
      { name = "openj9",  image = "ibm-semeru-runtimes:open-21-jre-noble" },
      { name = "temurin", image = "eclipse-temurin:21-jre-alpine" },
    ]
  }
  tags = [
    "ghcr.io/beidoums/beidou-server:nightly-${jre.name}",
    "sleepnap/beidou-server:nightly-${jre.name}",
    # jre.name == "temurin" ? "ghcr.io/beidoums/beidou-server:nightly" : "",
    # jre.name == "temurin" ? "sleepnap/beidou-server:nightly" : "",
  ]
  args = {
    RUNTIME_JRE_IMAGE = jre.image
  }
  labels = {
    "org.opencontainers.image.created" = "${timestamp()}"
  }
}

target "frontend" {
  context    = "."
  dockerfile = "./nightly/frontend.Dockerfile"
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  tags = [
    "ghcr.io/beidoums/beidou-ui:nightly",
    "sleepnap/beidou-ui:nightly",
  ]
  labels = {
    "org.opencontainers.image.created" = "${timestamp()}"
  }
}