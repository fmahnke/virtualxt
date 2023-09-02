{ lib, stdenv, fetchFromGitHub
, makeWrapper, premake5
, libpcap
, SDL2
}:

stdenv.mkDerivation rec {
  pname = "virtualxt";
  version = "0.9";

  src = fetchFromGitHub {
    owner = "andreas-jonsson";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-RFafBwYhBtUILnZ9wSwMd+7jUIGh+yMMXu5SAK7AYHw=";
  };

  nativeBuildInputs = [ makeWrapper premake5 ];
  buildInputs = [ SDL2 libpcap ];

  buildFlags = [ "sdl2-frontend modules" ];

  premakeFlags = [ "--modules" ];

  installPhase = ''
    runHook preInstall

    set -e

    share=$out/share; bin=$out/bin; lib=$out/lib
    modules=$share/modules

    mkdir -p $share/bios $share/boot $modules $bin $lib

    cp build/bin/* $bin
    cp boot/* $share/boot
    cp bios/*.bin bios/*.ROM $share/bios
    cp modules/*.vxt $modules

    wrapProgram $bin/virtualxt \
        --run 'XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"' \
        --run 'VXT_CONFIG="$XDG_CONFIG_HOME/virtualxt"' \
        --run 'mkdir -p "$VXT_CONFIG"' \
        --run "cp $share/boot/*.img"' "$VXT_CONFIG"' \
        --run 'chmod 644 "$VXT_CONFIG"/*.img' \
        --set VXT_DEFAULT_MODULES_PATH $modules \
        --set VXT_DEFAULT_BIOS_PATH $share/bios/GLABIOS.ROM \
        --set VXT_DEFAULT_VXTX_BIOS_PATH $share/bios/vxtx.bin \
        --run 'export VXT_DEFAULT_HD_IMAGE="$VXT_CONFIG/freedos_hd.img"'

    set +e

    runHook postInstall
  '';

  meta = {
      homepage = "https://virtualxt.org";
      description = "A portable, lightweight IBM PC/XT emulator written in C.";
      licenses = lib.licenses.free;
      maintainers = with lib.maintainers; [ fmahnke ];
  };
}

