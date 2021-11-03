{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    gnupg
    dart
    xapian gmime3 talloc zlib
    pythonPackages.python
    notmuch
    llvm
    llvmPackages.libclang
    gdb
  ];

  nativeBuildInputs = with pkgs; [
    gdk_pixbuf
    glib
    epoxy
    atk
    harfbuzz
    pango
    cairo
    libselinux
    libsepol
    xorg.xorgproto
    xorg.libXft
    xorg.libXinerama
    pcre
    xorg.libX11.dev
    xorg.libX11
    flutter
    cmake
    ninja
    clang
    pkg-config
    gtk3-x11
    gtk3.dev
    util-linux
  ];

  FLUTTER_PATH = "${pkgs.flutter}";


  CPATH = "${pkgs.xorg.libX11.dev}/include:${pkgs.xorg.xorgproto}/include:${pkgs.epoxy}/lib";

  CLANG_PATH = with pkgs; pkgs.lib.makeLibraryPath [ llvmPackages.libclang ];

  LD_LIBRARY_PATH = with pkgs; "$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [ clang llvm notmuch pango epoxy gtk3 harfbuzz atk cairo gdk_pixbuf glib ]}";
}
