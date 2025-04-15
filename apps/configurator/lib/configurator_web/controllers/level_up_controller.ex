defmodule ConfiguratorWeb.LevelUpController do
  use ConfiguratorWeb, :controller

  alias GameBackend.Configuration

  def index(conn, %{"version_id" => version_id}) do
    level_up_config = Configuration.get_level_up_configuration_by_version(version_id)
    version = Configuration.get_version!(version_id)

    render(conn, :index, level_up_config: level_up_config, version: version)
  end
end
