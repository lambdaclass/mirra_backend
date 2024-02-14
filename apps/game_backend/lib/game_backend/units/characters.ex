defmodule GameBackend.Units.Characters do
  @moduledoc """
  Operations done to the Configuration storage related to Characters.
  """

  import Ecto.Query
  alias GameBackend.Repo
  alias GameBackend.Units.Characters.Character

  ##############
  # Characters #
  ##############

  def insert_character(attrs \\ %{}) do
    %Character{}
    |> Character.changeset(attrs)
    |> Repo.insert()
  end

  def get_character(id), do: Repo.get(Character, id)

  def get_characters(), do: Repo.all(Character)

  def get_character_by_name(name), do: Repo.one(from(c in Character, where: c.name == ^name))

  def delete_all_characters(), do: Repo.delete_all(Character)
end
