defmodule GameBackend.Units.Skills.Effect do
  @moduledoc false

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skills.Type

  @primary_key false
  embedded_schema do
    field(:type, Type)
    field(:stat, :string)
    field(:based_on_stat, :string) # amount will be treated as the % of this stat if its set
    field(:amount, :integer)
    field(:application_type, :string)
  end

  @doc false
  def changeset(effect, attrs \\ %{}) do
    effect
    |> cast(attrs, [:type, :stat, :based_on_stat, :amount, :application_type])
    |> validate_inclusion(:stat, ["health", "max_health", "attack", "speed", "energy", "armor"])
    |> validate_inclusion(:application_type, ["additive", "multiplicative"])
    |> validate_required([:type, :stat, :amount, :application_type])
  end

  @doc """
  Changeset for editing a level's basic attributes.
  """
  def edit_changeset(level, attrs), do: cast(level, attrs, [:campaign])
end
