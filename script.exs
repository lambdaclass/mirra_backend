singularity_effect = %{
  name: "singularity",
  remove_on_action: false,
  one_time_application: true,
  allow_multiple_effects: true,
  disabled_outside_pool: true,
  effect_mechanics: [
    %{
      name: "pull",
      force: 25.0,
      effect_delay_ms: 0,
      execute_multiple_times: true
    },
    %{
      name: "damage",
      damage: 15,
      effect_delay_ms: 400,
      execute_multiple_times: true
    }
  ]
}

multi_piercing_shoot = %{
  type:  :multi_shoot,
  angle_between:  120.0,
  amount:  3,
  speed:  0.8,
  duration_ms:  1500,
  remove_on_collision:  false,
  projectile_offset:  100,
  damage:  5,
  radius:  150.0,
  parent_mechanic:  nil,
  on_explode_mechanics:  [
    %{
      name:  "tornado",
      type:  :spawn_pool,
      activation_delay:  250,
      duration_ms:  4000,
      radius:  350.0,
      range:  0.0,
      shape:  :circle,
      vertices:  [],
      effect:  singularity_effect
    }
  ]
}

params = %{
  name:  "uren_ultimate",
  type:  :ultimate,
  cooldown_mechanism:  :time,
  cooldown_ms:  10000,
  execution_duration_ms:  1000,
  activation_delay_ms:  0,
  is_passive:  false,
  autoaim:  true,
  max_autoaim_range:  1200,
  can_pick_destination:  false,
  block_movement:  true,
  mechanics:  [multi_piercing_shoot],
  version_id:  "f1ab2bf2-4cb5-4e9d-9034-44334c7b92a9"
}

changeset = Ecto.Changeset.change(%GameBackend.Units.Skills.Skill{}, params)

GameBackend.Repo.insert(changeset)
