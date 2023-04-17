{ lib, stdenv, fetchFromGitHub
, makeWrapper, premake5
, SDL2
}:

stdenv.mkDerivation rec {
  pname = "virtualxt";
  version = "0.8";

  src = fetchFromGitHub {
    owner = "andreas-jonsson";
    repo = pname;
    rev = "v0.8";
    sha256 = "sha256-2OISIxUaikj17X5aWdpjOpnrDdAvdT8eNUCb/30mSa4=";
  };

  nativeBuildInputs = [ makeWrapper premake5 ];
  buildInputs = [ SDL2 ];

  buildFlags = [ "sdl2-frontend" ];

  installPhase = ''
    runHook preInstall

    share=$out/share; bin=$out/bin; lib=$out/lib
    mkdir -p $share $bin $lib
    cp build/bin/virtualxt $bin
    mkdir -p $share/bios $share/boot
    cp boot/* $share/boot; cp bios/*.bin $share/bios

    wrapProgram $bin/virtualxt \
        --run 'XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"' \
        --run 'VXT_CONFIG="$XDG_CONFIG_HOME/virtualxt"' \
        --run 'mkdir -p "$VXT_CONFIG"' \
        --run "cp $share/boot/freedos_hd.img"' "$VXT_CONFIG"' \
        --run 'chmod 644 "$VXT_CONFIG/freedos_hd.img"' \
        --set VXT_DEFAULT_BIOS_PATH $share/bios/pcxtbios.bin \
        --set VXT_DEFAULT_VXTX_BIOS_PATH $share/bios/vxtx.bin \
        --run 'export VXT_DEFAULT_HD_IMAGE="$VXT_CONFIG/freedos_hd.img"'

    runHook postInstall
  '';

  meta = {
      homepage = "https://virtualxt.org";
      description = "A portable, lightweight IBM PC/XT emulator written in C.";
      licenses = lib.licenses.free;
      maintainers = with lib.maintainers; [ fmahnke ];
  };
}

