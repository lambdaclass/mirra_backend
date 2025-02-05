defmodule GameBackend.Repo.Migrations.AddUsersOwnedAssets do
  use Ecto.Migration

  def change do
    create table(:skins) do
      add(:is_default, :boolean)
      add(:character_id, references(:characters))

      timestamps(type: :utc_datetime)
    end

    create table(:assets) do
      add(:type, :string)
      add(:is_equipped, :boolean)

      timestamps(type: :utc_datetime)
    end

    create table(:owned_assets) do
      add(:user_id, references(:users))
      add(:asset_id, references(:assets))

      timestamps(type: :utc_datetime)
    end
  end
end
