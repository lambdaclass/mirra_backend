defmodule GameBackend.Schema do
  @moduledoc """
  Common schema for the GameBackend. Configures primary and foreign key types.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end
end
