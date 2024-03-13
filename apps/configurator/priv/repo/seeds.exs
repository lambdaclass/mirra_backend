## TODO: Change this once PR#336 is merged
{:ok, data_json} = File.read("../arena/priv/config.json")

%Configurator.Configure.Configuration{data: data_json, is_default: true}
|> Configurator.Repo.insert!()
