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
    "locales",

    "bash",
    "locales",
    "zip",
    "unzip",
    "git",
    "awscli",

    # # Some of our packages require PyCall.jl/Conda.jl deps
    "python3",

    # These are required dependencies of Cypress
    "liblapack3",
    "libgtk2.0-0",
    # "libgtk-3-dev",
    "libgbm-dev",
    "libnotify-dev",
    "libgconf-2-4",
    "libnss3",
    "libxss1",
    "libasound2",
    "libxtst6",
    "xauth",
    "xvfb",
    "npm",

    # These are just for debugging
    "curl",
    "vim"
]

# artifact_hash, tarball_path, = debootstrap(arch, image; archive, packages, release)
artifact_hash, tarball_path, = debootstrap(arch, image; archive, packages) do rootfs, chroot_ENV
    my_chroot(args...) = root_chroot(rootfs, "bash", "-c", args...; ENV=chroot_ENV)

    # apt-get install npm
    

    #=@info("Installing GTK...")
    gtk_cmd = """
    apt-get update
    apt-get install gtk
    """
    my_chroot(gtk_cmd)=#

    @info("Installing Cypress...")
    cypress_cmd = """
    npm install cypress --save-dev
    """
    my_chroot(cypress_cmd)
end

upload_gha(tarball_path)
test_sandbox(artifact_hash)
