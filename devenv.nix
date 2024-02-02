{ pkgs, lib, ... }: {

  # Example for passing env var to make and caddy to deploy the app automatically
  # env.DOMAIN = "brazil-testing.curseofmirra.com";

  processes = {
    main.exec = "make start";
  };

  packages = [
    # OS-agnostic packages
    pkgs.gnumake

  ] ++ lib.optionals pkgs.stdenv.isLinux [ 
    # Packages only for Linux
    pkgs.inotify-tools

  ] ++ lib.optionals pkgs.stdenv.isDarwin [ 
    #Packages only for MacOS

  ];

  languages = {
    elixir = {
      enable = true;
      package = pkgs.beam.packages.erlangR26.elixir_1_15;
    };

    erlang = {
      enable = true;
    };

    rust = {
      enable = true;
      components = [ "rustc" "cargo" "clippy" "rustfmt" "rust-analyzer" ];
    };
    
    javascript = {
      enable = true;
    };
  };
}
