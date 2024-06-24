defmodule ConfiguratorWeb.UtilsAPI do
  alias Configurator.Configuration

  def list_characters do
    Configuration.list_characters()
    |> Enum.map(fn character ->
      %{
        active: character.active,
        name: character.name,
        base_speed: character.base_speed,
        base_size: character.base_size,
        base_health: character.base_health,
        base_stamina: character.base_stamina,
        max_inventory_size: character.max_inventory_size,
        natural_healing_interval: character.natural_healing_interval,
        natural_healing_damage_interval: character.natural_healing_damage_interval,
        stamina_interval: character.stamina_interval,
        skills: character.skills
      }
    end)
  end
end
