defmodule Configurator.Repo.Migrations.RenameIsDefaultField do
  use Ecto.Migration

  def change do
    rename table(:configurations), :is_default, to: :current
  end
end
