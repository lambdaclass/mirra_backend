defmodule GameBackend.Schema do
  @moduledoc """
  Base module for all schemas in game_backend

  It sets the primary key to be a binary_id and the foreign key type to be a binary_id
  """
  defmacro __using__(prefix: prefix) do
    quote do
      use Ecto.Schema
      @schema_prefix unquote(prefix)
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end

  ## This clause of the macro is only needed while we transition to the new way of using the schemas
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @schema_prefix "public"
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end
end
