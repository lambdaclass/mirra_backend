{
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";

  outputs = { self, nixpkgs }: 
  let
    pkgs = import nixpkgs { system = "aarch64-darwin"; };

    beamPkgs = with pkgs.beam_minimal; packagesWith interpreters.erlangR26;
    erlang = beamPkgs.erlang;
    elixir = beamPkgs.elixir_1_15;
    nodejs = pkgs.nodejs_20;
    rust = pkgs.rustc;
    cargo = pkgs.cargo;
    postgres = pkgs.postgresql;

  in {
    defaultPackage.aarch64-darwin = pkgs.mkShell {
      name = "curse-of-mirra";
      buildInputs = [
        elixir 
        pkgs.nil 
        erlang 
        nodejs 
        rust 
        cargo 
      ];

      # ENV VARS
      LANG               = "en_US.UTF-8";
      CARGO_INSTALL_ROOT = "${toString ./.}/.cargo";
      ERL_INCLUDE_PATH   = "${erlang}/lib/erlang/usr/include";
    };
  };
}
