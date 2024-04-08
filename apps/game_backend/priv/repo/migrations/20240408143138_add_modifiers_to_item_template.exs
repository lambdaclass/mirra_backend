defmodule GameBackend.Repo.Migrations.AddModifiersToItemTemplate do
  use Ecto.Migration

  def change do
    alter table(:item_templates) do
      add :modifiers, {:array, :map}
    end
  end
end
