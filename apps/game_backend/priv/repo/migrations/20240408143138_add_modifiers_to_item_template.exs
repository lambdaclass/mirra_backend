defmodule GameBackend.Repo.Migrations.AddModifiersToItemTemplate do
  use Ecto.Migration

  def change do
    alter table(:item_templates) do
      add :base_modifiers, {:array, :map}
    end
  end
end
