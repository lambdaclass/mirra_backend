defmodule GameBackend.Repo.Migrations.RenameSkillAndMechanicEffects do
  use Ecto.Migration

  def change do
    rename table(:skills), :effect_to_apply, to: :on_owner_effect
    rename table(:mechanics), :on_collide_effects, to: :on_collide_effect
  end
end
