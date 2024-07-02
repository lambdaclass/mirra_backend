defmodule GameBackend.Units.Skills do
  @moduledoc """
  Operations with skills.
  """

  import Ecto.Query

  alias GameBackend.Units.Skills.Mechanic
  alias GameBackend.Units.Skills.Skill
  alias GameBackend.Repo

  def insert_skill(attrs) do
    %Skill{}
    |> Skill.changeset(attrs)
    |> Repo.insert()
  end

  def update_skill(skill, attrs \\ %{}) do
    skill
    |> Skill.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Inserts all skills into the database.
  If another one already exists with the same name, it updates it instead.
  """
  def upsert_skills(attrs_list) do
    Enum.reduce(attrs_list, Ecto.Multi.new(), fn attrs, multi ->
      # Cannot use Multi.insert because of the embeds_many
      Ecto.Multi.run(multi, attrs.name, fn _, _ ->
        upsert_skill(attrs)
      end)
    end)
    |> Repo.transaction()
  end

  def get_skill_by_name(skill_name) do
    Repo.one(
      from(s in Skill, where: s.name == ^skill_name, preload: [mechanics: [:apply_effects_to, :passive_effects]])
    )
  end

  def upsert_skill(attrs) do
    case get_skill_by_name(attrs.name) do
      nil -> insert_skill(attrs)
      skill -> update_skill(skill, attrs)
    end
  end

  def get_mechanic_detail(mechanic) do
    Enum.find_value(Map.keys(mechanic), fn detail_type ->
      detail_type in Mechanic.mechanic_types() and mechanic[detail_type] != nil
    end)
  end

  def list_curse_skills() do
    curse_id = GameBackend.Utils.get_game_id(:curse_of_mirra)

    q =
      from(s in Skill,
        where: ^curse_id == s.game_id,
        preload: [mechanics: [:on_arrival_mechanic, :on_explode_mechanic]]
      )

    Repo.all(q)
  end

  @doc """
  Gets a single skill.

  Raises `Ecto.NoResultsError` if the Skill does not exist.

  ## Examples

      iex> get_skill!(123)
      %Skill{}

      iex> get_skill!(456)
      ** (Ecto.NoResultsError)

  """
  def get_skill!(id) do
    Repo.get!(Skill, id)
    |> Repo.preload(mechanics: [:on_arrival_mechanic, :on_explode_mechanic])
  end

  @doc """
  Deletes a skill.

  ## Examples

      iex> delete_skill(skill)
      {:ok, %Skill{}}

      iex> delete_skill(skill)
      {:error, %Ecto.Changeset{}}

  """
  def delete_skill(%Skill{} = skill) do
    Repo.delete(skill)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking skill changes.

  ## Examples

      iex> change_skill(skill)
      %Ecto.Changeset{data: %Skill{}}

  """
  def change_skill(%Skill{} = skill, attrs \\ %{}) do
    Skill.changeset(skill, attrs)
  end
end
