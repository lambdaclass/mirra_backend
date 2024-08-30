defmodule GameBackend.Repo.Migrations.AddHighestHistoricalPrestigeToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :highest_historical_prestige, :integer, default: 0
    end

    execute("""
      UPDATE users u
      SET highest_historical_prestige = (select sum(prestige) from units unit where unit.user_id = u.id)
      where highest_historical_prestige = 0;
    """, "")
  end
end
