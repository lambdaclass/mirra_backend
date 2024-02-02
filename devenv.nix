{ pkgs, lib, ... }: {

  packages = [
    pkgs.gnumake
  ] ++ lib.optionals pkgs.stdenv.isLinux [ # Packages only for Linux
    pkgs.inotify-tools
  ] ++ lib.optionals pkgs.stdenv.isDarwin [ #Packages only for MacOS
    #pkgs.darwin.apple_sdk.frameworks.Security
  ];

  languages = {
    elixir = {
      enable = true;
      package = pkgs.beam.packages.erlangR26.elixir_1_15;
    };
    erlang = {
      enable = true;
    };
   
    javascript = {
      enable = true;
    };
  };

  processes = {
    main.exec = "make start";
  };
}
