{ pkgs ? import <nixpkgs> { } }:


pkgs.mkShell {
  # # 

  materialFonts = pkgs.fetchzip {
			url = "https://storage.googleapis.com/flutter_infra_release/flutter/fonts/bd151aa3c2f7231344411a01dba4ef61b3cd56b2/fonts.zip";
			sha512 = "z4M6JxQGA+hiylnPQip0V05be3gy1KUCvXfDyS1x1q3MJrx8Y3ekOFVHxOE2gWjEcmskSV90WlUYQN4AcLcZCw==";
      stripRoot = false;
		};

  src = "./";

  buildInputs = with pkgs; [
    gnupg
    dart
    xapian gmime3 talloc zlib
    pythonPackages.python
    notmuch
    llvm
    llvmPackages.libclang
    gdb
    unzip
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
# "build/flutter_assets/fonts/"
  phases = [ "unpackPhase" "buildPhase" ];
  unpackPhase = ''
  runHook preUnpack
    mkdir -p build/flutter_assets/fonts/
    cp $materialFonts/* build/flutter_assets/fonts/
    #ls build/flutter_assets/fonts/
    runHook postUnpack
    echo "listing.."
    ls -la .
  '';
  buildPhase = ''
  ls -la
  flutter build linux
  '';
}
