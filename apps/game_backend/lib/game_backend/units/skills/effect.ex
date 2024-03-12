defmodule GameBackend.Units.Skills.Effect do
  @moduledoc false

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skills.TargetingStrategy
  alias GameBackend.Units.Skills.Type

  @primary_key false
  embedded_schema do
    field(:type, Type)

    field(:stat_affected, :string)
    # amount will be treated as the % of this stat if its set
    field(:stat_based_on, :string)
    field(:amount, :integer)
    field(:amount_format, :string)
    field(:amount_of_targets, :integer)
    field(:targeting_strategy, TargetingStrategy)
    field(:targets_allies, :boolean)
  end

  @doc false
  def changeset(effect, attrs \\ %{}) do
    effect
    |> cast(attrs, [
      :type,
      :stat_affected,
      :stat_based_on,
      :amount,
      :amount_format,
      :amount_of_targets,
      :targeting_strategy,
      :targets_allies
    ])
    |> validate_inclusion(:stat_affected, ["health", "max_health", "attack", "energy", "defense"])
    |> validate_inclusion(:amount_format, ["additive", "multiplicative"])
    |> validate_required([
      :type,
      :stat_affected,
      :amount,
      :amount_format,
      :targeting_strategy,
      :targets_allies
    ])
  end

  @doc """
  Changeset for editing a level's basic attributes.
  """
  def edit_changeset(level, attrs), do: cast(level, attrs, [:campaign])
end
