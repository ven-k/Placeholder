# This image is a bit of an anomaly; we install pdflatex, python3.... pretty much the kitchen sink
# It is used by pipelines that use the SciML ecosystem such as the SciMLBenchmarks repository.

using RootfsUtils: parse_build_args, upload_gha, test_sandbox
using RootfsUtils: debootstrap
using RootfsUtils: root_chroot

args         = parse_build_args(ARGS, @__FILE__)
arch         = args.arch
archive      = args.archive
image        = args.image
release      = "bullseye"

packages = [
    "locales",

    # "bash",
    # "locales",
    # "zip",
    # "unzip",
    # "git",
    # "awscli",

    # Work around bug in debootstrap where virtual dependencies are not properly installed
    # X-ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=878961
    # X-ref: https://bugs.launchpad.net/ubuntu/+source/debootstrap/+bug/86536
    # "perl-openssl-defaults",
    # "dbus-user-session",
    # "python3-sip",

    # Get a C compiler, for compiling python extensions
    # "build-essential",
    # # Get latex, so that we can invoke `pdflatex` and friends
    # "texlive-latex-extra",
    # "lmodern",
    # # Some of our packages require PyCall.jl/Conda.jl deps
    # "python3",


    # These are required dependencies
    #="liblapack3",
    "libgtk2.0-0",
    "libgtk-3-0",
    "libgbm-dev",
    "libnotify-dev",
    "libgconf-2-4",
    "libnss3",
    "libxss1",
    "libasound2",
    "libxtst6",
    "xauth",
    "xvfb",=#
    "npm",

    # These are just for debugging
    "curl",
    "vim"
]

# artifact_hash, tarball_path, = debootstrap(arch, image; archive, packages, release)
artifact_hash, tarball_path, = debootstrap(arch, image; archive, packages, release) do rootfs, chroot_ENV
    my_chroot(args...) = root_chroot(rootfs, "bash", "-c", args...; ENV=chroot_ENV)

    # apt-get install npm
    @info("Installing Cypress...")
    cypress_cmd = """
    npm install cypress --save-dev
    """
    my_chroot(cypress_cmd)
end

upload_gha(tarball_path)
test_sandbox(artifact_hash)
