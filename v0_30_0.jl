# Adds liblapack-dev to the v0_29_0 image

using RootfsUtils: parse_build_args, upload_gha, test_sandbox
using RootfsUtils: debootstrap
using RootfsUtils: root_chroot, chroot
release  = "bullseye"

args         = parse_build_args(ARGS, @__FILE__)
arch         = args.arch
archive      = args.archive
image        = args.image

packages = [
    "locales",
    "localepurge",

    "bash",
    "zip",
    "unzip",
    "git",
    "gcc",
    "g++",
    "liblapack-dev",

    # Some of our packages require PyCall.jl/Conda.jl deps
    "python3",

    # Get a C compiler, for compiling python extensions
    "build-essential",
    # Get latex, so that we can invoke `pdflatex` and friends
    "texlive-latex-extra",

    # These are just for debugging
    "curl",
    "vim",
    "lldb",

    # JSON parser
    "jq"

]

artifact_hash, tarball_path = debootstrap(arch, image; archive, packages, release) do rootfs, chroot_ENV
    my_chroot(args...) = root_chroot(rootfs, "bash", "-c", args...; ENV=chroot_ENV)

    @info("Fixing systemd & installing gdb...")
    dpkg_fix_cmd = """
    dpkg --configure -a
    apt-get update
    apt-get upgrade
    apt-get -y install gdb
    """
    my_chroot(dpkg_fix_cmd)

    @info("Add AWSCLI V2...")
    awscli_v2_cmd = """
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    """
    my_chroot(awscli_v2_cmd)

    @info("Installing docker...")
    docker_install_cmd = """
    # Enter the location we want to write files out to
    cd /usr/bin
    # Download tarball, piping it directly into `tar`, and tell `tar` to only extract one file, stripping one element of its path name:
    curl -L https://download.docker.com/linux/static/stable/x86_64/docker-20.10.19.tgz | tar -zxv --strip-components=1 docker/docker
    """
    my_chroot(docker_install_cmd)

    @info("Installing docker buildx & making it executable...")
    docker_buildx_cmd = """
    # Download the buildx binary to /usr/local/lib/docker/cli-plugins, rename it as docker-buildx and make it executable for all users
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -L https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-amd64 --output /usr/local/lib/docker/cli-plugins/docker-buildx
    chmod a+x /usr/local/lib/docker/cli-plugins/docker-buildx
    """
    my_chroot(docker_buildx_cmd)
end

# test_sandbox(artifact_hash)
