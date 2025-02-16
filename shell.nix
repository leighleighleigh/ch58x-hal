let
  #rustOverlay = builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz";
  rustOverlay = builtins.fetchGit {
    url = "https://github.com/oxalica/rust-overlay";
    rev = "85f3aed5f4b8eb312c6e8fe8c476bac248aed75f";
  };

  pkgs = import <nixpkgs> {
    overlays = [ (import rustOverlay) ];
  };

  rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
  
  llvmPackages = pkgs.llvmPackages;

  jdkVersion = pkgs.jdk21;

  hostPkgs = [ rust ] ++ (with pkgs; [
    #just
    pkg-config
    systemd
    udev
    openssl

    # for libcamera-rs
    libcamera # for native builds
    #pkgsCross.aarch64-multiplatform.libcamera
    #pkgsCross.aarch64-multiplatform.glibc
    
    # bindgen struggles to find libclang, needs this
    #libclang # see below
    rustPlatform.bindgenHook

    zlib
    #meson
    #ninja
    #(python3.withPackages(ps: [ ps.jinja2 ps.ply ]))

    # for cargo xbuild / tauri
    # from https://v2.tauri.app/start/prerequisites/#linux
    at-spi2-atk
    atkmm
    cairo
    gdk-pixbuf
    glib

    #glibc # dont inclde, it confuses things
    #glibc_multi

    gobject-introspection
    gobject-introspection.dev
    gtk3
    librsvg
    libsoup_3
    harfbuzz
    fuse2
    pango
    webkitgtk_4_1
    webkitgtk_4_1.dev
    libgcrypt
    gpgme


    # for android tools (emulator specifically)
    nss
    nspr
    libdrm
    freetype
    xorg.libSM
    xorg.libICE
    xorg.libXrender
    xorg.libXrandr
    xorg.libXfixes
    xorg.libXcursor
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libxcb
    xorg.libXi
    xorg.libXinerama
    fontconfig
    xorg.libX11
    xorg.libXext
    xorg.libxkbfile
    mesa
    expat
    libxkbcommon
    alsa-lib
    libpulseaudio
    libpng
    libbsd
    wchisp
    wlink
  ]) ++ [ jdkVersion ] 
  ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.wrapGAppsHook4 ];

in
  pkgs.mkShell.override {stdenv = pkgs.clangStdenv;} rec {
  #pkgs.mkShell.override {stdenv = pkgs.clangMultiStdenv;} rec {
  #pkgs.mkShell.override {stdenv = pkgs.gccMultiStdenv;} rec {
  #pkgs.mkShell.override {stdenv = pkgs.gccStdenv;} rec {

    buildInputs = hostPkgs;

    LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath buildInputs}";

    shellHook = ''
        export PS1="''${debian_chroot:+($debian_chroot)}\[\033[01;39m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ "
        export PS1="(nix-rs)$PS1"
        export LD_LIBRARY_PATH="''${LD_LIBRARY_PATH}:${LD_LIBRARY_PATH}"
        # for android builds / emulation
        export ANDROID_HOME="$HOME/Android/Sdk"
        export NDK_HOME="$ANDROID_HOME/ndk/$(ls -1 $ANDROID_HOME/ndk)"
        export JAVA_HOME="${jdkVersion.home}"
        # to make gtk plugin happy
        export XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS
    '';
  }
