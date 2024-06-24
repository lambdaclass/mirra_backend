defmodule Configurator.Configuration.Character do
  use Configurator.Schema
  import Ecto.Changeset

  schema "characters" do
    field :active, :boolean, default: false
    field :name, :string
    field :base_speed, :decimal
    field :base_size, :decimal
    field :base_health, :integer
    field :base_stamina, :integer

    field :max_inventory_size, :integer
    field :natural_healing_interval, :integer
    field :natural_healing_damage_interval, :integer
    field :stamina_interval, :integer

    # TODO This should be removed once we have the skills relationship
    field :skills, {:map, :string}

    timestamps(type: :utc_datetime)
  end

  @required [
    :name,
    :active,
    :base_speed,
    :base_size,
    :base_health,
    :base_stamina,
    :stamina_interval,
    :max_inventory_size,
    :natural_healing_interval,
    :natural_healing_damage_interval,
    :skills
  ]

  @permitted [] ++ @required

  @doc false
  def changeset(character, attrs) do
    character
    |> cast(attrs, @permitted)
    |> validate_required(@required)
  end
end
