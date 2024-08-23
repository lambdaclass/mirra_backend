defmodule GameBackend.ArenaServers.ArenaServer do
  @moduledoc """
  ArenaServers
  """
  use GameBackend.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:name, :ip, :url, :status, :environment]}
  schema "arena_servers" do
    field(:name, :string)
    field(:ip, :string)
    field(:url, :string)
    field(:gateway_url, :string)
    field(:status, Ecto.Enum, values: [:active, :inactive])
    field(:environment, Ecto.Enum, values: [:production, :development, :staging])

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(arena_server, attrs) do
    arena_server
    |> cast(attrs, [:name, :ip, :url, :status, :environment, :gateway_url])
    |> validate_required([:name, :url, :status, :environment, :gateway_url])
  end
end
