defmodule GameBackend.Units.Skills.Effect do
  @moduledoc false

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skills.Effects.{Modifier, TargetStrategy, Type}
  alias GameBackend.Units.Skills.Effects.{Modifier, TargetStrategy, Type}

  @primary_key false
  embedded_schema do
    field(:type, Type)
    field(:initial_delay, :integer)

    field(:components, {:array, :map})
    embeds_many(:modifiers, Modifier)
    field(:executions, {:array, :map})

    field(:target_count, :integer)
    field(:target_strategy, TargetStrategy)
    field(:target_allies, :boolean)
    field(:target_attribute, :string)
    field(:initial_delay, :integer)

    field(:components, {:array, :map})
    embeds_many(:modifiers, Modifier)
    field(:executions, {:array, :map})

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
      :components,
      :executions,
      :target_count,
      :target_strategy,
      :target_allies,
      :target_attribute
    ])
      :initial_delay,
      :components,
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
    |> validate_change(:executions, fn :executions, executions ->
      valid? =
        Enum.all?(executions, fn execution ->
          case execution do
            %{
              type: "DealDamage",
              attack_ratio: _attack_ratio,
              energy_recharge: _energy_recharge,
              delay: _delay
            } ->
              true

            %{
              type: "DealDamageOverTime",
              attack_ratio: _attack_ratio,
              energy_recharge: _energy_recharge,
              delay: _delay
            } ->
              true

            %{
              type: "Heal",
              attack_ratio: _attack_ratio,
              delay: _delay
            } ->
              true

            %{
              type: "AddEnergy",
              amount: _amount
            } ->
              true

            _ ->
              false
          end
        end)

      if valid?, do: [], else: [executions: "An execution is invalid"]
    end)
    |> validate_change(:components, fn :components, components ->
      valid? =
        Enum.all?(components, fn component ->
          case component do
            %{
              type: "ChanceToApply",
              chance: _chance
            } ->
              true

            %{
              type: "ApplyTags",
              tag: _effect
            } ->
              true

            _ ->
              false
          end
        end)

      if valid?, do: [], else: [components: "A component is invalid"]
    end)
    |> cast_embed(:modifiers)
  end
end
