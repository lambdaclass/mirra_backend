defmodule GameBackend.Repo.Migrations.AddUsersOwnedAssets do
  use Ecto.Migration

  def change do
    create table(:skins) do
      add(:name, :string)
      add(:is_default, :boolean)
      add(:character_id, references(:characters))

      timestamps(type: :utc_datetime)
    end

    create table(:user_skins) do
      add(:user_id, references(:users))
      add(:skin_id, references(:skins))

      timestamps(type: :utc_datetime)
    end
  end
end
