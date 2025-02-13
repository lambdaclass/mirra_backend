defmodule GameBackend.Repo.Migrations.AddUnitSkins do
  use Ecto.Migration

  def change do
    create table(:skins) do
      add(:name, :string)
      add(:is_default, :boolean)
      add(:character_id, references(:characters))

      timestamps(type: :utc_datetime)
    end

    create table(:unit_skins) do
      add(:selected, :boolean)
      add(:unit_id, references(:units))
      add(:skin_id, references(:skins))

      timestamps(type: :utc_datetime)
    end
  end
end
