{ pkgs, ... }:

{
  languages = {
    elixir = {
      enable = true;
      package = pkgs.beam.packages.erlangR26.elixir_1_15;
    };

    erlang = {
      enable = true;
    };
  };

  services.postgres = {
    enable = true;
    package = pkgs.postgresql_16;
    initialDatabases = [
      { name = "arena_db"; }
      { name = "game_client_db"; }
    ];
    listen_addresses = "127.0.0.1";
    #port = "5432";
    initialScript = "CREATE USER postgres WITH PASSWORD 'postgres';";
  };
}
