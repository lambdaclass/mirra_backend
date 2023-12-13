defmodule DarkWorldsServer.Characters do
  alias DarkWorldsServer.Characters.Character
  alias DarkWorldsServer.Characters.CharacterSkill
  alias DarkWorldsServer.Characters.Effect
  alias DarkWorldsServer.Repo
  alias DarkWorldsServer.Characters.Skill

  def insert_character(attrs \\ %{}) do
    %Character{}
    |> Character.changeset(attrs)
    |> Repo.insert()
  end

  def insert_skill(attrs \\ %{}) do
    %Skill{}
    |> Skill.changeset(attrs)
    |> Repo.insert()
  end

  def insert_effect(attrs \\ %{}) do
    %Effect{}
    |> Effect.changeset(attrs)
    |> Repo.insert()
  end

  def insert_character_skill(attrs \\ %{}) do
    %CharacterSkill{}
    |> CharacterSkill.changeset(attrs)
    |> Repo.insert()
  end

  def get_character(id), do: Repo.get(Character, id)

  def get_skill(id), do: Repo.get(Skill, id)

  def get_effect(id), do: Repo.get(Effect, id)

  def get_character_skill(id), do: Repo.get(CharacterSkill, id)

  def delete_all_characters(), do: Repo.delete_all(Character)
  def delete_all_skills(), do: Repo.delete_all(Skill)
  def delete_all_effects(), do: Repo.delete_all(Effect)
  def delete_all_character_skills(), do: Repo.delete_all(CharacterSkill)

  def delete_all() do
    delete_all_characters()
    delete_all_skills()
    delete_all_effects()
    delete_all_character_skills()
  end
end
