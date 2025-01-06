defmodule GameBackend.Repo.Migrations.AddAttackTypeToSkill do
  use Ecto.Migration

  def change do
    alter table(:skills) do
      add :attack_type, :string
    end
  end
end
