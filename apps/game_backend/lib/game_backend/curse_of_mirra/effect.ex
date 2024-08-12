defmodule GameBackend.CurseOfMirra.Effect do
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
             :name
           ]}
  embedded_schema do
    field(:name, :string)
    field(:duration_ms, :integer)
    field(:remove_on_action, :boolean)
    field(:one_time_application, :boolean)
    field(:allow_multiple_effects, :boolean)
    field(:consume_projectile, :boolean)
    embeds_many(:effect_mechanics, EffectMechanic)
  end

  def changeset(position, attrs) do
    position
    |> cast(attrs, [
      :duration_ms,
      :remove_on_action,
      :one_time_application,
      :allow_multiple_effects,
      :consume_projectile,
      :name
    ])
    |> validate_required([
      :remove_on_action,
      :one_time_application,
      :allow_multiple_effects,
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
               :force
             ]}
    embedded_schema do
      field(:name, :string)
      field(:modifier, :decimal)
      field(:force, :decimal)
      field(:execute_multiple_times, :boolean)
      field(:damage, :integer)
      field(:effect_delay_ms, :integer)
    end

    def changeset(position, attrs) do
      position
      |> cast(attrs, [
        :name,
        :modifier,
        :execute_multiple_times,
        :damage,
        :effect_delay_ms,
        :force
      ])
      |> validate_required([
        :name,
        :execute_multiple_times,
        :effect_delay_ms
      ])
    end
  end
end
