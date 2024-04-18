defmodule GameBackend.Units.Skills.Mechanics.Effect do
  @moduledoc false

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skills.Mechanics.Effects.Modifier

  @primary_key false
  embedded_schema do
    field(:type, :map)
    field(:initial_delay, :integer)

    field(:components, {:array, :map})
    embeds_many(:modifiers, Modifier)
    field(:executions, {:array, :map})
  end

  @doc false
  def changeset(effect, attrs \\ %{}) do
    effect
    |> cast(attrs, [
      :type,
      :initial_delay,
      :components,
      :executions
    ])
    |> validate_required([
      :type,
      :initial_delay
    ])
    |> validate_change(:executions, fn :executions, executions ->
      valid? =
        Enum.all?(executions, fn execution -> valid_execution?(execution) end)

      if valid?, do: [], else: [executions: "An execution is invalid"]
    end)
    |> validate_change(:components, fn :components, components ->
      valid? =
        Enum.all?(components, fn component -> valid_component?(component) end)

      if valid?, do: [], else: [components: "A component is invalid"]
    end)
    |> cast_embed(:modifiers)
  end

  defp valid_execution?(execution) do
    case execution do
      %{
        type: "DealDamage",
        attack_ratio: _attack_ratio,
        energy_recharge: _energy_recharge
      } ->
        true

      %{
        type: "DealDamageOverTime",
        attack_ratio: _attack_ratio,
        energy_recharge: _energy_recharge
      } ->
        true

      %{
        type: "Heal",
        attack_ratio: _attack_ratio
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
  end

  defp valid_component?(component) do
    case component do
      %{
        type: "ChanceToApply",
        chance: _chance
      } ->
        true

      %{
        type: "ApplyTags",
        tags: [_some_tag | _other_tags]
      } ->
        true

      %{
        type: "TargetTagRequirements",
        tags: [_some_tag | _other_tags]
      } ->
        true

      _ ->
        false
    end
  end
end
