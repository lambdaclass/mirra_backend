{ pkgs, ... }:

{
  processes = {
    main.exec = "make start";
  };

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
    };

    javascript = {
      enable = true;
    };
  };

  packages = [
    pkgs.inotify-tools
    pkgs.gnumake
  ];

  services = {
    #postgres = {
    #  enable = true;
    #  package = pkgs.postgresql_16;
    #  initialDatabases = [
    #    { name = "arena_db"; }
    #    { name = "game_client_db"; }
    #  ];
    #  port = 5432;
    #  listen_addresses = "127.0.0.1";
    #  initialScript = "CREATE USER postgres WITH PASSWORD 'postgres';";
    #};
    #caddy = {
    #  enable = true;
    #
    #  # Replace with actual domain.
    #  config = "
    #    localhost {
    #      reverse_proxy localhost:4000
    #    }
    #  ";
    #};
  };
}

