defmodule GameBackend.Units.Skills.Skill do
  @moduledoc false

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Users.Upgrades.Buff
  alias GameBackend.Units.Skills.Mechanic

  schema "skills" do
    field(:name, :string)
    field(:game_id, :integer)
    field(:cooldown, :integer)
    field(:energy_regen, :integer)
    field(:animation_duration, :integer)
    field(:activation_delay_ms, :integer)
    field(:autoaim, :boolean, default: false)
    field(:block_movement, :boolean, default: false)
    field(:can_pick_destination, :boolean, default: false)
    field(:cooldown_mechanism, Ecto.Enum, values: [:stamina, :time, :mana])
    field(:cooldown_ms, :integer)
    field(:execution_duration_ms, :integer)
    field(:inmune_while_executing, :boolean, default: false)
    field(:is_passive, :boolean, default: false)
    field(:max_autoaim_range, :integer)
    field(:stamina_cost, :integer)
    field(:mana_cost, :integer)
    field(:mana_recovery_amount, :integer)
    field(:effects_to_apply, {:array, :string})
    field(:type, Ecto.Enum, values: [:basic, :dash, :ultimate])

    belongs_to(:buff, Buff)
    has_many(:mechanics, Mechanic, on_replace: :delete)

    timestamps()
  end

  @doc false
  def changeset(skill, attrs \\ %{}) do
    skill
    |> cast(attrs, [
      :name,
      :game_id,
      :cooldown,
      :energy_regen,
      :animation_duration,
      :buff_id,
      :activation_delay_ms,
      :autoaim,
      :block_movement,
      :can_pick_destination,
      :cooldown_mechanism,
      :cooldown_ms,
      :execution_duration_ms,
      :inmune_while_executing,
      :is_passive,
      :max_autoaim_range,
      :stamina_cost,
      :mana_cost,
      :mana_recovery_amount,
      :effects_to_apply,
      :type
    ])
    |> cast_assoc(:mechanics)
    |> unique_constraint([:game_id, :name])
    |> foreign_key_constraint(:characters, name: "characters_basic_skill_id_fkey")
  end
end
