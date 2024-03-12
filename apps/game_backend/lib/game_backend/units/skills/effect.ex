defmodule GameBackend.Units.Skills.Effect do
  @moduledoc false

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skills.Effects.{Component, Modifier, Execution, TargetStrategy, Type}

  @primary_key false
  embedded_schema do
    field(:type, Type)
    field(:initial_delay, :integer)

    embeds_many(:components, Component)
    embeds_many(:modifiers, Modifier)
    embeds_many(:executions, Execution)

    field(:target_count, :integer)
    field(:target_strategy, TargetStrategy)
    field(:target_allies, :boolean)
    field(:target_attribute, :string)
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
      :target_strategy,
      :targets_allies
    ])
    |> validate_inclusion(:stat_affected, ["health", "max_health", "attack", "energy", "defense"])
    |> validate_inclusion(:amount_format, ["additive", "multiplicative"])
    |> validate_required([
      :type,
      :stat_affected,
      :amount,
      :amount_format,
      :target_strategy,
      :targets_allies
    ])
  end

  @doc """
  Changeset for editing a level's basic attributes.
  """
  def edit_changeset(level, attrs), do: cast(level, attrs, [:campaign])
end
