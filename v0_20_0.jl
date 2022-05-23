# awscli automatically installs python. So this isn't a python-less rootfs-image

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
    "zip",
    "unzip",
    "git",

    # Work around bug in debootstrap where virtual dependencies are not properly installed
    # X-ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=878961
    # X-ref: https://bugs.launchpad.net/ubuntu/+source/debootstrap/+bug/86536
    "perl-openssl-defaults",
    "dbus-user-session",
  
    # Get a C compiler, for compiling python extensions
    "build-essential",
    # Get latex, so that we can invoke `pdflatex` and friends
    "texlive-latex-extra",
    "awscli",

    # These are just for debugging
    "curl",
    "vim",
    "gdb",
    # "gdb-minimal",
    "lldb"
]

# artifact_hash, tarball_path, = debootstrap(arch, image; archive, packages, release)

artifact_hash, tarball_path, = debootstrap(arch, image; archive, packages, release) do rootfs, chroot_ENV
    my_chroot(args...) = root_chroot(rootfs, "bash", "-c", args...; ENV=chroot_ENV)

    @info("fixing systemd...")
    dpkg_fix_cmd = """
    apt install --reinstall systemd
    """
    my_chroot(dpkg_fix_cmd)
end

test_sandbox(artifact_hash)
