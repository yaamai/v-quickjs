BASE = [
    'podman',
    'run',
    '--rm',
    '-e', 'AIRI_LOG_LEVEL='+ENV.AIRI_LOG_LEVEL,
    '-e', 'USER='+ENV.USER,
    '-e', 'HOME='+ENV.PWD+'/home',
    '-v', '/tmp:/tmp',
    '-v', ENV.PWD+':'+ENV.PWD,
    '-w', ENV.PWD//,
    // ENV.ISTTY // 'ENV.ISTTY' special env value, if within tty, replaced with '-t'
]
// DEFS.ary.suffix = ["--"]
// DEFS.obj.s = ["--"]

// c/c++
let gcc = "docker.io/library/gcc:latest"
CMDS.gcc = gcc
CMDS["g++"] = gcc
CMDS.cmake = 'registry.naru.pw/de/cmake:latest'

// python
let python = {b: [BASE, "-e", "PATH="+ENV.PATH, "-e", "VIRTUAL_ENV="+ENV.VIRTUAL_ENV], s: ["--", "python"], i: "registry.naru.pw/de/python:latest", a: CMDLINE.slice(1)}
CMDS.python = python
CMDS.pylint = Object.assign({}, python, {s: [python.s, "-m", "pylint"]})
CMDS.mypy = Object.assign({}, python, {s: [python.s, "-m", "mypy"]})
CMDS.flake8 = "registry.naru.pw/de/python:latest"
//Object.assign({}, python, {s: [python.s, "-m", "flake8"]})
CMDS.autopep8 = "registry.naru.pw/de/python:latest"
CMDS.black = "registry.naru.pw/de/python:latest"
CMDS["reorder-python-imports"] = "registry.naru.pw/de/python:latest"
CMDS.pip = Object.assign({}, python, {s: [python.s, "-m", "pip"]})
CMDS.pytest = Object.assign({}, python, {s: [python.s, "-m", "pytest"]})
CMDS.cython = "registry.naru.pw/de/cython:latest"

// go
// NOTE: ale go linter cd to subdir. so mount entire working dir is needed
let go = ['-v', ENV.HOME+':'+ENV.HOME, '-e', 'GOPATH=' + ENV.PWD + '/go', '-e', 'HOME=/tmp', 'registry.naru.pw/de/golang:latest']
CMDS.go = go
CMDS.gofmt = go
CMDS.gopls = go

// shell scripts
CMDS.shellcheck = ['-e', 'PATH=/bin', 'docker.io/koalaman/shellcheck:stable']

// rust
//rust = [BASE, 'registry.naru.pw/de/rust:latest']
let rust = [BASE, 'docker.io/library/rust:1.51-alpine']
CMDS.cargo = rust
CMDS.rustc = rust

// v
CMDS.v = "reg.naru.pw/vlang:latest"
CMDS.vls = "reg.naru.pw/de/vlang:latest"

// kubernetes
let k8s_env = ["-e", "KUBECONFIG="+ENV.KUBECONFIG]
CMDS.helm = [k8s_env, "docker.io/alpine/helm:3.3.0"]
CMDS["k8s-gitsync"] = [k8s_env, "-e", "KGS_LOG_LEVEL=DEBUG", "docker.io/yaamai/k8s-gitsync:c963445c"]
CMDS.kubectl = [k8s_env, "docker.io/bitnami/kubectl:1.18.10"]
CMDS.velero = {p: k8s_env, i: 'docker.io/velero/velero:v1.5.2', a: ['/velero', CMDLINE.slice(1)]}
CMDS.flux = {p: k8s_env, i: "registry.naru.pw/de/flux:latest", a: ['/flux', CMDLINE.slice(1)]}
CMDS["kube-webhook-certgen"] = {p: k8s_env, i: 'docker.io/jettech/kube-webhook-certgen:v1.5.0', a: ['/kube-webhook-certgen', CMDLINE.slice(1)]}

// misc
CMDS.etcd = ["-e", "ALLOW_NONE_AUTHENTICATION=yes", "docker.io/bitnami/etcd:latest"]
CMDS.etcdctl = ["-e", "ALLOW_NONE_AUTHENTICATION=yes", "docker.io/bitnami/etcd:latest"]
CMDS.upx = [BASE, 'docker.io/yaamai/upx:latest']
CMDS.mc = [BASE, 'docker.io/minio/mc:latest']
CMDS.kaniko = {i: 'gcr.io/kaniko-project/executor:latest', a: ['/kaniko/executor', CMDLINE.slice(1)]}
CMDS.restic = [BASE, '-e', 'AWS_SECRET_ACCESS_KEY=minioadmin', '-e', 'AWS_ACCESS_KEY_ID=minioadmin', 'docker.io/restic/restic:0.9.6', '--']
CMDS.sops = "docker.io/yaamai/sops:latest"
CMDS.kubeseal = "docker.io/yaamai/sealed-secrets:latest"

// nodejs
CMDS.npx = "docker.io/library/node:latest"
CMDS.npm = "docker.io/library/node:latest"
CMDS.node = "docker.io/library/node:latest"

// lua
CMDS.lua = "docker.io/woahbase/alpine-lua:latest"

// crystal
CMDS.crystal = "docker.io/crystallang/crystal:latest"

"ok"
