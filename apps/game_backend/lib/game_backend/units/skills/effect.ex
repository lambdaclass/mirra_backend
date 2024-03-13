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
    field(:executions, {:array, Execution})

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
      :initial_delay,
      :executions,
      :target_count,
      :target_strategy,
      :target_allies,
      :target_attribute
    ])
    |> validate_required([
      :type,
      :initial_delay,
      :target_count,
      :target_strategy,
      :target_allies,
      :target_attribute
    ])
    |> cast_embed(:components)
    |> cast_embed(:modifiers)
  end
end
