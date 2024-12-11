defmodule ConfiguratorWeb.VersionController do
  use ConfiguratorWeb, :controller
  # import Ecto.Query
  alias ConfiguratorWeb.MapConfigurationController

  alias GameBackend.Configuration
  alias GameBackend.Configuration.Version

  def index(conn, _params) do
    versions = Configuration.list_versions()
    render(conn, :index, versions: versions)
  end

  def new(conn, _params) do
    config = Arena.Configuration.get_game_config()
    map_params = config.map
    _changeset = Configuration.change_version(%Version{})
    skills = GameBackend.Units.Skills.list_curse_skills() |> Enum.group_by(& &1.type)
    # list_all_version_settings
    # version_q = from v in GameBackend.Configuration.Version, order_by: [{:desc, :inserted_at}], limit: 1, select: v.id
    # version_q = from v in GameBackend.Configuration.Version, order_by: [{:desc, :inserted_at}], limit: 1, preload: [:characters, :consumable_items, :game_configuration, :map_configurations, skills: [:effect_to_apply, mechanics: [:on_arrival_mechanic, :on_explode_mechanics]]]
    # last_version = GameBackend.Repo.one(version_q)
    last_version = GameBackend.Configuration.get_current_version()

    params =
      Map.from_struct(last_version)
      # Enum.map(last_version.characters, fn c -> Map.from_struct(c) end))
      |> Map.put(:characters, schema_to_map(last_version.characters))
      # Enum.map(last_version.consumable_items, fn c -> Map.from_struct(c) end))
      |> Map.put(:consumable_items, schema_to_map(last_version.consumable_items))
      |> Map.put(:game_configuration, schema_to_map(last_version.game_configuration))
      # Enum.map(last_version.map_configurations, fn c -> Map.from_struct(c) end))
      |> Map.put(:map_configurations, [map_params])
      # Enum.map(last_version.skills, fn c -> Map.from_struct(c) end))
      |> Map.put(:skills, schema_to_map(last_version.skills))

    changeset = Configuration.change_version(%Version{}, params)
    # characters_q = from c in GameBackend.Units.Characters.Character, where: c.version_id == ^last_version_id
    # characters = GameBackend.Repo.all(characters_q)
    # consumable_items_q = from ci in GameBackend.Items.ConsumableItem, where: ci.version_id == ^last_version_id
    # consumable_items = GameBackend.Repo.all(consumable_items_q)
    # skills_q = from s in GameBackend.Units.Skills.Skill, where: s.version_id == ^last_version_id
    # skills = GameBackend.Repo.all(skills_q)
    # game_configurations_q = from gc in GameBackend.CurseOfMirra.GameConfiguration, where: gc.version_id == ^last_version_id
    # game_configurations = GameBackend.Repo.all(game_configurations_q)
    # map_configurations_q = from mc in GameBackend.CurseOfMirra.MapConfiguration, where: mc.version_id == ^last_version_id
    # map_configurations = GameBackend.Repo.all(map_configurations_q)

    render(conn, :new, changeset: changeset, last_version: last_version, skills: skills)

    # render(conn, :new, changeset: changeset, characters: characters, consumable_items: consumable_items, skills: skills, game_configurations: game_configurations, map_configurations: map_configurations)
  end

  def schema_to_map(%{
        __cardinality__: :many,
        __field__: _,
        __owner__: _
      }) do
    []
  end

  def schema_to_map(%Decimal{} = decimal), do: decimal

  def schema_to_map(%_struct{} = schema) do
    schema
    # Convert the struct to a map
    |> Map.from_struct()
    |> Enum.map(fn {key, value} -> {key, schema_to_map(value)} end)
    # Convert back into a map
    |> Enum.into(%{})
  end

  def schema_to_map(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} -> {key, schema_to_map(value)} end)
    |> Enum.into(%{})
  end

  def schema_to_map(list) when is_list(list) do
    Enum.map(list, &schema_to_map/1)
  end

  def schema_to_map(value), do: value

  def create(conn, %{"version" => version_params} = params) do
    version_params =
      Map.put(
        version_params,
        "map_configurations",
        Enum.map(version_params["map_configurations"], fn {k, map} ->
          %{k => MapConfigurationController.parse_json_params(map)}
          # Enum.map(map, fn {k, v} ->
          #   %{k => MapConfigurationController.parse_json_params(v)}
          # end)
        end)
        |> hd()
      )

    case Configuration.create_version(version_params) do
      {:ok, version} ->
        conn
        |> put_flash(:info, "Version created successfully.")
        |> redirect(to: ~p"/versions/#{version}")

      {:error, %Ecto.Changeset{} = changeset} ->
        last_version = GameBackend.Configuration.get_current_version()
        skills = GameBackend.Units.Skills.list_curse_skills() |> Enum.group_by(& &1.type)

        render(conn, :new, changeset: changeset, last_version: last_version, skills: skills)
        # render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    version = Configuration.get_version!(id)
    render(conn, :show, version: version)
  end

  def edit(conn, %{"id" => id}) do
    version = Configuration.get_version!(id)
    changeset = Configuration.change_version(version)
    render(conn, :edit, version: version, changeset: changeset)
  end

  def update(conn, %{"id" => id, "version" => version_params}) do
    version = Configuration.get_version!(id)

    case Configuration.update_version(version, version_params) do
      {:ok, version} ->
        conn
        |> put_flash(:info, "Version updated successfully.")
        |> redirect(to: ~p"/versions/#{version}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, version: version, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    version = Configuration.get_version!(id)
    {:ok, _version} = Configuration.delete_version(version)

    conn
    |> put_flash(:info, "Version deleted successfully.")
    |> redirect(to: ~p"/versions")
  end

  def mark_as_current(conn, %{"id" => id}) do
    version = Configuration.get_version!(id)

    case Configuration.mark_as_current_version(version) do
      {:ok, _version} ->
        conn
        |> put_flash(:info, "Version marked as current.")
        |> redirect(to: ~p"/versions")

      {:error, _failed_action, _changeset, _changes_so_far} ->
        conn
        |> put_flash(:error, "Failed to mark version as current.")
        |> redirect(to: ~p"/versions")
    end
  end
end
