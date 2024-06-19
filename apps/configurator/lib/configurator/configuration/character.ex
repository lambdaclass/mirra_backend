defmodule Configurator.Configuration.Character do
  use Ecto.Schema
  import Ecto.Changeset

  schema "characters" do
    field :active, :boolean, default: false
    field :name, :string
    field :base_speed, :decimal
    field :base_size, :decimal
    field :base_health, :integer
    field :base_stamina, :integer

    timestamps(type: :utc_datetime)
  end


  @required [
    :name, :active, :base_speed, :base_size, :base_health, :base_stamina
  ]

  @permitted [] ++ @required

  @doc false
  def changeset(character, attrs) do
    character
    |> cast(attrs, @permitted)
    |> validate_required(@required)
  end
end
