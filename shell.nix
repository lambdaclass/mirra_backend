with (import <nixpkgs> {});
let
  basePackages = [
    erlang_26
    beam.packages.erlangR26.elixir_1_15
    nodejs_20
  ];
in mkShell {
  buildInputs = basePackages;

  shellHook = ''
    make _start
  '';
}
