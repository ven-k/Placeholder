# Modified https://github.com/JuliaCI/rootfs-images/commit/00640956a6c0637b32b0943975dbc3e904463cb5

using RootfsUtils: parse_build_args, upload_gha, test_sandbox
using RootfsUtils: debootstrap

args         = parse_build_args(ARGS, @__FILE__)
arch         = args.arch
archive      = args.archive
image        = args.image

# Build debian-based image with the following extra packages:
packages = [
    "awscli",
    "bash",
    "curl",
    "git",
    "gpg",
    "gpg-agent",
    "locales",
    "localepurge",
    "build-essential",
    "openssh-client",
    "vim",
]

artifact_hash, tarball_path, = debootstrap(arch, image; archive, packages)
upload_gha(tarball_path)
test_sandbox(artifact_hash)
