{ pkgs, ... }:

{
  languages = {
    nix = {
      enable = true;
    };

    elixir = {
      enable = true;
      package = pkgs.beam.packages.erlangR25.elixir_1_13;
    };
  };

  services.postgres = {
    enable = true;
    package = pkgs.postgresql_16;
    initialDatabases = [
      { name = "arena_db"; }
      #{ name = "game_client_db"; }
    ];
    #listen_addresses = "127.0.0.1";
    #port = "5432";
    initialScript = "CREATE USER postgres WITH PASSWORD 'postgres';";
  };
}
