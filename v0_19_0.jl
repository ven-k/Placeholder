# This image is a bit of an anomaly; we install pdflatex, python3.... pretty much the kitchen sink
# It is used by pipelines that use the SciML ecosystem such as the SciMLBenchmarks repository.

using RootfsUtils: parse_build_args, upload_gha, test_sandbox
using RootfsUtils: debootstrap
using RootfsUtils: root_chroot


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
    "liblapack3",

    # These are just for debugging
    "curl",
    "vim",
    "gdb",
    "lldb"
]

artifact_hash, tarball_path, = debootstrap(arch, image; archive, packages) do rootfs, chroot_ENV
    my_chroot(args...) = root_chroot(rootfs, "bash", "-c", args...; ENV=chroot_ENV)

    @info("Auto-fixing dpkg...")
    dpkg_fix_cmd = """
    dpkg --configure -a
    apt-get -f install
    """
    my_chroot(dpkg_fix_cmd)

end

test_sandbox(artifact_hash)
