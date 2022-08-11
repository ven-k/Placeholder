# This image is has awscli, build-essential, curl, docker, gcc, gdb, git, python, unzip, vim, zip aka almost everything that one might need

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
    "awscli",
    "gcc",

    # # Some of our packages require PyCall.jl/Conda.jl deps
    "python3",

    # Get a C compiler, for compiling python extensions
    "build-essential",
    # Get latex, so that we can invoke `pdflatex` and friends
    "texlive-latex-extra",
    "awscli",

    # These are just for debugging
    "curl",
    "vim",
    "lldb"

]

artifact_hash, tarball_path = debootstrap(arch, image; archive, packages) do rootfs, chroot_ENV
    my_chroot(args...) = root_chroot(rootfs, "bash", "-c", args...; ENV=chroot_ENV)

    @info("Fixing systemd & installing gdb...")
    dpkg_fix_cmd = """
    dpkg --configure -a
    apt-get update
    apt-get upgrade
    apt-get -y install gdb
    """
    my_chroot(dpkg_fix_cmd)

    @info("Installing docker...")
    docker_install_cmd = """
    # Enter the location we want to write files out to
    cd /usr/bin
    # Download tarball, piping it directly into `tar`, and tell `tar` to only extract one file, stripping one element of its path name:
    curl -L https://download.docker.com/linux/static/stable/x86_64/docker-20.10.10.tgz | tar -zxv --strip-components=1 docker/docker
    """
    my_chroot(docker_install_cmd)

end

upload_gha(tarball_path)
test_sandbox(artifact_hash)
