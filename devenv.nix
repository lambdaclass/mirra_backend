{ pkgs, lib, ... }: {

  # Example for passing env var to make and caddy to deploy the app automatically
  # env.DOMAIN = "brazil-testing.curseofmirra.com";

  processes = {
    main.exec = "make start";
  };

  packages = [
    # OS-agnostic packages
    pkgs.gnumake
    pkgs.protobuf
    pkgs.rustc
    pkgs.cargo

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

    #rust = {
    #  enable = true;
    #};
    
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
    };	
  };
}
