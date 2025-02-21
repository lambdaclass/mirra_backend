defmodule GameBackend.CurseOfMirra.Effects.Effect do
  @moduledoc """
  """
  use GameBackend.Schema
  alias __MODULE__.EffectMechanic
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :duration_ms,
             :remove_on_action,
             :one_time_application,
             :allow_multiple_effects,
             :consume_projectile,
             :effect_mechanics,
             :disabled_outside_pool,
             :name
           ]}
  embedded_schema do
    field(:name, :string)
    field(:duration_ms, :integer)
    field(:remove_on_action, :boolean)
    field(:one_time_application, :boolean)
    field(:allow_multiple_effects, :boolean)
    field(:consume_projectile, :boolean)
    field(:disabled_outside_pool, :boolean)
    embeds_many(:effect_mechanics, EffectMechanic, on_replace: :delete)
  end

  def changeset(position, attrs) do
    position
    |> cast(attrs, [
      :duration_ms,
      :remove_on_action,
      :one_time_application,
      :allow_multiple_effects,
      :consume_projectile,
      :disabled_outside_pool,
      :name
    ])
    |> validate_required([
      :remove_on_action,
      :one_time_application,
      :allow_multiple_effects,
      :disabled_outside_pool,
      :name
    ])
    |> cast_embed(:effect_mechanics)
  end

  defmodule EffectMechanic do
    @moduledoc """
    EffectMechanic embedded schema to be used by Effect
    """
    use GameBackend.Schema

    @derive {Jason.Encoder,
             only: [
               :name,
               :modifier,
               :execute_multiple_times,
               :damage,
               :effect_delay_ms,
               :force,
               :additive_duration_add_ms,
               :stat_multiplier
             ]}
    embedded_schema do
      field(:name, Ecto.Enum,
        values: [
          :damage_change,
          :defense_change,
          :reduce_stamina_interval,
          :reduce_cooldowns_duration,
          :speed_boost,
          :modify_radius,
          :damage_immunity,
          :pull_immunity,
          :pull,
          :damage,
          :buff_pool,
          :refresh_stamina,
          :refresh_cooldowns,
          :invisible,
          :silence
        ]
      )

      field(:modifier, :decimal)
      field(:force, :decimal)
      field(:execute_multiple_times, :boolean)
      field(:damage, :integer)
      field(:effect_delay_ms, :integer)
      field(:additive_duration_add_ms, :integer)
      field(:stat_multiplier, :decimal)
    end

    def changeset(position, attrs) do
      position
      |> cast(attrs, [
        :name,
        :modifier,
        :execute_multiple_times,
        :damage,
        :effect_delay_ms,
        :force,
        :additive_duration_add_ms,
        :stat_multiplier
      ])
      |> validate_required([
        :name,
        :execute_multiple_times,
        :effect_delay_ms
      ])
    end
  end
end
