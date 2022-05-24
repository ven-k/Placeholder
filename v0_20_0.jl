# awscli automatically installs python. So this isn't a python-less rootfs-image
# Install gdb separately
# Adding it to the list of packages results in failure of version resolution and systemd

using RootfsUtils: parse_build_args, upload_gha, test_sandbox
using RootfsUtils: debootstrap
using RootfsUtils: root_chroot
release      = "bullseye"

args         = parse_build_args(ARGS, @__FILE__)
arch         = args.arch
archive      = args.archive
image        = args.image

packages = [
    "bash",
    "locales",
    "git",

    "curl",
    "vim",
    "lldb",

    # Get a C compiler, for compiling python extensions
    "build-essential",
    # Get latex, so that we can invoke `pdflatex` and friends
    "texlive-latex-extra",
    "awscli"
]

# artifact_hash, tarball_path, = debootstrap(arch, image; archive, packages, release)

artifact_hash, tarball_path, = debootstrap(arch, image; archive, packages, release) do rootfs, chroot_ENV
    my_chroot(args...) = root_chroot(rootfs, "bash", "-c", args...; ENV=chroot_ENV)

    @info("fixing systemd...")
    dpkg_fix_cmd = """
    dpkg --configure -a
    apt-get update
    apt-get upgrade
    apt-get -y install gdb
    """
    my_chroot(dpkg_fix_cmd)
end

test_sandbox(artifact_hash)

