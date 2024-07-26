defmodule GameBackend.Repo.Migrations.AddMissingComboSkillFields do
  use Ecto.Migration

  def change do
    alter table(:skills) do
      add(:combo_reset_timer_ms, :integer)
      add(:next_skill_id, references(:skills))
    end
  end
end
