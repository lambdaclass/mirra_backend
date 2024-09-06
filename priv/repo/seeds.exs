alias GameBackend.Units.Skills
alias GameBackend.Units.Skills.Skill
alias GameBackend.{Gacha, Repo, Users, Utils}
alias GameBackend.Campaigns.Rewards.AfkRewardRate
alias GameBackend.Users.{KalineTreeLevel, Upgrade}
alias GameBackend.Units.Characters

curse_of_mirra_id = Utils.get_game_id(:curse_of_mirra)
champions_of_mirra_id = Utils.get_game_id(:champions_of_mirra)

### Champions Currencies

{:ok, _skills} = Champions.Config.import_skill_config()

{:ok, _characters} = Champions.Config.import_character_config()

{:ok, gold_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Gold"})

{:ok, _gems_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Gems"})

{:ok, arcane_crystals_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Arcane Crystals"})

{:ok, hero_souls_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Hero Souls"})

{:ok, summon_scrolls_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Summon Scrolls"})

{:ok, _mystic_scrolls_currency} =
  Users.Currencies.insert_currency(%{
    game_id: champions_of_mirra_id,
    name: "Mystic Summon Scrolls"
  })

{:ok, _4_star_shards_currency} =
  Users.Currencies.insert_currency(%{
    game_id: champions_of_mirra_id,
    name: "4* Shards"
  })

{:ok, _5_star_shards_currency} =
  Users.Currencies.insert_currency(%{
    game_id: champions_of_mirra_id,
    name: "5* Shards"
  })

{:ok, _fertilizer_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Fertilizer"})

{:ok, _supplies_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Supplies"})

{:ok, _blueprints_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Blueprints"})

{:ok, pearls_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Pearls"})

### Curse Currencies

{:ok, _curse_gold} =
  Users.Currencies.insert_currency(%{
    game_id: curse_of_mirra_id,
    name: "Gold"
  })

{:ok, _curse_gems} =
  Users.Currencies.insert_currency(%{
    game_id: curse_of_mirra_id,
    name: "Gems"
  })

{:ok, _curse_feature_tokens} =
  Users.Currencies.insert_currency(%{
    game_id: curse_of_mirra_id,
    name: "Feature Tokens"
  })

{:ok, _trophies_currency} =
  Users.Currencies.insert_currency(%{game_id: curse_of_mirra_id, name: "Trophies"})

{:ok, _items} = Champions.Config.import_item_template_config()

{:ok, _} =
  Gacha.insert_box(%{
    name: "Basic Summon",
    rank_weights: [
      %{rank: Champions.Units.get_rank(:star1), weight: 90},
      %{rank: Champions.Units.get_rank(:star2), weight: 70},
      %{rank: Champions.Units.get_rank(:star3), weight: 30},
      %{rank: Champions.Units.get_rank(:star4), weight: 7},
      %{rank: Champions.Units.get_rank(:star5), weight: 3}
    ],
    cost: [%{currency_id: summon_scrolls_currency.id, amount: 1}]
  })

{:ok, _} =
  GameBackend.Gacha.insert_box(%{
    name: "Mystic Summon",
    rank_weights: [
      %{rank: Champions.Units.get_rank(:star3), weight: 75},
      %{rank: Champions.Units.get_rank(:star4), weight: 20},
      %{rank: Champions.Units.get_rank(:star5), weight: 5}
    ],
    cost: [%{currency_id: summon_scrolls_currency.id, amount: 10}]
  })

# TODO: remove these inserts after completing CHoM-#360 (https://github.com/lambdaclass/champions_of_mirra/issues/360)
kaline_tree_levels =
  Enum.map(1..50, fn level_number ->
    %{
      level: level_number,
      fertilizer_level_up_cost: level_number * 100,
      gold_level_up_cost: level_number * 100,
      unlock_features: [],
      inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
  end)

{_, kaline_tree_levels} =
  Repo.insert_all(KalineTreeLevel, kaline_tree_levels, returning: [:id, :level])

seconds_in_day = 86_400

afk_reward_rates =
  Enum.flat_map(Enum.with_index(kaline_tree_levels, 1), fn {level, level_index} ->
    [
      %{
        kaline_tree_level_id: level.id,
        daily_rate: 10.0 * (level_index - 1) * seconds_in_day,
        currency_id: gold_currency.id,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      },
      %{
        kaline_tree_level_id: level.id,
        daily_rate: 2.0 * (level_index - 1) * seconds_in_day,
        currency_id: hero_souls_currency.id,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      },
      %{
        kaline_tree_level_id: level.id,
        daily_rate: 3.0 * (level_index - 1) * seconds_in_day,
        currency_id: arcane_crystals_currency.id,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }
    ]
  end)

Repo.insert_all(AfkRewardRate, afk_reward_rates)

Champions.Config.import_super_campaigns_config()
Champions.Config.import_main_campaign_levels_config()
Champions.Config.import_dungeon_levels_config()

Champions.Config.import_dungeon_settlement_levels_config()

{:ok, _initial_debuff} =
  Repo.insert(
    Upgrade.changeset(%Upgrade{}, %{
      game_id: champions_of_mirra_id,
      name: "Dungeon.BaseSetting",
      description: "This upgrade sets the base settings for the dungeon.",
      group: -1,
      buffs: [
        %{
          modifiers: [
            %{attribute: "max_level", magnitude: 10, operation: "Add"},
            %{attribute: "health", magnitude: 0.1, operation: "Multiply"},
            %{attribute: "attack", magnitude: 0.1, operation: "Multiply"}
          ]
        }
      ]
    })
  )

{:ok, sample_hp_1} =
  Repo.insert(
    Upgrade.changeset(%Upgrade{}, %{
      game_id: champions_of_mirra_id,
      name: "Dungeon.HPUpgrade1",
      description: "This upgrade increases the health of all units by 5%.",
      group: 1,
      cost: [
        %{currency_id: pearls_currency.id, amount: 5}
      ],
      buffs: [
        %{
          modifiers: [
            %{attribute: "health", magnitude: 0.05, operation: "Multiply"}
          ]
        }
      ]
    })
  )

{:ok, _sample_hp_2} =
  Repo.insert(
    Upgrade.changeset(%Upgrade{}, %{
      game_id: champions_of_mirra_id,
      name: "Dungeon.HPUpgrade2",
      description: "This upgrade increases the health of all units by 10%.",
      group: 1,
      cost: [
        %{currency_id: pearls_currency.id, amount: 10}
      ],
      upgrade_dependency_depends_on: [
        %{depends_on_id: sample_hp_1.id}
      ],
      buffs: [
        %{
          modifiers: [
            %{attribute: "health", magnitude: 1.1, operation: "Multiply"}
          ]
        }
      ]
    })
  )

Champions.Config.import_dungeon_levels_config()

##################### CURSE OF MIRRA #####################

default_version_params = %{
  name: "v1.0.0",
  current: true
}

{:ok, version} =
  GameBackend.Configuration.create_version(default_version_params)

## Mechanics
multi_shoot = %{
  "type" => "multi_shoot",
  "angle_between" => 22.0,
  "amount" => 3,
  "speed" => 1.1,
  "duration_ms" => 1000,
  "remove_on_collision" => true,
  "projectile_offset" => 100,
  "damage" => 44,
  "radius" => 40.0
}

singularity = %{
  "type" => "spawn_pool",
  "name" => "singularity",
  "activation_delay" => 400,
  "duration_ms" => 5000,
  "radius" => 450.0,
  "range" => 1200.0,
  "shape" => "circle",
  "vertices" => [],
  "effects_to_apply" => [
    "singularity"
  ]
}

simple_shoot = %{
  "type" => "simple_shoot",
  "speed" => 1.8,
  "duration_ms" => 1100,
  "remove_on_collision" => true,
  "projectile_offset" => 100,
  "radius" => 100.0,
  "damage" => 0,
  "on_explode_mechanics" => [
    %{
      "type" => "circle_hit",
      "damage" => 58,
      "range" => 250.0,
      "offset" => 0
    }
  ],
  "on_collide_effects" => %{
    "apply_effect_to_entity_type" => [
      "pool"
    ],
    "effects" => [
      "buff_singularity"
    ]
  }
}

quickslash_1 = %{
  "type" => "circle_hit",
  "damage" => 60,
  "range" => 350.0,
  "offset" => 400
}

quickslash_2 = %{
  "type" => "circle_hit",
  "damage" => 65,
  "range" => 350.0,
  "offset" => 400
}

quickslash_3 = %{
  "type" => "circle_hit",
  "damage" => 80,
  "range" => 350.0,
  "offset" => 400
}

## Skills
skills = [
  %{
    "name" => "muflus_crush",
    "type" => "basic",
    "cooldown_mechanism" => "stamina",
    "execution_duration_ms" => 450,
    "activation_delay_ms" => 150,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 700,
    "stamina_cost" => 1,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [
      %{
        "type" => "circle_hit",
        "damage" => 64,
        "range" => 350.0,
        "offset" => 400
      }
    ],
    "effects_to_apply" => [],
    "version_id" => version.id
  },
  %{
    "name" => "muflus_leap",
    "type" => "ultimate",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 8000,
    "execution_duration_ms" => 800,
    "activation_delay_ms" => 200,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 1300,
    "can_pick_destination" => true,
    "block_movement" => true,
    "mechanics" => [
      %{
        "type" => "leap",
        "range" => 1300.0,
        "speed" => 1.7,
        "radius" => 600,
        "on_arrival_mechanic" => %{
          "type" => "circle_hit",
          "damage" => 92,
          "range" => 600.0,
          "offset" => 0
        }
      }
    ]
  },
  %{
    "name" => "muflus_dash",
    "type" => "dash",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 4500,
    "execution_duration_ms" => 330,
    "activation_delay_ms" => 0,
    "is_passive" => false,
    "autoaim" => false,
    "max_autoaim_range" => 0,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [
      %{
        "type" => "dash",
        "speed" => 3.3,
        "duration_ms" => 330
      }
    ]
  },
  %{
    "name" => "h4ck_slingshot",
    "type" => "basic",
    "cooldown_mechanism" => "stamina",
    "execution_duration_ms" => 250,
    "activation_delay_ms" => 0,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 1300,
    "stamina_cost" => 1,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [multi_shoot],
    "effects_to_apply" => [],
    "version_id" => version.id
  },
  %{
    "name" => "h4ck_dash",
    "type" => "dash",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 5500,
    "execution_duration_ms" => 250,
    "activation_delay_ms" => 0,
    "is_passive" => false,
    "autoaim" => false,
    "max_autoaim_range" => 0,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [
      %{
        "type" => "dash",
        "speed" => 4.0,
        "duration_ms" => 250
      }
    ]
  },
  %{
    "name" => "h4ck_denial_of_service",
    "type" => "ultimate",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 9000,
    "execution_duration_ms" => 200,
    "activation_delay_ms" => 300,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 1200,
    "can_pick_destination" => true,
    "block_movement" => true,
    "mechanics" => [
      %{
        "type" => "spawn_pool",
        "name" => "denial_of_service",
        "activation_delay" => 250,
        "duration_ms" => 2500,
        "radius" => 500.0,
        "range" => 1200.0,
        "shape" => "circle",
        "vertices" => [],
        "effects_to_apply" => [
          "denial_of_service"
        ]
      }
    ],
    "effects_to_apply" => [],
    "version_id" => version.id
  },
  %{
    "name" => "uma_avenge",
    "type" => "basic",
    "cooldown_mechanism" => "stamina",
    "execution_duration_ms" => 500,
    "activation_delay_ms" => 0,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 650,
    "stamina_cost" => 1,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [
      %{
        "type" => "multi_circle_hit",
        "damage" => 22,
        "range" => 280.0,
        "interval_ms" => 200,
        "amount" => 3,
        "offset" => 200
      }
    ],
    "effects_to_apply" => [],
    "version_id" => version.id
  },
  %{
    "name" => "uma_veil_radiance",
    "type" => "ultimate",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 9000,
    "execution_duration_ms" => 300,
    "activation_delay_ms" => 150,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 0,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [
      %{
        "type" => "circle_hit",
        "damage" => 80,
        "range" => 800.0,
        "offset" => 0
      }
    ],
    "effects_to_apply" => [
      "invisible"
    ]
  },
  %{
    "name" => "uma_sneak",
    "type" => "dash",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 5000,
    "execution_duration_ms" => 250,
    "activation_delay_ms" => 0,
    "is_passive" => false,
    "autoaim" => false,
    "max_autoaim_range" => 0,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [
      %{
        "type" => "dash",
        "speed" => 4.0,
        "duration_ms" => 250
      }
    ],
    "effects_to_apply" => [],
    "version_id" => version.id
  },
  %{
    "name" => "valt_singularity",
    "type" => "ultimate",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 9000,
    "execution_duration_ms" => 500,
    "activation_delay_ms" => 300,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 1200,
    "can_pick_destination" => true,
    "block_movement" => true,
    "mechanics" => [singularity],
    "effects_to_apply" => [],
    "version_id" => version.id
  },
  %{
    "name" => "valt_warp",
    "type" => "dash",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 6000,
    "execution_duration_ms" => 450,
    "inmune_while_executing" => true,
    "activation_delay_ms" => 300,
    "is_passive" => false,
    "autoaim" => false,
    "max_autoaim_range" => 0,
    "can_pick_destination" => true,
    "block_movement" => true,
    "stamina_cost" => 1,
    "mechanics" => [
      %{
        "type" => "teleport",
        "range" => 1100,
        "duration_ms" => 150
      }
    ],
    "effects_to_apply" => [],
    "version_id" => version.id
  },
  %{
    "name" => "valt_antimatter",
    "type" => "basic",
    "cooldown_mechanism" => "stamina",
    "execution_duration_ms" => 450,
    "activation_delay_ms" => 150,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 1300,
    "stamina_cost" => 1,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [simple_shoot],
    "effects_to_apply" => [],
    "version_id" => version.id
  },
  %{
    "name" => "kenzu_quickslash",
    "type" => "basic",
    "cooldown_mechanism" => "stamina",
    "reset_combo_ms" => 0,
    "is_combo?" => true,
    "execution_duration_ms" => 350,
    "activation_delay_ms" => 150,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 700,
    "stamina_cost" => 1,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [quickslash_1],
    "effects_to_apply" => [],
    "version_id" => version.id
  },
  %{
    "name" => "kenzu_quickslash_second",
    "type" => "basic",
    "cooldown_mechanism" => "stamina",
    "reset_combo_ms" => 800,
    "is_combo?" => true,
    "execution_duration_ms" => 450,
    "activation_delay_ms" => 100,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 700,
    "stamina_cost" => 1,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [quickslash_2],
    "effects_to_apply" => [],
    "version_id" => version.id
  },
  %{
    "name" => "kenzu_quickslash_third",
    "type" => "basic",
    "cooldown_mechanism" => "stamina",
    "reset_combo_ms" => 800,
    "is_combo?" => true,
    "execution_duration_ms" => 800,
    "activation_delay_ms" => 100,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 700,
    "stamina_cost" => 1,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [quickslash_3],
    "effects_to_apply" => [],
    "version_id" => version.id
  },
  %{
    "name" => "kenzu_whirlwind",
    "type" => "ultimate",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 9000,
    "execution_duration_ms" => 5000,
    "activation_delay_ms" => 0,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 0,
    "can_pick_destination" => false,
    "block_movement" => false,
    "mechanics" => [
      %{
        "type" => "multi_circle_hit",
        "damage" => 50,
        "range" => 300.0,
        "interval_ms" => 500,
        "duration_ms" => 5000,
        "offset" => 0
      }
    ],
    "effects_to_apply" => [
      "whirlwind"
    ],
    "version_id" => version.id
  },
  %{
    "name" => "kenzu_pounce",
    "type" => "dash",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 5000,
    "execution_duration_ms" => 250,
    "activation_delay_ms" => 0,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 1300,
    "can_pick_destination" => true,
    "block_movement" => true,
    "mechanics" => [
      %{
        "type" => "leap",
        "range" => 1300.0,
        "speed" => 1.7,
        "radius" => 600,
        "on_arrival_mechanic" => %{}
      }
    ],
    "effects_to_apply" => [],
    "version_id" => version.id
  },
  %{
    "name" => "otix_carbonthrow",
    "type" => "basic",
    "cooldown_mechanism" => "stamina",
    "execution_duration_ms" => 450,
    "activation_delay_ms" => 150,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 1400,
    "stamina_cost" => 1,
    "can_pick_destination" => true,
    "block_movement" => true,
    "mechanics" => [
      %{
        "type" => "simple_shoot",
        "speed" => 1.8,
        "duration_ms" => 0,
        "remove_on_collision" => false,
        "projectile_offset" => 0,
        "radius" => 250.0,
        "damage" => 0,
        "range" => 700,
        "on_explode_mechanics" => [
          %{
            "type" => "circle_hit",
            "damage" => 58,
            "range" => 250.0,
            "offset" => 0
          }
        ]
      }
    ],
    "effects_to_apply" => []
  },
  %{
    "name" => "otix_magma_rush",
    "type" => "dash",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 5500,
    "execution_duration_ms" => 250,
    "activation_delay_ms" => 0,
    "is_passive" => false,
    "autoaim" => false,
    "max_autoaim_range" => 0,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [
      %{
        "type" => "dash",
        "speed" => 4.0,
        "duration_ms" => 250
      }
    ]
  },
  %{
    "name" => "otix_inferno",
    "type" => "ultimate",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 10000,
    "execution_duration_ms" => 1000,
    "activation_delay_ms" => 0,
    "is_passive" => false,
    "autoaim" => false,
    "max_autoaim_range" => 0,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [
      %{
        "name" => "inferno",
        "type" => "spawn_pool",
        "activation_delay" => 250,
        "duration_ms" => 8000,
        "radius" => 400.0,
        "range" => 0.0,
        "shape" => "circle",
        "vertices" => [],
        "effects_to_apply" => [
          "inferno"
        ]
      }
    ]
  }
]

skills =
  Enum.map(skills, fn skill_params ->
    {:ok, skill} =
      Map.put(skill_params, "game_id", curse_of_mirra_id)
      |> Skills.insert_skill()

    {skill.name, skill.id}
  end)
  |> Map.new()

# Associate combo skills
_combo_skills =
  [
    {"kenzu_quickslash", "kenzu_quickslash_second"},
    {"kenzu_quickslash_second", "kenzu_quickslash_third"}
  ]
  |> Enum.each(fn {skill, next_skill} ->
    Repo.get(Skill, skills[skill])
    |> Skills.update_skill(%{next_skill_id: skills[next_skill]})
  end)

# Characters params
muflus_params = %{
  name: "muflus",
  active: true,
  base_speed: 0.63,
  base_size: 110.0,
  base_health: 440,
  base_stamina: 3,
  stamina_interval: 2000,
  max_inventory_size: 1,
  natural_healing_interval: 1000,
  natural_healing_damage_interval: 3500,
  basic_skill_id: skills["muflus_crush"],
  ultimate_skill_id: skills["muflus_leap"],
  dash_skill_id: skills["muflus_dash"],
  base_mana: 100,
  initial_mana: 50,
  mana_recovery_strategy: "time",
  mana_recovery_time_interval_ms: 1000,
  mana_recovery_time_amount: 10,
  version_id: version.id
}

h4ck_params = %{
  name: "h4ck",
  active: true,
  base_speed: 0.7,
  base_size: 90.0,
  base_health: 400,
  base_stamina: 3,
  stamina_interval: 1800,
  max_inventory_size: 1,
  natural_healing_interval: 1000,
  natural_healing_damage_interval: 3500,
  basic_skill_id: skills["h4ck_slingshot"],
  ultimate_skill_id: skills["h4ck_denial_of_service"],
  dash_skill_id: skills["h4ck_dash"],
  base_mana: 100,
  initial_mana: 50,
  mana_recovery_strategy: "time",
  mana_recovery_time_interval_ms: 1000,
  mana_recovery_time_amount: 10,
  version_id: version.id
}

uma_params = %{
  name: "uma",
  active: true,
  base_speed: 0.67,
  base_size: 95.0,
  base_health: 400,
  base_stamina: 3,
  stamina_interval: 2000,
  max_inventory_size: 1,
  natural_healing_interval: 1000,
  natural_healing_damage_interval: 3500,
  basic_skill_id: skills["uma_avenge"],
  ultimate_skill_id: skills["uma_veil_radiance"],
  dash_skill_id: skills["uma_sneak"],
  base_mana: 100,
  initial_mana: 50,
  mana_recovery_strategy: "time",
  mana_recovery_time_interval_ms: 1000,
  mana_recovery_time_amount: 10,
  version_id: version.id
}

valtimer_params = %{
  name: "valtimer",
  active: true,
  base_speed: 0.68,
  base_size: 100.0,
  base_health: 400,
  base_stamina: 3,
  stamina_interval: 2000,
  max_inventory_size: 1,
  natural_healing_interval: 1000,
  natural_healing_damage_interval: 3500,
  basic_skill_id: skills["valt_antimatter"],
  ultimate_skill_id: skills["valt_singularity"],
  dash_skill_id: skills["valt_warp"],
  base_mana: 100,
  initial_mana: 50,
  mana_recovery_strategy: "time",
  mana_recovery_time_interval_ms: 1000,
  mana_recovery_time_amount: 10,
  version_id: version.id
}

kenzu_params = %{
  name: "kenzu",
  active: false,
  base_speed: 1,
  base_size: 100.0,
  base_health: 400,
  base_stamina: 3,
  stamina_interval: 2000,
  max_inventory_size: 1,
  natural_healing_interval: 1000,
  natural_healing_damage_interval: 3500,
  basic_skill_id: skills["kenzu_quickslash"],
  ultimate_skill_id: skills["kenzu_whirlwind"],
  dash_skill_id: skills["kenzu_pounce"],
  base_mana: 100,
  initial_mana: 50,
  mana_recovery_strategy: "time",
  mana_recovery_time_interval_ms: 1000,
  mana_recovery_time_amount: 10,
  version_id: version.id
}

otix_params = %{
  name: "otix",
  active: false,
  base_speed: 0.68,
  base_size: 100.0,
  base_health: 400,
  base_stamina: 3,
  stamina_interval: 2000,
  max_inventory_size: 1,
  natural_healing_interval: 1000,
  natural_healing_damage_interval: 3500,
  basic_skill_id: skills["otix_carbonthrow"],
  ultimate_skill_id: skills["otix_inferno"],
  dash_skill_id: skills["otix_magma_rush"],
  version_id: version.id
}

# Insert characters
[muflus_params, h4ck_params, uma_params, valtimer_params, kenzu_params, otix_params]
|> Enum.each(fn char_params ->
  Map.put(char_params, :game_id, curse_of_mirra_id)
  |> Map.put(:faction, "none")
  |> Characters.insert_character()
end)

game_configuration_1 = %{
  tick_rate_ms: 30,
  bounty_pick_time_ms: 0,
  start_game_time_ms: 5000,
  end_game_interval_ms: 1000,
  shutdown_game_wait_ms: 10000,
  natural_healing_interval_ms: 300,
  zone_shrink_start_ms: 35000,
  zone_shrink_radius_by: 10,
  zone_shrink_interval: 100,
  zone_stop_interval_ms: 13000,
  zone_start_interval_ms: 20000,
  zone_damage_interval_ms: 1000,
  zone_damage: 40,
  item_spawn_interval_ms: 7500,
  bots_enabled: true,
  zone_enabled: true,
  bounties_options_amount: 3,
  match_timeout_ms: 300_000,
  field_of_view_inside_bush: 400,
  version_id: version.id,
  time_visible_in_bush_after_skill: 2000,
  distance_to_power_up: 400,
  power_up_damage_modifier: 0.08,
  power_up_health_modifier: 0.08,
  power_up_radius: 200.0,
  power_up_activation_delay_ms: 500,
  power_ups_per_kill: [
    %{
      minimum_amount_of_power_ups: 0,
      amount_of_power_ups_to_drop: 1
    },
    %{
      minimum_amount_of_power_ups: 2,
      amount_of_power_ups_to_drop: 2
    },
    %{
      minimum_amount_of_power_ups: 6,
      amount_of_power_ups_to_drop: 3
    }
  ]
}

{:ok, _game_configuration_1} =
  GameBackend.Configuration.create_game_configuration(game_configuration_1)

golden_clock_params = %{
  active: true,
  name: "golden_clock",
  radius: 200.0,
  mechanics: %{},
  effects: ["golden_clock_effect"],
  version_id: version.id
}

{:ok, _golden_clock} =
  GameBackend.Items.create_consumable_item(golden_clock_params)

magic_boots_params = %{
  active: true,
  name: "magic_boots",
  radius: 200.0,
  mechanics: %{},
  effects: ["magic_boots_effect"],
  version_id: version.id
}

{:ok, _magic_boots} =
  GameBackend.Items.create_consumable_item(magic_boots_params)

mirra_blessing_params = %{
  active: true,
  name: "mirra_blessing",
  radius: 200.0,
  mechanics: %{},
  effects: ["mirra_blessing_effect"],
  version_id: version.id
}

{:ok, _mirra_blessing} =
  GameBackend.Items.create_consumable_item(mirra_blessing_params)

giant_fruit_params = %{
  active: true,
  name: "giant",
  radius: 200.0,
  mechanics: %{},
  effects: ["giant_effect"],
  version_id: version.id
}

{:ok, _giant_fruit} =
  GameBackend.Items.create_consumable_item(giant_fruit_params)

polymorph_params = %{
  active: false,
  name: "polymorph",
  radius: 200.0,
  mechanics: %{},
  effects: ["polymorph_effect"]
}

{:ok, _polymorph} =
  GameBackend.Items.create_consumable_item(polymorph_params)

araban_map_config = %{
  name: "Araban",
  radius: 5520.0,
  active: true,
  initial_positions: [
    %{
      x: 5400,
      y: -400.0
    },
    %{
      x: -5300,
      y: 400.0
    },
    %{
      x: 1100,
      y: 5100
    },
    %{
      x: 3200,
      y: -4300
    },
    %{
      x: -3400,
      y: 3600
    },
    %{
      x: -1900,
      y: -5100
    },
    %{
      x: 4200,
      y: 3200
    }
  ],
  obstacles: [
    %{
      name: "sand_cascade",
      radius: 365.55,
      shape: "circle",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: -3998.0,
        y: 3939.0
      },
      vertices: []
    },
    %{
      name: "right_center_spikes",
      radius: 0.0,
      shape: "polygon",
      type: :dynamic,
      base_status: "underground",
      statuses_cycle: %{
        "raised" => %{
          "make_obstacle_collisionable" => true,
          "next_status" => "underground",
          "on_activation_mechanics" => %{
            "polygon_hit" => %{
              "damage" => 10,
              "vertices" => [
                %{"x" => 2967.0, "y" => 1374.0},
                %{"x" => 2709.0, "y" => 1163.0},
                %{"x" => 4041.0, "y" => -378.0},
                %{"x" => 4283.0, "y" => -190.0}
              ]
            }
          },
          "time_until_transition_ms" => 2000,
          "transition_time_ms" => 3000
        },
        "underground" => %{
          "make_obstacle_collisionable" => false,
          "next_status" => "raised",
          "on_activation_mechanics" => %{},
          "time_until_transition_ms" => 2000,
          "transition_time_ms" => 3000
        }
      },
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 2967.0,
          y: 1374.0
        },
        %{
          x: 2709.0,
          y: 1163.0
        },
        %{
          x: 4041.0,
          y: -378.0
        },
        %{
          x: 4283.0,
          y: -190.0
        }
      ]
    },
    %{
      name: "left_bottom_spikes",
      radius: 0.0,
      shape: "polygon",
      type: :dynamic,
      base_status: "underground",
      statuses_cycle: %{
        "raised" => %{
          "make_obstacle_collisionable" => true,
          "next_status" => "underground",
          "on_activation_mechanics" => %{
            "polygon_hit" => %{
              "damage" => 10,
              "vertices" => [
                %{"x" => -2012.0, "y" => -1905.0},
                %{"x" => -1896.0, "y" => -2200},
                %{"x" => -670.0, "y" => -1343.0},
                %{"x" => -910.0, "y" => -1087.0}
              ]
            }
          },
          "time_until_transition_ms" => 2000,
          "transition_time_ms" => 3000
        },
        "underground" => %{
          "make_obstacle_collisionable" => false,
          "next_status" => "raised",
          "on_activation_mechanics" => %{},
          "time_until_transition_ms" => 2000,
          "transition_time_ms" => 3000
        }
      },
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -2012.0,
          y: -1905.0
        },
        %{
          x: -1896.0,
          y: -2200
        },
        %{
          x: -670.0,
          y: -1343.0
        },
        %{
          x: -910.0,
          y: -1087.0
        }
      ]
    },
    %{
      name: "right_bottom_spikes",
      radius: 0.0,
      shape: "polygon",
      type: :dynamic,
      base_status: "underground",
      statuses_cycle: %{
        "raised" => %{
          "make_obstacle_collisionable" => true,
          "next_status" => "underground",
          "on_activation_mechanics" => %{
            "polygon_hit" => %{
              "damage" => 10,
              "vertices" => [
                %{"x" => 120.0, "y" => -1281.0},
                %{"x" => 1785.0, "y" => -2107.0},
                %{"x" => 1599.0, "y" => -2387.0},
                %{"x" => -59.0, "y" => -1577.0}
              ]
            }
          },
          "time_until_transition_ms" => 2000,
          "transition_time_ms" => 3000
        },
        "underground" => %{
          "make_obstacle_collisionable" => false,
          "next_status" => "raised",
          "on_activation_mechanics" => %{},
          "time_until_transition_ms" => 2000,
          "transition_time_ms" => 3000
        }
      },
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 120.0,
          y: -1281.0
        },
        %{
          x: 1785.0,
          y: -2107.0
        },
        %{
          x: 1599.0,
          y: -2387.0
        },
        %{
          x: -59.0,
          y: -1577.0
        }
      ]
    },
    %{
      name: "left_center_spikes",
      radius: 0.0,
      shape: "polygon",
      type: :dynamic,
      base_status: "underground",
      statuses_cycle: %{
        "raised" => %{
          "make_obstacle_collisionable" => true,
          "next_status" => "underground",
          "on_activation_mechanics" => %{
            "polygon_hit" => %{
              "damage" => 10,
              "vertices" => [
                %{"x" => -3836.0, "y" => 1192.0},
                %{"x" => -3140.0, "y" => 157.0},
                %{"x" => -3488.0, "y" => -43.0},
                %{"x" => -4171.0, "y" => 1001.0}
              ]
            }
          },
          "time_until_transition_ms" => 2000,
          "transition_time_ms" => 3000
        },
        "underground" => %{
          "make_obstacle_collisionable" => false,
          "next_status" => "raised",
          "on_activation_mechanics" => %{},
          "time_until_transition_ms" => 2000,
          "transition_time_ms" => 3000
        }
      },
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -3836.0,
          y: 1192.0
        },
        %{
          x: -3140.0,
          y: 157.0
        },
        %{
          x: -3488.0,
          y: -43.0
        },
        %{
          x: -4171.0,
          y: 1001.0
        }
      ]
    },
    %{
      name: "top_center_spikes",
      radius: 0.0,
      shape: "polygon",
      type: :dynamic,
      base_status: "underground",
      statuses_cycle: %{
        "raised" => %{
          "make_obstacle_collisionable" => true,
          "next_status" => "underground",
          "on_activation_mechanics" => %{
            "polygon_hit" => %{
              "damage" => 10,
              "vertices" => [
                %{"x" => -1280.0, "y" => 2965.0},
                %{"x" => 723.0, "y" => 3165.0},
                %{"x" => 780.0, "y" => 2826.0},
                %{"x" => -1245.0, "y" => 2610.0}
              ]
            }
          },
          "time_until_transition_ms" => 2000,
          "transition_time_ms" => 3000
        },
        "underground" => %{
          "make_obstacle_collisionable" => false,
          "next_status" => "raised",
          "on_activation_mechanics" => %{},
          "time_until_transition_ms" => 2000,
          "transition_time_ms" => 3000
        }
      },
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -1280.0,
          y: 2965.0
        },
        %{
          x: 723.0,
          y: 3165.0
        },
        %{
          x: 780.0,
          y: 2826.0
        },
        %{
          x: -1245.0,
          y: 2610.0
        }
      ]
    },
    %{
      name: "middle stone south",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -956.0,
          y: -779.0
        },
        %{
          x: -761.0,
          y: -727.0
        },
        %{
          x: 219.0,
          y: -1232.0
        },
        %{
          x: 105.0,
          y: -1632.0
        },
        %{
          x: -503.0,
          y: -1416.0
        },
        %{
          x: -995.0,
          y: -989.0
        }
      ]
    },
    %{
      name: "middle stone north",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -415.0,
          y: 1413.0
        },
        %{
          x: -459.0,
          y: 1789.0
        },
        %{
          x: 135.0,
          y: 1871.0
        },
        %{
          x: 794.0,
          y: 1716.0
        },
        %{
          x: 769.0,
          y: 1495.0
        }
      ]
    },
    %{
      name: "carapace 1",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -1674.0,
          y: 2991.0
        },
        %{
          x: -1428.0,
          y: 3051.0
        },
        %{
          x: -1222.0,
          y: 2894.0
        },
        %{
          x: -1180.0,
          y: 2572.0
        },
        %{
          x: -1575.0,
          y: 2018.0
        },
        %{
          x: -2335.0,
          y: 1667.0
        },
        %{
          x: -2661.0,
          y: 2136.0
        },
        %{
          x: -2450.0,
          y: 2536.0
        }
      ]
    },
    %{
      name: "carapace 2",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 2758.0,
          y: -1822.0
        },
        %{
          x: 2887.0,
          y: -2198.0
        },
        %{
          x: 2523.0,
          y: -2600
        },
        %{
          x: 1916.0,
          y: -3018.0
        },
        %{
          x: 1635.0,
          y: -3016.0
        },
        %{
          x: 1402.0,
          y: -2822.0
        },
        %{
          x: 1386.0,
          y: -2557.0
        },
        %{
          x: 1728.0,
          y: -2034.0
        },
        %{
          x: 2411.0,
          y: -1668.0
        }
      ]
    },
    %{
      name: "lava rock 1 a",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 3421.0,
          y: -1034.0
        },
        %{
          x: 3230.0,
          y: -759.0
        },
        %{
          x: 3646.0,
          y: -726.0
        },
        %{
          x: 3970.0,
          y: -1079.0
        }
      ]
    },
    %{
      name: "lava rock 1 b",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 3970.0,
          y: -1079.0
        },
        %{
          x: 3646.0,
          y: -726.0
        },
        %{
          x: 4020.0,
          y: -520.0
        },
        %{
          x: 4352.0,
          y: -882.0
        }
      ]
    },
    %{
      name: "lava rock 1 c",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 4352.0,
          y: -882.0
        },
        %{
          x: 4020.0,
          y: -520.0
        },
        %{
          x: 4230.0,
          y: -222.0
        },
        %{
          x: 4600,
          y: -237.0
        },
        %{
          x: 4697.0,
          y: -508.0
        },
        %{
          x: 4352.0,
          y: -882.0
        },
        %{
          x: 4020.0,
          y: -520.0
        }
      ]
    },
    %{
      name: "lava rock 2 a",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -4420.0,
          y: 575.0
        },
        %{
          x: -4663.0,
          y: 661.0
        },
        %{
          x: -4744.0,
          y: 840.0
        },
        %{
          x: -4454.0,
          y: 1279.0
        },
        %{
          x: -4101.0,
          y: 932.0
        }
      ]
    },
    %{
      name: "lava rock 2 b",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -4454.0,
          y: 1279.0
        },
        %{
          x: -3980.0,
          y: 1513.0
        },
        %{
          x: -3852.0,
          y: 1140.0
        },
        %{
          x: -4101.0,
          y: 932.0
        }
      ]
    },
    %{
      name: "lava rock 2 c",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -3980.0,
          y: 1513.0
        },
        %{
          x: -3459.0,
          y: 1473.0
        },
        %{
          x: -3273.0,
          y: 1304.0
        },
        %{
          x: -3322.0,
          y: 1188.0
        },
        %{
          x: -3455.0,
          y: 1163.0
        },
        %{
          x: -3852.0,
          y: 1140.0
        }
      ]
    },
    %{
      name: "cannon rock 1 a",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 470.0,
          y: -4100
        },
        %{
          x: 790.0,
          y: -3950.0
        },
        %{
          x: 1300,
          y: -4450.0
        },
        %{
          x: 1300,
          y: -6500
        },
        %{
          x: 360.0,
          y: -6500
        },
        %{
          x: 360.0,
          y: -4700
        }
      ]
    },
    %{
      name: "cannon rock 1 b",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -770.0,
          y: -5850.0
        },
        %{
          x: 360.0,
          y: -4700
        },
        %{
          x: 1150.0,
          y: -5470.0
        },
        %{
          x: 1150.0,
          y: -8000
        },
        %{
          x: -770.0,
          y: -8000
        }
      ]
    },
    %{
      name: "cannon rock 2 a",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -849.0,
          y: 4252.0
        },
        %{
          x: -1120.0,
          y: 4900
        },
        %{
          x: -1120.0,
          y: 6500
        },
        %{
          x: -135.0,
          y: 6500
        },
        %{
          x: -135.0,
          y: 4836.0
        },
        %{
          x: -439.0,
          y: 4212.0
        }
      ]
    },
    %{
      name: "cannon rock 2 b",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 1226.0,
          y: 5607.0
        },
        %{
          x: -135.0,
          y: 4836.0
        },
        %{
          x: -748.0,
          y: 5674.0
        },
        %{
          x: -748.0,
          y: 6500
        },
        %{
          x: 1226.0,
          y: 6500
        }
      ]
    },
    %{
      name: "halfmoon rock 1 a",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -2511.0,
          y: -2436.0
        },
        %{
          x: -2881.0,
          y: -2496.0
        },
        %{
          x: -2905.0,
          y: -1895.0
        },
        %{
          x: -2542.0,
          y: -1896.0
        },
        %{
          x: -2031.0,
          y: -1935.0
        },
        %{
          x: -1948.0,
          y: -2168.0
        }
      ]
    },
    %{
      name: "halfmoon rock 1 b",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -2881.0,
          y: -2496.0
        },
        %{
          x: -3563.0,
          y: -2312.0
        },
        %{
          x: -3943.0,
          y: -1877.0
        },
        %{
          x: -3206.0,
          y: -1552.0
        },
        %{
          x: -2905.0,
          y: -1895.0
        }
      ]
    },
    %{
      name: "halfmoon rock 1 c",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -3943.0,
          y: -1877.0
        },
        %{
          x: -4089.0,
          y: -1199.0
        },
        %{
          x: -4022.0,
          y: -707.0
        },
        %{
          x: -3355.0,
          y: -1030.0
        },
        %{
          x: -3206.0,
          y: -1552.0
        }
      ]
    },
    %{
      name: "halfmoon rock 1 d",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -4022.0,
          y: -707.0
        },
        %{
          x: -3772.0,
          y: -241.0
        },
        %{
          x: -3376.0,
          y: 92.0
        },
        %{
          x: -3173.0,
          y: -62.0
        },
        %{
          x: -3306.0,
          y: -520.0
        },
        %{
          x: -3355.0,
          y: -1030.0
        }
      ]
    },
    %{
      name: "halfmoon rock 2 a",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 791.0,
          y: 3026.0
        },
        %{
          x: 1259.0,
          y: 3438.0
        },
        %{
          x: 1598.0,
          y: 3597.0
        },
        %{
          x: 1786.0,
          y: 3026.0
        },
        %{
          x: 1436.0,
          y: 2928.0
        },
        %{
          x: 934.0,
          y: 2825.0
        }
      ]
    },
    %{
      name: "halfmoon rock 2 b",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 1598.0,
          y: 3597.0
        },
        %{
          x: 2304.0,
          y: 3607.0
        },
        %{
          x: 2789.0,
          y: 3293.0
        },
        %{
          x: 2169.0,
          y: 2779.0
        },
        %{
          x: 1786.0,
          y: 3026.0
        }
      ]
    },
    %{
      name: "halfmoon rock 2 c",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 2789.0,
          y: 3293.0
        },
        %{
          x: 3115.0,
          y: 2681.0
        },
        %{
          x: 3186.0,
          y: 2190.0
        },
        %{
          x: 2547.0,
          y: 2229.0
        },
        %{
          x: 2169.0,
          y: 2779.0
        }
      ]
    },
    %{
      name: "halfmoon rock 2 d",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 3186.0,
          y: 2190.0
        },
        %{
          x: 3073.0,
          y: 1673.0
        },
        %{
          x: 2783.0,
          y: 1244.0
        },
        %{
          x: 2546.0,
          y: 1337.0
        },
        %{
          x: 2547.0,
          y: 2229.0
        }
      ]
    },
    %{
      name: "wall entry",
      radius: 0.0,
      shape: "polygon",
      type: :static,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -2376.0,
          y: 5248.0
        },
        %{
          x: -2284.0,
          y: 4949.0
        },
        %{
          x: -3078.0,
          y: 3927.0
        },
        %{
          x: -3402.0,
          y: 3897.0
        },
        %{
          x: -5000,
          y: 3897.0
        },
        %{
          x: -5000,
          y: 5248.0
        }
      ]
    },
    %{
      name: "right center water lake",
      radius: 0.0,
      shape: "polygon",
      type: :lake,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 3578.0,
          y: 763.0
        },
        %{
          x: 5389.0,
          y: 2035.0
        },
        %{
          x: 5662.0,
          y: 1243.0
        },
        %{
          x: 3809.0,
          y: 438.0
        }
      ]
    },
    %{
      name: "bottom left water lake SW",
      radius: 0.0,
      shape: "polygon",
      type: :lake,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -1910.0,
          y: -3253.0
        },
        %{
          x: -1616.0,
          y: -3434.0
        },
        %{
          x: -1422.0,
          y: -3827.0
        },
        %{
          x: -1480.0,
          y: -4195.0
        },
        %{
          x: -2125.0,
          y: -4696.0
        },
        %{
          x: -2688.0,
          y: -4563.0
        },
        %{
          x: -2775.0,
          y: -4101.0
        }
      ]
    },
    %{
      name: "bottom left water lake N",
      radius: 0.0,
      shape: "polygon",
      type: :lake,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -1208.0,
          y: -2490.0
        },
        %{
          x: -766.0,
          y: -2513.0
        },
        %{
          x: -493.0,
          y: -3091.0
        },
        %{
          x: -971.0,
          y: -3326.0
        },
        %{
          x: -1378.0,
          y: -3235.0
        },
        %{
          x: -1690.0,
          y: -2961.0
        }
      ]
    },
    %{
      name: "bottom left water lake E",
      radius: 0.0,
      shape: "polygon",
      type: :lake,
      base_status: nil,
      statuses_cycle: %{},
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -976.0,
          y: -3814.0
        },
        %{
          x: -412.0,
          y: -3428.0
        },
        %{
          x: -211.0,
          y: -3714.0
        },
        %{
          x: -176.0,
          y: -4068.0
        },
        %{
          x: -303.0,
          y: -4490.0
        },
        %{
          x: -675.0,
          y: -4734.0
        },
        %{
          x: -1340.0,
          y: -4615.0
        }
      ]
    }
  ],
  bushes: [
    %{
      name: "right edge bushes (b)",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 5238.0,
          y: 2467.0
        },
        %{
          x: 5415.0,
          y: 2076.0
        },
        %{
          x: 4290.0,
          y: 1173.0
        },
        %{
          x: 3967.0,
          y: 1852.0
        }
      ]
    },
    %{
      name: "right edge bushes (a)",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 4290.0,
          y: 1173.0
        },
        %{
          x: 3535.0,
          y: 813.0
        },
        %{
          x: 2917.0,
          y: 1492.0
        },
        %{
          x: 3111.0,
          y: 2031.0
        },
        %{
          x: 3801.0,
          y: 2099.0
        }
      ]
    },
    %{
      name: "right top edge bushes",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 2520.0,
          y: 5142.0
        },
        %{
          x: 3859.0,
          y: 4395.0
        },
        %{
          x: 3347.0,
          y: 2874.0
        },
        %{
          x: 3023.0,
          y: 2888.0
        },
        %{
          x: 1974.0,
          y: 3737.0
        }
      ]
    },
    %{
      name: "top edge bushes",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -73.0,
          y: 5375.0
        },
        %{
          x: 718.0,
          y: 5346.0
        },
        %{
          x: 766.0,
          y: 4681.0
        },
        %{
          x: 131.0,
          y: 4305.0
        },
        %{
          x: -577.0,
          y: 4374.0
        }
      ]
    },
    %{
      name: "top pass bushes",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -1373.0,
          y: 4325.0
        },
        %{
          x: -618.0,
          y: 4398.0
        },
        %{
          x: -1289.0,
          y: 2801.0
        },
        %{
          x: -1733.0,
          y: 2894.0
        },
        %{
          x: -1915.0,
          y: 3307.0
        }
      ]
    },
    %{
      name: "top left edge bushes (a)",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -3489.0,
          y: 1910.0
        },
        %{
          x: -3455.0,
          y: 1348.0
        },
        %{
          x: -4631.0,
          y: 1025.0
        },
        %{
          x: -5581.0,
          y: 1156.0
        },
        %{
          x: -5441.0,
          y: 1743.0
        }
      ]
    },
    %{
      name: "top left edge bushes (b)",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -3653.0,
          y: 1868.0
        },
        %{
          x: -2472.0,
          y: 2223.0
        },
        %{
          x: -2014.0,
          y: 1265.0
        },
        %{
          x: -2667.0,
          y: 760.0
        },
        %{
          x: -3037.0,
          y: 796.0
        }
      ]
    },
    %{
      name: "bottom left edge bushes",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -3973.0,
          y: -1290.0
        },
        %{
          x: -3473.0,
          y: -2191.0
        },
        %{
          x: -5065.0,
          y: -2925.0
        },
        %{
          x: -5532.0,
          y: -1858.0
        }
      ]
    },
    %{
      name: "lake bottom left bushes",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -2568.0,
          y: -3802.0
        },
        %{
          x: -2178.0,
          y: -4690.0
        },
        %{
          x: -2418.0,
          y: -5303.0
        },
        %{
          x: -3883.0,
          y: -4379.0
        },
        %{
          x: -3262.0,
          y: -3809.0
        }
      ]
    },
    %{
      name: "lake bottom right bushes",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -746.0,
          y: -4637.0
        },
        %{
          x: -187.0,
          y: -5021.0
        },
        %{
          x: -167.0,
          y: -5372.0
        },
        %{
          x: -710.0,
          y: -5828.0
        },
        %{
          x: -1697.0,
          y: -5539.0
        },
        %{
          x: -1472.0,
          y: -4731.0
        }
      ]
    },
    %{
      name: "bottom edge bushes",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 1133.0,
          y: -3654.0
        },
        %{
          x: 2193.0,
          y: -4166.0
        },
        %{
          x: 2136.0,
          y: -5482.0
        },
        %{
          x: 1048.0,
          y: -5500
        },
        %{
          x: 521.0,
          y: -4089.0
        },
        %{
          x: 619.0,
          y: -3775.0
        }
      ]
    },
    %{
      name: "with hole in the middle bushes (a)",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 2810.0,
          y: -89.0
        },
        %{
          x: 3636.0,
          y: -63.0
        },
        %{
          x: 3995.0,
          y: -414.0
        },
        %{
          x: 4323.0,
          y: -1052.0
        },
        %{
          x: 2921.0,
          y: -2986.0
        },
        %{
          x: 1832.0,
          y: -1752.0
        },
        %{
          x: 1884.0,
          y: -1261.0
        }
      ]
    },
    %{
      name: "with hole in the middle bushes (b)",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 4289.0,
          y: -1035.0
        },
        %{
          x: 5648.0,
          y: -1995.0
        },
        %{
          x: 5272.0,
          y: -2692.0
        },
        %{
          x: 3706.0,
          y: -1596.0
        }
      ]
    },
    %{
      name: "with hole in the middle bushes (c)",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 4662.0,
          y: -1944.0
        },
        %{
          x: 5431.0,
          y: -2452.0
        },
        %{
          x: 4438.0,
          y: -3902.0
        },
        %{
          x: 3644.0,
          y: -3559.0
        }
      ]
    },
    %{
      name: "with hole in the middle bushes (d)",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 3246.0,
          y: -2469.0
        },
        %{
          x: 4269.0,
          y: -2991.0
        },
        %{
          x: 3795.0,
          y: -3638.0
        },
        %{
          x: 2938.0,
          y: -2976.0
        }
      ]
    },
    %{
      name: "center bottom small bush",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -548.0,
          y: -1302.0
        },
        %{
          x: 9.0,
          y: -1594.0
        },
        %{
          x: -51.0,
          y: -2024.0
        },
        %{
          x: -1038.0,
          y: -1705.0
        }
      ]
    },
    %{
      name: "bottom lake top bush",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -2066.0,
          y: -2114.0
        },
        %{
          x: -1428.0,
          y: -2684.0
        },
        %{
          x: -1711.0,
          y: -3032.0
        },
        %{
          x: -2672.0,
          y: -2426.0
        }
      ]
    },
    %{
      name: "left cave bush",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -2771.0,
          y: -218.0
        },
        %{
          x: -1948.0,
          y: -662.0
        },
        %{
          x: -1762.0,
          y: -1297.0
        },
        %{
          x: -2026.0,
          y: -1982.0
        },
        %{
          x: -3063.0,
          y: -1976.0
        },
        %{
          x: -3514.0,
          y: -437.0
        }
      ]
    },
    %{
      name: "middle top bush",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: -1442.0,
          y: 2139.0
        },
        %{
          x: -1146.0,
          y: 2512.0
        },
        %{
          x: 1373.0,
          y: 2795.0
        },
        %{
          x: 733.0,
          y: 1820.0
        },
        %{
          x: -782.0,
          y: 1710.0
        }
      ]
    },
    %{
      name: "right cave bush (a)",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 1323.0,
          y: 2919.0
        },
        %{
          x: 2363.0,
          y: 3005.0
        },
        %{
          x: 2543.0,
          y: 2427.0
        },
        %{
          x: 1275.0,
          y: 2509.0
        }
      ]
    },
    %{
      name: "right cave bush (b)",
      radius: 0.0,
      shape: "polygon",
      position: %{
        x: 0.0,
        y: 0.0
      },
      vertices: [
        %{
          x: 2072.0,
          y: 2456.0
        },
        %{
          x: 2635.0,
          y: 2413.0
        },
        %{
          x: 2600,
          y: 1198.0
        },
        %{
          x: 1992.0,
          y: 1232.0
        }
      ]
    }
  ],
  crates: [
    %{
      position: %{x: 5500.0, y: 200.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: 3900.0, y: -2300.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: 2400.0, y: -4800.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: -1241.0, y: -3554.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: -4200.0, y: -3500.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: -5400.0, y: -1000.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: -4200.0, y: 3200.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: -1400.0, y: 4600.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: 1300.0, y: 4600.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: 3500.0, y: 2600.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: 1700.0, y: 2200.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: 3000.0, y: 300.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: 1200.0, y: -2600.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: -2500.0, y: -1200.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: -1900.0, y: 1700.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: 100.0, y: 600.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: 700.0, y: -100.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    },
    %{
      position: %{x: -500.0, y: -100.0},
      shape: "circle",
      radius: 150.0,
      health: 250,
      vertices: [],
      amount_of_power_ups: 1,
      power_up_spawn_delay_ms: 300
    }
  ],
  pools: [],
  version_id: version.id
}

merliot_map_config = %{
  name: "Merliot",
  radius: 10000.0,
  active: false,
  initial_positions: [
    %{
      x: 5360.0,
      y: -540.0
    },
    %{
      x: -5130.0,
      y: -920.0
    },
    %{
      x: 555.0,
      y: 4314.0
    },
    %{
      x: 2750.0,
      y: -4200.0
    },
    %{
      x: -3700.0,
      y: 2700.0
    },
    %{
      x: 4250.0,
      y: 3000.0
    },
    %{
      x: -1842.0,
      y: -4505.0
    }
  ],
  obstacles: [
    %{
      name: "East wall",
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      base_status: "",
      statuses_cycle: %{},
      vertices: [
        %{
          x: 6400.0,
          y: 6800.0
        },
        %{
          x: 6800.0,
          y: 6800.0
        },
        %{
          x: 6800.0,
          y: -6800.0
        },
        %{
          x: 6400.0,
          y: -6800.0
        }
      ]
    },
    %{
      name: "North wall",
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      base_status: "",
      statuses_cycle: %{},
      vertices: [
        %{
          x: 6400.0,
          y: 6400.0
        },
        %{
          x: 6400.0,
          y: 6800.0
        },
        %{
          x: -6400.0,
          y: 6800.0
        },
        %{
          x: -6400.0,
          y: 6400.0
        }
      ]
    },
    %{
      name: "West wall",
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      base_status: "",
      statuses_cycle: %{},
      vertices: [
        %{
          x: -6400.0,
          y: 6800.0
        },
        %{
          x: -6800.0,
          y: 6800.0
        },
        %{
          x: -6800.0,
          y: -6800.0
        },
        %{
          x: -6400.0,
          y: -6800.0
        }
      ]
    },
    %{
      name: "South wall",
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      base_status: "",
      statuses_cycle: %{},
      vertices: [
        %{
          x: -6400.0,
          y: -6400.0
        },
        %{
          x: 6400.0,
          y: -6400.0
        },
        %{
          x: 6400.0,
          y: -6800.0
        },
        %{
          x: -6400.0,
          y: -6800.0
        }
      ]
    }
  ],
  bushes: [],
  pools: [],
  version_id: version.id
}

{:ok, _araban_map_configuration} =
  GameBackend.Configuration.create_map_configuration(araban_map_config)

{:ok, _merliot_map_configuration} =
  GameBackend.Configuration.create_map_configuration(merliot_map_config)

GameBackend.CurseOfMirra.Config.import_quest_descriptions_config()

brazil_arena_server =
  %{
    name: "BRAZIL",
    ip: "",
    url: "arena-brazil-testing-aws.championsofmirra.com",
    gateway_url: "https://central-europe-staging.championsofmirra.com",
    status: "active",
    environment: "production"
  }

GameBackend.Configuration.create_arena_server(brazil_arena_server)

europe_arena_server =
  %{
    name: "EUROPE",
    ip: "",
    url: "arena-europe-testing.championsofmirra.com",
    gateway_url: "https://central-europe-staging.championsofmirra.com",
    status: "active",
    environment: "production"
  }

GameBackend.Configuration.create_arena_server(europe_arena_server)

################### END CURSE OF MIRRA ###################
