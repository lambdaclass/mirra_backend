defmodule GameBackend.Units.Skills.Skill do
  @moduledoc false

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Configuration.Version
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
    field(:reset_combo_ms, :integer)
    field(:execution_duration_ms, :integer)
    field(:inmune_while_executing, :boolean, default: false)
    field(:is_passive, :boolean, default: false)
    field(:is_combo?, :boolean, default: false)
    field(:max_autoaim_range, :integer)
    field(:stamina_cost, :integer)
    field(:mana_cost, :integer)
    field(:type, Ecto.Enum, values: [:basic, :dash, :ultimate])
    field(:attack_type, Ecto.Enum, values: [:melee, :ranged])

    belongs_to(:buff, Buff)
    belongs_to(:next_skill, __MODULE__)
    has_many(:mechanics, Mechanic, on_replace: :delete)
    belongs_to(:version, Version)
    embeds_one(:on_owner_effect, GameBackend.CurseOfMirra.Effect)

    timestamps()
  end

  @permitted [
    :name,
    :game_id,
    :cooldown,
    :energy_regen,
    :animation_duration,
    :buff_id,
    :next_skill_id,
    :activation_delay_ms,
    :autoaim,
    :block_movement,
    :can_pick_destination,
    :cooldown_mechanism,
    :cooldown_ms,
    :reset_combo_ms,
    :execution_duration_ms,
    :inmune_while_executing,
    :is_passive,
    :is_combo?,
    :max_autoaim_range,
    :stamina_cost,
    :mana_cost,
    :type,
    :version_id,
    :attack_type
  ]

  @doc false
  def changeset(skill, attrs \\ %{}) do
    skill
    |> cast(attrs, @permitted)
    |> cast_assoc(:mechanics)
    |> unique_constraint([:game_id, :name, :version_id])
    |> validate_required([:game_id, :name, :version_id])
    |> foreign_key_constraint(:characters, name: "characters_basic_skill_id_fkey")
    |> cooldown_mechanism_validation()
    |> validate_combo_fields()
    |> cast_embed(:on_owner_effect)
  end

  @doc false
  def assoc_changeset(skill, attrs \\ %{}) do
    skill
    |> cast(attrs, @permitted)
    |> cast_assoc(:mechanics)
    |> unique_constraint([:game_id, :name, :version_id])
    |> validate_required([:game_id, :name])
    |> foreign_key_constraint(:characters, name: "characters_basic_skill_id_fkey")
    |> cooldown_mechanism_validation()
    |> validate_combo_fields()
    |> cast_embed(:on_owner_effect)
  end

  defp cooldown_mechanism_validation(changeset) do
    case get_field(changeset, :cooldown_mechanism) do
      :stamina ->
        changeset
        |> validate_required([:stamina_cost])
        |> validate_number(:stamina_cost, greater_than_or_equal_to: 0)

      :time ->
        changeset
        |> validate_required([:cooldown_ms])
        |> validate_number(:cooldown_ms, greater_than_or_equal_to: 0)

      :mana ->
        changeset
        |> validate_required([:mana_cost])
        |> validate_number(:mana_cost, greater_than_or_equal_to: 0)

      _ ->
        changeset
    end
  end

  defp validate_combo_fields(changeset) do
    is_combo? = get_field(changeset, :is_combo?)
    reset_combo_ms = get_field(changeset, :reset_combo_ms)

    if is_combo? and is_nil(reset_combo_ms) do
      add_error(changeset, :reset_combo_ms, "Combo reset time is needed for combo skills")
    else
      changeset
    end
  end
end
