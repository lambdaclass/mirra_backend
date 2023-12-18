defmodule DarkWorldsServer.Config.Characters do
  @moduledoc """
  Operations done to the Configuration storage related to Characters.
  """

  import Ecto.Query

  alias DarkWorldsServer.Config.Characters.Character
  alias DarkWorldsServer.Config.Characters.CharacterSkill
  alias DarkWorldsServer.Config.Characters.Effect
  alias DarkWorldsServer.Config.Characters.Projectile
  alias DarkWorldsServer.Config.Characters.ProjectileEffect
  alias DarkWorldsServer.Config.Characters.Skill
  alias DarkWorldsServer.Repo

  ##############
  # Characters #
  ##############

  def insert_character(attrs \\ %{}) do
    %Character{}
    |> Character.changeset(attrs)
    |> Repo.insert()
  end

  def get_character(id), do: Repo.get(Character, id) |> Repo.preload(:skills)

  def get_characters(), do: Repo.all(Character) |> Repo.preload(:skills)

  def get_character_by_name(name), do: Repo.one(from(c in Character, where: c.name == ^name))

  def delete_all_characters(), do: Repo.delete_all(Character)

  def get_character_skill_number(character_id, skill_id),
    do:
      Repo.one(
        from(cs in CharacterSkill,
          where: cs.character_id == ^character_id and cs.skill_id == ^skill_id,
          select: cs.skill_number
        )
      )

  ##########
  # Skills #
  ##########

  def insert_skill(attrs \\ %{}) do
    %Skill{}
    |> Skill.changeset(attrs)
    |> Repo.insert()
  end

  def get_skill(id), do: Repo.get(Skill, id)

  def get_skills(), do: Repo.all(Skill)

  def get_skill_by_name(name), do: Repo.one(from(s in Skill, where: s.name == ^name))

  def delete_all_skills(), do: Repo.delete_all(Skill)

  ###########
  # Effects #
  ###########

  def insert_effect(attrs \\ %{}) do
    %Effect{}
    |> Effect.changeset(attrs)
    |> Repo.insert()
  end

  def get_effect(id), do: Repo.get(Effect, id)

  def get_effects(), do: Repo.all(Effect)

  def get_effect_by_name(name), do: Repo.one(from(e in Effect, where: e.name == ^name))

  def delete_all_effects(), do: Repo.delete_all(Effect)

  ###################
  # CharacterSkills #
  ###################

  def insert_character_skill(attrs \\ %{}) do
    %CharacterSkill{}
    |> CharacterSkill.changeset(attrs)
    |> Repo.insert()
  end

  def delete_all_character_skills(), do: Repo.delete_all(CharacterSkill)

  ###############
  # Projectiles #
  ###############

  def insert_projectile(attrs \\ %{}) do
    %Projectile{}
    |> Projectile.changeset(attrs)
    |> Repo.insert()
  end

  def get_projectile(id), do: Repo.get(Projectile, id) |> Repo.preload(:on_hit_effects)

  def get_projectiles(), do: Repo.all(Projectile) |> Repo.preload(:on_hit_effects)

  def get_projectile_by_name(name),
    do: Repo.one(from(p in Projectile, where: p.name == ^name, preload: :on_hit_effects))

  def delete_all_projectiles(), do: Repo.delete_all(Projectile)

  #####################
  # ProjectileEffects #
  #####################

  def insert_projectile_effect(attrs \\ %{}) do
    %ProjectileEffect{}
    |> ProjectileEffect.changeset(attrs)
    |> Repo.insert()
  end

  def delete_all_projectile_effects(), do: Repo.delete_all(ProjectileEffect)
end
