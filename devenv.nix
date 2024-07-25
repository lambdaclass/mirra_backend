{ pkgs, lib, ... }: {

  processes = {
    main.exec = "make start";
  };

  packages = [
    # OS-agnostic packages
    pkgs.gnumake
    pkgs.protobuf
    pkgs.rustc
    pkgs.cargo
    pkgs.clang
    pkgs.nodejs_21

  ] ++ lib.optionals pkgs.stdenv.isLinux [ 
    # Packages only for Linux
    pkgs.inotify-tools

  ] ++ lib.optionals pkgs.stdenv.isDarwin [ 
    #Packages only for MacOS
  
  ];

  languages = {
    elixir = {
      enable = true;
      package = pkgs.beam.packages.erlangR26.elixir_1_16;
    };

    erlang = {
      enable = true;
    };
    
    javascript = {
      enable = true;
    };
  };
  
  services = {	
    postgres = {	
      enable = true;	
      package = pkgs.postgresql_16;	
      port = 5432;	
      listen_addresses = "127.0.0.1";	
      initialScript = "CREATE USER postgres WITH PASSWORD 'postgres'; ALTER USER postgres WITH SUPERUSER;";
      initialDatabases = [
        { name = "game_backend_prod"; }
      ];
    };
  };
}
