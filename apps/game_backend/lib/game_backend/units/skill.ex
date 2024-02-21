defmodule GameBackend.Units.Skill do
  @moduledoc false

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skills.Effect
  alias GameBackend.Units.Skills.TargetingStrategy

  schema "skills" do
    embeds_many(:effects, Effect)
    field(:targeting_strategy, TargetingStrategy)
    field(:amount_of_targets, :integer)
    field(:cooldown, :integer)
    timestamps()
  end

  @doc false
  def changeset(skill, attrs \\ %{}) do
    skill
    |> cast(attrs, [:targeting_strategy, :amount_of_targets])
    |> cast_embed(:effects)
    |> validate_required([:targeting_strategy])
  end
end
