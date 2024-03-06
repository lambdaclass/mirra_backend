defmodule GameBackend.Units.Skill do
  @moduledoc false

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skills.Effect
  alias GameBackend.Units.Skills.TargetingStrategy

  schema "skills" do
    field(:name, :string)
    embeds_many(:effects, Effect, on_replace: :delete)
    field(:targeting_strategy, TargetingStrategy)
    field(:targets_allies, :boolean)
    field(:amount_of_targets, :integer)
    field(:cooldown, :integer)
    timestamps()
  end

  @doc false
  def changeset(skill, attrs \\ %{}) do
    skill
    |> cast(attrs, [:name, :targeting_strategy, :amount_of_targets, :cooldown, :targets_allies])
    |> cast_embed(:effects)
  end
end
