defmodule ConfiguratorWeb.ConfigurationJSON do
  def show(%{configuration: configuration}) do
    Jason.decode!(configuration.data)
  end
end
