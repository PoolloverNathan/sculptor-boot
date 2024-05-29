# vim:ft=nix:ts=2:sts=2:sw=2:et:
{
  inputs = {
    nixpkgs.url = github:nixos/nixpkgs;
    flake-utils.url = github:numtide/flake-utils;
    sculptor.url = github:shiroyashik/sculptor;
    sculptor.flake = false;
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    sculptor,
  }:
    (with flake-utils.lib; eachSystem allSystems) (system: let
      pkgs = import nixpkgs {inherit system;};
      mf = (pkgs.lib.importTOML (sculptor + /Cargo.toml)).package;
    in {
      formatter = pkgs.alejandra;
      nixpkgs = pkgs;
      packages.default = pkgs.rustPlatform.buildRustPackage {
        pname = mf.name;
        inherit (mf) version;
        src = sculptor;
        cargoHash = sha256:bdG9x4MDjneqlHy9e018LGDOWKOmb94A9dRDnLPOjuk=;
        nativeBuildInputs = [pkgs.pkg-config pkgs.openssl.dev];
        PKG_CONFIG_PATH = pkgs.openssl.dev + /lib/pkgconfig;
      };
    })
    // {
      __functor = self: {
        name,
        app ? "default",
        # copied from Config.example.toml:
        listen ? "0.0.0.0:6665",
        motd ? [
          "You are connected to "
          {
            color = "gold";
            text = "The Sculptor";
          }
          "\nUnofficial Backend V2 for Figura\n\n"
          [
            {
              clickEvent.action = "open_url";
              clickEvent.value = https://github.com/shiroyashik/sculptor;
              text = "Please ";
            }
            {
              color = "gold";
              underlined = true;
              text = "Star";
            }
            "me on GitHub!\n\n"
          ]
        ],
        avatarDir ? "avatars",
        users ? {},
      }:
        (with flake-utils.lib; eachSystem allSystems) (system: {
          apps.${app} = {
            type = "app";
            program = "${self.nixpkgs.${system}.writers.writeBash name ''
              cd $(mktemp -d)
              ln -s ${
                if builtins.typeOf avatarDir == "path"
                then builtins.toString avatarDir
                else "~-/${avatarDir}"
              } avatars
              ln -s ${(self.nixpkgs.${system}.formats.toml {}).generate "Config.toml" {
                inherit listen;
                motd = builtins.toJSON motd;
                advancedUsers = {};
              }} Config.toml
              ${self.packages.${system}.default}/bin/${self.packages.${system}.default.pname}
            ''}";
          };
        });
    }
    // {
      inherit
        (self {
          name = "sculptor";
          app = "configured";
        })
        apps
        ;
    };
}
