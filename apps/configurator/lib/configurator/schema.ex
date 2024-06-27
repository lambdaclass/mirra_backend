defmodule Configurator.Schema do
  @moduledoc """
  Base module for all schemas in configurator

  It sets the primary key to be a binary_id and the foreign key type to be a binary_id
  """
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end
end
