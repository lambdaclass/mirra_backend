defmodule GameBackend.Units.Characters.Character do
  @moduledoc """
  Characters are the template on which units are based.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skills.Skill

  @derive {Jason.Encoder,
           only: [
             :active,
             :name,
             :base_attack,
             :base_health,
             :base_defense,
             :base_stamina,
             :stamina_interval,
             :max_inventory_size,
             :natural_healing_interval,
             :natural_healing_damage_interval,
             :base_speed,
             :base_size,
             :base_mana,
             :mana_recovery_strategy,
             :mana_recovery_time_interval_ms,
             :mana_recovery_time_amount,
             :mana_recovery_damage_multiplier
           ]}

  schema "characters" do
    field(:game_id, :integer)
    field(:active, :boolean, default: true)
    field(:name, :string)
    field(:title, :string)
    field(:lore, :string)
    field(:faction, :string)
    field(:class, :string)
    field(:quality, :integer)
    field(:ranks_dropped_in, {:array, :integer})

    field(:base_health, :integer)
    field(:base_attack, :integer)
    field(:base_defense, :integer)
    field(:base_stamina, :integer)
    field(:stamina_interval, :integer)
    field(:max_inventory_size, :integer)
    field(:natural_healing_interval, :integer)
    field(:natural_healing_damage_interval, :integer)
    field(:base_speed, :float)
    field(:base_size, :float)
    field(:base_mana, :integer)
    field(:mana_recovery_strategy, Ecto.Enum, values: [:time, :skill, :damage])
    field(:mana_recovery_time_interval_ms, :integer)
    field(:mana_recovery_time_amount, :decimal)
    field(:mana_recovery_damage_multiplier, :decimal)

    belongs_to(:basic_skill, Skill, on_replace: :update)
    belongs_to(:ultimate_skill, Skill, on_replace: :update)
    belongs_to(:dash_skill, Skill, on_replace: :update)

    timestamps()
  end

  @doc false
  def changeset(character, attrs) do
    character
    |> cast(attrs, [
      :game_id,
      :name,
      :active,
      :faction,
      :quality,
      :title,
      :lore,
      :class,
      :ranks_dropped_in,
      :basic_skill_id,
      :ultimate_skill_id,
      :base_health,
      :base_attack,
      :base_speed,
      :stamina_interval,
      :base_size,
      :base_stamina,
      :base_mana,
      :initial_mana,
      :mana_recovery_strategy,
      :mana_recovery_time_interval_ms,
      :mana_recovery_time_amount,
      :mana_recovery_damage_multiplier,
      :max_inventory_size,
      :natural_healing_interval,
      :natural_healing_damage_interval,
      :base_defense,
      :basic_skill_id,
      :dash_skill_id,
      :ultimate_skill_id
    ])
    |> cast_assoc(:basic_skill)
    |> cast_assoc(:ultimate_skill)
    |> validate_required([:game_id, :name, :active, :faction])
  end
end
