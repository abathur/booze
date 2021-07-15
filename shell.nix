
{ pkgs ? import <nixpkgs> { }
}:

with pkgs;
let
  test_bash = pkgs.bash_5.overrideAttrs (oldAttrs:
    with pkgs; rec {
      # src = ./.;
      # borrowed from https://github.com/NixOS/nixpkgs/blob/master/pkgs/shells/bash/4.4.nix
      # except to skip external readline in favor of built-in readline
      # patches = [];

      prePatch = ''
        substituteInPlace Makefile.in --replace "conftypes.h unwind_prot.h jobs.h siglist.h" "conftypes.h unwind_prot.h jobs.h siglist.h execute_cmd.h"
      '';
      dontStrip = true;
      extraOutputsToInstall = [ "include" ];
    });
  booze = stdenv.mkDerivation rec {
    pname = "booze";
    version = "unreleased";
    src = ./.;
    # src = fetchFromGitHub {
    #   owner  = "zevweiss";
    #   repo   = "booze";
    #   rev    = "14831de6380b45489d514b34cd2ea921f37baff0";
    #   # 058f760c142869cbad22a18d5a54f01702269b5f
    #   hash = "sha256-5PKO0Mx/sevpTgJLXM1wA57T+hE9QM/UJhN2jMUMSp8=";
    # };
    installPhase = ''
      mkdir -p $out/lib
      install booze.so $out/lib
      ls -la $out/lib/booze.so
    '';
    dontStrip = true;
    prePatch = ''
      substituteInPlace Makefile --replace "/usr/include/bash /usr/include/bash/builtins" "${test_bash.dev}/include/bash ${test_bash.dev}/include/bash/include ${test_bash.dev}/include/bash/builtins"
      substituteInPlace Makefile --replace "-bundle_loader bash" "-bundle_loader ${test_bash}/bin/bash"
    '';
    nativeBuildInputs = [ pkg-config test_bash gcc clang fuse ];
    buildInputs = with pkgs; [ fuse ];
  };

in pkgs.mkShell {
  buildInputs = [ booze test_bash ];
  shellHook = ''
    final=
    cleanup(){
      umount mount
      rm -rf source mount
      echo $final
    }
    trap cleanup EXIT
    mkdir source mount
    touch source/{one,two}
    enable -f ${booze}/lib/booze.so booze
    . ./passthrough.sh source mount &
    sleep 2
    if [[ -e mount/two ]]; then
      final="They DO exist!"
      exit 0
    else
      final="Oh no!"
      exit 1
    fi
  '';
}
