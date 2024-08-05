defmodule GameBackend.Repo.Migrations.AddNewSkillFieldsForCombo do
  use Ecto.Migration

  def change do
    alter table(:skills) do
      add(:reset_combo_ms, :integer)
      add(:is_combo?, :boolean, default: false)
      add(:next_skill_id, references(:skills))
    end
  end
end
