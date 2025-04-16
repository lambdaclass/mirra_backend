alias GameBackend.Units.Skills
alias GameBackend.Units.Skills.Skill
alias GameBackend.{Gacha, Repo, Users, Utils}
alias GameBackend.Campaigns.Rewards.AfkRewardRate
alias GameBackend.Users.{KalineTreeLevel, Upgrade}
alias GameBackend.Units.Characters

curse_of_mirra_id = Utils.get_game_id(:curse_of_mirra)
champions_of_mirra_id = Utils.get_game_id(:champions_of_mirra)

### Champions Currencies

{:ok, _skills} = Champions.Config.import_skill_config(champions_of_mirra_id)

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

singularity_effect = %{
  name: "singularity",
  remove_on_action: false,
  one_time_application: true,
  allow_multiple_effects: true,
  disabled_outside_pool: true,
  effect_mechanics: [
    %{
      name: "pull",
      force: 15.0,
      effect_delay_ms: 0,
      execute_multiple_times: true
    },
    %{
      name: "damage",
      damage: 25,
      effect_delay_ms: 400,
      execute_multiple_times: true
    }
  ]
}

denial_of_service =
  %{
    name: "denial_of_service",
    remove_on_action: false,
    one_time_application: true,
    allow_multiple_effects: true,
    disabled_outside_pool: true,
    effect_mechanics: [
      %{
        name: "damage",
        damage: 25,
        effect_delay_ms: 220,
        execute_multiple_times: true
      }
    ]
  }

invisible_effect =
  %{
    name: "invisible",
    duration_ms: 5000,
    remove_on_action: true,
    one_time_application: false,
    allow_multiple_effects: true,
    disabled_outside_pool: true,
    effect_mechanics: [
      %{
        name: "invisible",
        execute_multiple_times: true,
        effect_delay_ms: 0
      },
      %{
        name: "speed_boost",
        modifier: 0.3,
        effect_delay_ms: 0,
        execute_multiple_times: false
      }
    ]
  }

whirlwind_effect =
  %{
    name: "whirlwind",
    duration_ms: 5000,
    remove_on_action: false,
    one_time_application: true,
    allow_multiple_effects: true,
    disabled_outside_pool: true,
    effect_mechanics: [
      %{
        name: "pull_immunity",
        effect_delay_ms: 0,
        execute_multiple_times: false
      },
      %{
        name: "speed_boost",
        modifier: 0.2,
        effect_delay_ms: 0,
        execute_multiple_times: false
      }
    ]
  }

_buff_singularity_effect =
  %{
    name: "buff_singularity",
    remove_on_action: false,
    one_time_application: true,
    consume_projectile: true,
    allow_multiple_effects: true,
    disabled_outside_pool: true,
    effect_mechanics: [
      %{
        name: "buff_pool",
        stat_multiplier: 0.1,
        additive_duration_add_ms: 1000,
        effect_delay_ms: 0,
        execute_multiple_times: false
      }
    ]
  }

inferno_effect = %{
  name: "inferno",
  remove_on_action: false,
  one_time_application: true,
  allow_multiple_effects: true,
  disabled_outside_pool: true,
  effect_mechanics: [
    %{
      name: "speed_boost",
      modifier: -0.60,
      effect_delay_ms: 0,
      execute_multiple_times: false
    },
    %{
      name: "damage",
      damage: 25,
      effect_delay_ms: 400,
      execute_multiple_times: true
    }
  ]
}

toxic_onion_effect = %{
  name: "toxic_onion",
  remove_on_action: false,
  duration_ms: 3000,
  one_time_application: false,
  allow_multiple_effects: true,
  disabled_outside_pool: false,
  effect_mechanics: [
    %{
      name: "damage",
      damage: 10,
      effect_delay_ms: 1000,
      execute_multiple_times: true
    }
  ]
}

peb_effect = %{
  name: "putrid_elixir_bomb",
  remove_on_action: false,
  duration_ms: 4000,
  one_time_application: true,
  allow_multiple_effects: true,
  disabled_outside_pool: false,
  effect_mechanics: [
    %{
      name: "damage",
      damage: 5,
      effect_delay_ms: 250,
      execute_multiple_times: true
    },
    %{
      name: "damage",
      damage: 60,
      effect_delay_ms: 0,
      execute_multiple_times: false
    }
  ]
}

## Mechanics
multi_shoot = %{
  "type" => "multi_shoot",
  "angle_between" => 22.0,
  "amount" => 3,
  "speed" => 1.1,
  "duration_ms" => 1000,
  "remove_on_collision" => true,
  "projectile_offset" => 100,
  "damage" => 25,
  "radius" => 40.0
}

singularity = %{
  "type" => "spawn_pool",
  "name" => "singularity",
  "activation_delay" => 400,
  "duration_ms" => 5000,
  "radius" => 500.0,
  "range" => 1200.0,
  "shape" => "circle",
  "vertices" => [],
  "effect" => singularity_effect
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
      "damage" => 60,
      "range" => 300.0,
      "offset" => 0
    }
  ]
}

simple_piercing_shoot = %{
  "type" => "simple_shoot",
  "speed" => 0.8,
  "duration_ms" => 2500,
  "remove_on_collision" => false,
  "projectile_offset" => 100,
  "radius" => 150.0,
  "damage" => 4
}

multi_piercing_shoot = %{
  "type" => "multi_shoot",
  "angle_between" => 120.0,
  "amount" => 3,
  "speed" => 0.8,
  "duration_ms" => 1500,
  "remove_on_collision" => false,
  "projectile_offset" => 100,
  "damage" => 5,
  "radius" => 150.0,
  "on_explode_mechanics" => [
    %{
      "name" => "tornado",
      "type" => "spawn_pool",
      "activation_delay" => 250,
      "duration_ms" => 4000,
      "radius" => 350.0,
      "range" => 0.0,
      "shape" => "circle",
      "vertices" => [],
      "effect" => singularity_effect
    }
  ]
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

inferno = %{
  "name" => "inferno",
  "type" => "spawn_pool",
  "activation_delay" => 250,
  "duration_ms" => 8000,
  "radius" => 650.0,
  "range" => 0.0,
  "shape" => "circle",
  "vertices" => [],
  "effect" => inferno_effect
}

toxic_onion_explosion = %{
  "name" => "toxic_onion_explosion",
  "type" => "circle_hit",
  "damage" => 50,
  "range" => 350.0,
  "offset" => 0,
  "effect" => toxic_onion_effect
}

toxic_onion = %{
  "type" => "simple_shoot",
  "speed" => 1.8,
  "duration_ms" => 0,
  "remove_on_collision" => false,
  "projectile_offset" => 0,
  "radius" => 250.0,
  "damage" => 0,
  "range" => 1200,
  "on_explode_mechanics" => [
    toxic_onion_explosion
  ]
}

putrid_elixir_bomb = %{
  "name" => "putrid_elixir_bomb",
  "type" => "spawn_pool",
  "activation_delay" => 250,
  "duration_ms" => 8000,
  "radius" => 650.0,
  "range" => 0.0,
  "shape" => "circle",
  "vertices" => [],
  "effect" => peb_effect
}

spore_dash = %{
  "type" => "dash",
  "speed" => 4.0,
  "duration_ms" => 250
}

otix_carbonthrow_mechanic = %{
  "type" => "simple_shoot",
  "speed" => 1.8,
  "duration_ms" => 0,
  "remove_on_collision" => false,
  "projectile_offset" => 0,
  "radius" => 250.0,
  "damage" => 0,
  "range" => 1200,
  "on_explode_mechanics" => [
    %{
      "type" => "circle_hit",
      "damage" => 60,
      "range" => 350.0,
      "offset" => 0
    }
  ]
}

otix_magma_rush_mechanic = %{
  "type" => "dash",
  "speed" => 2.0,
  "duration_ms" => 750
}

## Skills

skills = [
  %{
    "name" => "muflus_crush",
    "type" => "basic",
    "attack_type" => "melee",
    "cooldown_mechanism" => "stamina",
    "execution_duration_ms" => 350,
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
        "damage" => 55,
        "range" => 350.0,
        "offset" => 400
      }
    ],
    "version_id" => version.id
  },
  %{
    "name" => "muflus_leap",
    "type" => "ultimate",
    "attack_type" => "ranged",
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
          "damage" => 110,
          "range" => 600.0,
          "offset" => 0
        }
      }
    ],
    "version_id" => version.id
  },
  %{
    "name" => "muflus_dash",
    "type" => "dash",
    "attack_type" => "melee",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 4500,
    "execution_duration_ms" => 500,
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
        "duration_ms" => 500
      }
    ],
    "version_id" => version.id
  },
  %{
    "name" => "h4ck_slingshot",
    "type" => "basic",
    "attack_type" => "ranged",
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
    "version_id" => version.id
  },
  %{
    "name" => "h4ck_dash",
    "type" => "dash",
    "attack_type" => "melee",
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
    ],
    "version_id" => version.id
  },
  %{
    "name" => "h4ck_denial_of_service",
    "type" => "ultimate",
    "attack_type" => "ranged",
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
        "effect" => denial_of_service
      }
    ],
    "version_id" => version.id
  },
  %{
    "name" => "uma_avenge",
    "type" => "basic",
    "attack_type" => "melee",
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
        "damage" => 27,
        "range" => 300.0,
        "interval_ms" => 200,
        "amount" => 3,
        "offset" => 200
      }
    ],
    "version_id" => version.id
  },
  %{
    "name" => "uma_veil_radiance",
    "type" => "ultimate",
    "attack_type" => "melee",
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
    "on_owner_effect" => invisible_effect,
    "version_id" => version.id
  },
  %{
    "name" => "uma_sneak",
    "type" => "dash",
    "attack_type" => "melee",
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
    "version_id" => version.id
  },
  %{
    "name" => "valt_singularity",
    "type" => "ultimate",
    "attack_type" => "ranged",
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
    "version_id" => version.id
  },
  %{
    "name" => "valt_warp",
    "type" => "dash",
    "attack_type" => "ranged",
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
    "version_id" => version.id
  },
  %{
    "name" => "valt_antimatter",
    "type" => "basic",
    "attack_type" => "ranged",
    "cooldown_mechanism" => "stamina",
    "execution_duration_ms" => 450,
    "activation_delay_ms" => 150,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 1500,
    "stamina_cost" => 1,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [simple_shoot],
    "version_id" => version.id
  },
  %{
    "name" => "kenzu_quickslash",
    "type" => "basic",
    "attack_type" => "melee",
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
    "version_id" => version.id
  },
  %{
    "name" => "kenzu_quickslash_second",
    "type" => "basic",
    "attack_type" => "melee",
    "cooldown_mechanism" => "stamina",
    "reset_combo_ms" => 1_500,
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
    "version_id" => version.id
  },
  %{
    "name" => "kenzu_quickslash_third",
    "type" => "basic",
    "attack_type" => "melee",
    "cooldown_mechanism" => "stamina",
    "reset_combo_ms" => 1_500,
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
    "version_id" => version.id
  },
  %{
    "name" => "kenzu_whirlwind",
    "type" => "ultimate",
    "attack_type" => "melee",
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
        "damage" => 60,
        "range" => 500.0,
        "interval_ms" => 500,
        "duration_ms" => 5000,
        "offset" => 0
      }
    ],
    "on_owner_effect" => whirlwind_effect,
    "version_id" => version.id
  },
  %{
    "name" => "kenzu_pounce",
    "type" => "dash",
    "attack_type" => "melee",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 5000,
    "execution_duration_ms" => 350,
    "activation_delay_ms" => 0,
    "is_passive" => false,
    "autoaim" => false,
    "max_autoaim_range" => 1300,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [
      %{
        "type" => "dash",
        "speed" => 3.7,
        "radius" => 600,
        "duration_ms" => 350
      }
    ],
    "version_id" => version.id
  },
  %{
    "name" => "otix_carbonthrow",
    "type" => "basic",
    "attack_type" => "ranged",
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
      otix_carbonthrow_mechanic
    ],
    "version_id" => version.id
  },
  %{
    "name" => "otix_magma_rush",
    "type" => "dash",
    "attack_type" => "melee",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 5500,
    "execution_duration_ms" => 750,
    "activation_delay_ms" => 0,
    "is_passive" => false,
    "autoaim" => false,
    "max_autoaim_range" => 0,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [
      otix_magma_rush_mechanic
    ],
    "version_id" => version.id
  },
  %{
    "name" => "otix_inferno",
    "type" => "ultimate",
    "attack_type" => "melee",
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
      inferno
    ],
    "version_id" => version.id
  },
  %{
    "name" => "shinko_toxic_onion",
    "type" => "basic",
    "attack_type" => "ranged",
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
      toxic_onion
    ],
    "version_id" => version.id
  },
  %{
    "name" => "shinko_spore_dash",
    "type" => "dash",
    "attack_type" => "melee",
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
      spore_dash
    ],
    "version_id" => version.id
  },
  %{
    "name" => "shinko_PEB",
    "type" => "ultimate",
    "attack_type" => "melee",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 10000,
    "execution_duration_ms" => 400,
    "activation_delay_ms" => 0,
    "is_passive" => false,
    "autoaim" => false,
    "max_autoaim_range" => 0,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [
      putrid_elixir_bomb
    ],
    "version_id" => version.id
  },
  %{
    "name" => "uren_basic",
    "type" => "basic",
    "attack_type" => "ranged",
    "cooldown_mechanism" => "stamina",
    "execution_duration_ms" => 450,
    "activation_delay_ms" => 150,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 1500,
    "stamina_cost" => 1,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [simple_piercing_shoot],
    "version_id" => version.id
  },
  %{
    "name" => "uren_ultimate",
    "type" => "ultimate",
    "attack_type" => "ranged",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 10000,
    "execution_duration_ms" => 1000,
    "activation_delay_ms" => 0,
    "is_passive" => false,
    "autoaim" => true,
    "max_autoaim_range" => 1200,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [multi_piercing_shoot],
    "version_id" => version.id
  },
  %{
    "name" => "uren_dash",
    "type" => "dash",
    "attack_type" => "melee",
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 4000,
    "execution_duration_ms" => 275,
    "activation_delay_ms" => 0,
    "is_passive" => false,
    "autoaim" => false,
    "max_autoaim_range" => 0,
    "can_pick_destination" => false,
    "block_movement" => true,
    "mechanics" => [
      %{
        "type" => "dash",
        "speed" => 4,
        "duration_ms" => 275
      }
    ],
    "version_id" => version.id
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
  active: false,
  base_speed: 0.58,
  base_size: 110.0,
  base_health: 550,
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
  base_speed: 0.65,
  base_size: 90.0,
  base_health: 350,
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
  active: false,
  base_speed: 0.65,
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
  base_speed: 0.62,
  base_size: 100.0,
  base_health: 350,
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
  active: true,
  base_speed: 0.65,
  base_size: 100.0,
  base_health: 500,
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
  active: true,
  base_speed: 0.65,
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

shinko_params = %{
  name: "shinko",
  active: false,
  base_speed: 0.65,
  base_size: 100.0,
  base_health: 400,
  base_stamina: 3,
  stamina_interval: 2000,
  max_inventory_size: 1,
  natural_healing_interval: 1000,
  natural_healing_damage_interval: 3500,
  basic_skill_id: skills["shinko_toxic_onion"],
  ultimate_skill_id: skills["shinko_PEB"],
  dash_skill_id: skills["shinko_spore_dash"],
  version_id: version.id
}

uren_params = %{
  name: "uren",
  active: false,
  base_speed: 0.68,
  base_size: 100.0,
  base_health: 400,
  base_stamina: 3,
  stamina_interval: 2000,
  max_inventory_size: 1,
  natural_healing_interval: 1000,
  natural_healing_damage_interval: 3500,
  basic_skill_id: skills["uren_basic"],
  ultimate_skill_id: skills["uren_ultimate"],
  dash_skill_id: skills["uren_dash"],
  version_id: version.id
}

# Insert characters
characters =
  [
    muflus_params,
    h4ck_params,
    uma_params,
    valtimer_params,
    kenzu_params,
    otix_params,
    shinko_params,
    uren_params
  ]
  |> Enum.reduce([], fn char_params, characters ->
    {:ok, character} =
      Map.put(char_params, :game_id, curse_of_mirra_id)
      |> Map.put(:faction, "none")
      |> Characters.insert_character()

    characters ++ [character]
  end)

# Skins params

muflus_basic_params = %{
  is_default: true,
  name: "Basic",
  character_id: Enum.find(characters, fn c -> c.name == "muflus" end).id
}

h4ck_fenix_params = %{
  is_default: false,
  name: "Fenix",
  character_id: Enum.find(characters, fn c -> c.name == "h4ck" end).id
}

h4ck_basic_params = %{
  is_default: true,
  name: "Basic",
  character_id: Enum.find(characters, fn c -> c.name == "h4ck" end).id
}

valtimer_frostimer_params = %{
  is_default: false,
  name: "Frostimer",
  character_id: Enum.find(characters, fn c -> c.name == "valtimer" end).id
}

valtimer_basic_params = %{
  is_default: true,
  name: "Basic",
  character_id: Enum.find(characters, fn c -> c.name == "valtimer" end).id
}

kenzu_black_lotus_params = %{
  is_default: false,
  name: "Black Lotus",
  character_id: Enum.find(characters, fn c -> c.name == "kenzu" end).id
}

kenzu_basic_params = %{
  is_default: true,
  name: "Basic",
  character_id: Enum.find(characters, fn c -> c.name == "kenzu" end).id
}

otix_corrupt_underground = %{
  is_default: false,
  name: "Corrupt Underground",
  character_id: Enum.find(characters, fn c -> c.name == "otix" end).id
}

otix_basic_params = %{
  is_default: true,
  name: "Basic",
  character_id: Enum.find(characters, fn c -> c.name == "otix" end).id
}

uren_basic_params = %{
  is_default: true,
  name: "Basic",
  character_id: Enum.find(characters, fn c -> c.name == "uren" end).id
}

shinko_basic_params = %{
  is_default: true,
  name: "Basic",
  character_id: Enum.find(characters, fn c -> c.name == "shinko" end).id
}

# Insert skins
[
  h4ck_fenix_params,
  h4ck_basic_params,
  valtimer_frostimer_params,
  valtimer_basic_params,
  kenzu_black_lotus_params,
  kenzu_basic_params,
  otix_corrupt_underground,
  otix_basic_params,
  muflus_basic_params,
  uren_basic_params,
  shinko_basic_params
]
|> Enum.each(fn skin_params -> Characters.insert_skin(skin_params) end)

game_configuration_1 = %{
  tick_rate_ms: 30,
  bounty_pick_time_ms: 0,
  start_game_time_ms: 5000,
  end_game_interval_ms: 1000,
  shutdown_game_wait_ms: 10000,
  natural_healing_interval_ms: 300,
  zone_shrink_start_ms: 15000,
  zone_shrink_radius_by: 20,
  zone_shrink_interval: 100,
  zone_stop_interval_ms: 10000,
  zone_start_interval_ms: 20000,
  zone_damage_interval_ms: 1000,
  zone_damage: 40,
  item_spawn_interval_ms: 5000,
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

golden_clock_effect = %{
  name: "golden_clock_effect",
  duration_ms: 9000,
  remove_on_action: false,
  one_time_application: true,
  allow_multiple_effects: true,
  disabled_outside_pool: false,
  effect_mechanics: [
    %{
      name: "reduce_stamina_interval",
      modifier: 0.5,
      effect_delay_ms: 0,
      execute_multiple_times: false
    },
    %{
      name: "refresh_stamina",
      effect_delay_ms: 0,
      execute_multiple_times: false
    },
    %{
      name: "reduce_cooldowns_duration",
      modifier: 0.5,
      effect_delay_ms: 0,
      execute_multiple_times: false
    },
    %{
      name: "refresh_cooldowns",
      effect_delay_ms: 0,
      execute_multiple_times: false
    }
  ]
}

golden_clock_params = %{
  active: true,
  name: "golden_clock",
  radius: 200.0,
  mechanics: %{},
  effect: golden_clock_effect,
  version_id: version.id
}

{:ok, _golden_clock} =
  GameBackend.Items.create_consumable_item(golden_clock_params)

magic_boots_effect =
  %{
    name: "magic_boots_effect",
    duration_ms: 8000,
    remove_on_action: false,
    one_time_application: true,
    allow_multiple_effects: true,
    disabled_outside_pool: true,
    effect_mechanics: [
      %{
        name: "speed_boost",
        modifier: 0.5,
        effect_delay_ms: 0,
        execute_multiple_times: false
      }
    ]
  }

magic_boots_params = %{
  active: true,
  name: "magic_boots",
  radius: 200.0,
  mechanics: %{},
  effect: magic_boots_effect,
  version_id: version.id
}

{:ok, _magic_boots} =
  GameBackend.Items.create_consumable_item(magic_boots_params)

mirra_blessing_effect =
  %{
    name: "mirra_blessing_effect",
    duration_ms: 7000,
    remove_on_action: false,
    one_time_application: true,
    allow_multiple_effects: true,
    disabled_outside_pool: true,
    effect_mechanics: [
      %{
        name: "damage_immunity",
        effect_delay_ms: 0,
        execute_multiple_times: false
      }
    ]
  }

mirra_blessing_params = %{
  active: true,
  name: "mirra_blessing",
  radius: 200.0,
  mechanics: %{},
  effect: mirra_blessing_effect,
  version_id: version.id
}

{:ok, _mirra_blessing} =
  GameBackend.Items.create_consumable_item(mirra_blessing_params)

giant_effect =
  %{
    name: "giant_effect",
    duration_ms: 9000,
    remove_on_action: false,
    one_time_application: true,
    allow_multiple_effects: true,
    disabled_outside_pool: true,
    effect_mechanics: [
      %{
        name: "modify_radius",
        modifier: 0.4,
        effect_delay_ms: 0,
        execute_multiple_times: false
      },
      %{
        name: "damage_change",
        modifier: 0.25,
        effect_delay_ms: 0,
        execute_multiple_times: true
      },
      %{
        name: "speed_boost",
        modifier: -0.25,
        effect_delay_ms: 0,
        execute_multiple_times: false
      },
      %{
        name: "defense_change",
        modifier: 0.4,
        effect_delay_ms: 0,
        execute_multiple_times: true
      }
    ]
  }

giant_fruit_params = %{
  active: true,
  name: "giant",
  radius: 200.0,
  mechanics: %{},
  effect: giant_effect,
  version_id: version.id
}

{:ok, _giant_fruit} =
  GameBackend.Items.create_consumable_item(giant_fruit_params)

polymorph_effect = %{
  name: "polymorph_effect",
  duration_ms: 9000,
  remove_on_action: true,
  disabled_outside_pool: false,
  one_time_application: true,
  allow_multiple_effects: true,
  effect_mechanics: []
}

polymorph_params = %{
  active: false,
  name: "polymorph",
  radius: 200.0,
  mechanics: %{},
  effect: polymorph_effect
}

{:ok, _polymorph} =
  GameBackend.Items.create_consumable_item(polymorph_params)

bomb_circle_hit_mechanic =
  %{
    name: "bomb_circle_hit",
    type: "circle_hit",
    damage: 64,
    range: 380.0,
    offset: 400
  }

spawn_bomb_mechanic =
  %{
    name: "item_spawn_bomb",
    type: "spawn_bomb",
    radius: 200.0,
    activation_delay_ms: 3000,
    preparation_delay_ms: 500,
    activate_on_proximity: true,
    shape: "circle",
    vertices: [],
    parent_mechanic: bomb_circle_hit_mechanic
  }

fake_item_params = %{
  active: false,
  name: "fake_item",
  radius: 200.0,
  mechanics: [spawn_bomb_mechanic],
  version_id: version.id
}

{:ok, _fake_item} =
  GameBackend.Items.create_consumable_item(fake_item_params)

heal_mechanic =
  %{
    name: "heal_mechanic",
    type: "heal",
    amount: 200
  }

health_item_params = %{
  active: true,
  name: "health_item",
  radius: 200.0,
  mechanics: [heal_mechanic],
  version_id: version.id
}

{:ok, _heal_item} =
  GameBackend.Items.create_consumable_item(health_item_params)

silence_effect =
  %{
    name: "silence_effect",
    duration_ms: 9000,
    remove_on_action: false,
    one_time_application: true,
    disabled_outside_pool: false,
    allow_multiple_effects: true,
    effect_mechanics: [
      %{
        name: "silence",
        execute_multiple_times: false,
        effect_delay_ms: 0
      }
    ],
    version_id: version.id
  }

silence_item_mechanic =
  %{
    name: "silence_item_mechanic",
    type: "circle_hit",
    damage: 0,
    range: 1_000,
    offset: 0,
    effect: silence_effect,
    version_id: version.id
  }

silence_item_params = %{
  active: true,
  name: "silence_item",
  radius: 200.0,
  mechanics: [silence_item_mechanic],
  version_id: version.id
}

{:ok, _silence_item} =
  GameBackend.Items.create_consumable_item(silence_item_params)

_slow_field_effect = %{
  name: "slow_field_effect",
  duration_ms: 9000,
  remove_on_action: true,
  one_time_application: true,
  allow_multiple_effects: true,
  disabled_outside_pool: false,
  effect_mechanics: [
    %{
      name: "speed_boost",
      modifier: -0.5,
      effect_delay_ms: 0,
      execute_multiple_times: false
    }
  ]
}

araban_map_config = %{
  name: "Araban",
  radius: 15000,
  active: true,
  initial_positions: [
    %{
      x: -4300,
      y: 5800
    },
    %{
      x: 100,
      y: 3300
    },
    %{
      x: 3700,
      y: 5400
    },
    %{
      x: 5400,
      y: 3800
    },
    %{
      x: 3300,
      y: 100
    },
    %{
      x: 5400,
      y: -3800
    },
    %{
      x: 3900,
      y: -5400
    },
    %{
      x: -600,
      y: -3200
    },
    %{
      x: -4000,
      y: -5600
    },
    %{
      x: -5100,
      y: -3800
    },
    %{
      x: -3100,
      y: 100
    },
    %{
      x: -5600,
      y: 4300
    }
  ],
  obstacles: [
    %{
      "name" => "Wall_Top",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "8117.765", "y" => "6600"},
        %{"x" => "-9005.646", "y" => "6600"},
        %{"x" => "-8936.1", "y" => "6400"},
        %{"x" => "7947.096", "y" => "6400"}
      ]
    },
    %{
      "name" => "Wall_Bottom",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "8117.765", "y" => "-6600"},
        %{"x" => "-9005.646", "y" => "-6600"},
        %{"x" => "-8936.1", "y" => "-6400"},
        %{"x" => "7947.096", "y" => "-6400"}
      ]
    },
    %{
      "name" => "Wall_Right",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "6600", "y" => "-6519.197"},
        %{"x" => "6600", "y" => "6191.239"},
        %{"x" => "6400", "y" => "6209.371"},
        %{"x" => "6400", "y" => "-6427.376"}
      ]
    },
    %{
      "name" => "Wall_Left",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "-6600", "y" => "-6519.197"},
        %{"x" => "-6600", "y" => "6191.239"},
        %{"x" => "-6400", "y" => "6209.371"},
        %{"x" => "-6400", "y" => "-6427.376"}
      ]
    },
    %{
      "name" => "Rock_T_011",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "-3631.276", "y" => "6298.693"},
        %{"x" => "-2891.395", "y" => "6455.582"},
        %{"x" => "-2736.692", "y" => "5319.521"},
        %{"x" => "-3001.521", "y" => "5180.479"}
      ]
    },
    %{
      "name" => "Rock_T_02",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "-2396.266", "y" => "3147.654"},
        %{"x" => "-1782.337", "y" => "3509.896"},
        %{"x" => "-1280.627", "y" => "2632.996"},
        %{"x" => "-1556.002", "y" => "2407.177"}
      ]
    },
    %{
      "name" => "Rock_T_03_p1",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "2210.523", "y" => "4944.701"},
        %{"x" => "3061.171", "y" => "5457.247"},
        %{"x" => "3521.709", "y" => "5410.178"},
        %{"x" => "2835.657", "y" => "4767.928"}
      ]
    },
    %{
      "name" => "Rock_T_03_p2",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "2210.523", "y" => "4944.701"},
        %{"x" => "2216.941", "y" => "4180.208"},
        %{"x" => "2819.373", "y" => "3917.946"},
        %{"x" => "2835.657", "y" => "4767.928"}
      ]
    },
    %{
      "name" => "Calduron_T_06",
      "position" => %{"x" => "-1683", "y" => "6380"},
      "radius" => "420",
      "shape" => "circle",
      "type" => "static",
      "vertices" => []
    },
    %{
      "name" => "Calduron_T_05",
      "position" => %{"x" => "1760", "y" => "6380"},
      "radius" => "420",
      "shape" => "circle",
      "type" => "static",
      "vertices" => []
    },
    %{
      "name" => "Rock_R_01",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "6731.636", "y" => "3630.905"},
        %{"x" => "6612.104", "y" => "2801.469"},
        %{"x" => "5287.139", "y" => "2694.42"},
        %{"x" => "5226.602", "y" => "3159.771"}
      ]
    },
    %{
      "name" => "Rock_R_02",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "3203.68", "y" => "2368.408"},
        %{"x" => "3605.801", "y" => "1767.61"},
        %{"x" => "2645.971", "y" => "1281.607"},
        %{"x" => "2435.806", "y" => "1514.578"}
      ]
    },
    %{
      "name" => "Rock_R_03_p1",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "5031.366", "y" => "-2160.352"},
        %{"x" => "5524.489", "y" => "-3467.086"},
        %{"x" => "4786.79", "y" => "-2848.165"}
      ]
    },
    %{
      "name" => "Rock_R_03_p2",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "5031.366", "y" => "-2160.352"},
        %{"x" => "4203.926", "y" => "-2242.507"},
        %{"x" => "3831.921", "y" => "-2830.578"},
        %{"x" => "4786.79", "y" => "-2848.165"}
      ]
    },
    %{
      "name" => "Calduron_L_01",
      "position" => %{"x" => "6610", "y" => "1840"},
      "radius" => "420",
      "shape" => "circle",
      "type" => "static",
      "vertices" => []
    },
    %{
      "name" => "Calduron_L_02",
      "position" => %{"x" => "6610", "y" => "-1780"},
      "radius" => "420",
      "shape" => "circle",
      "type" => "static",
      "vertices" => []
    },
    %{
      "name" => "Rock_L_01",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "-6782.466", "y" => "-3745.394"},
        %{"x" => "-6834.827", "y" => "-2870.991"},
        %{"x" => "-5365.272", "y" => "-2708.721"},
        %{"x" => "-5188.337", "y" => "-3064.951"}
      ]
    },
    %{
      "name" => "Rock_L_02",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "-3264.556", "y" => "-2392.352"},
        %{"x" => "-3437.08", "y" => "-1693.48"},
        %{"x" => "-2547.287", "y" => "-1257.384"},
        %{"x" => "-2364.423", "y" => "-1521.288"}
      ]
    },
    %{
      "name" => "Rock_L_03_p1",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "-4690.288", "y" => "2755.349"},
        %{"x" => "-5199.296", "y" => "2372.082"},
        %{"x" => "-5496.187", "y" => "3443.65"}
      ]
    },
    %{
      "name" => "Rock_L_03_p2",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "-4690.288", "y" => "2755.349"},
        %{"x" => "-5199.296", "y" => "2372.082"},
        %{"x" => "-4567.782", "y" => "2035.565"},
        %{"x" => "-3802.042", "y" => "2788.869"}
      ]
    },
    %{
      "name" => "Calduron_L_03",
      "position" => %{"x" => "-6460", "y" => "1840"},
      "radius" => "420",
      "shape" => "circle",
      "type" => "static",
      "vertices" => []
    },
    %{
      "name" => "Calduron_L_04",
      "position" => %{"x" => "-6460", "y" => "-1610"},
      "radius" => "420",
      "shape" => "circle",
      "type" => "static",
      "vertices" => []
    },
    %{
      "name" => "Rock_B_01",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "2765.068", "y" => "-6673.642"},
        %{"x" => "3802.116", "y" => "-6588.992"},
        %{"x" => "3145.547", "y" => "-5129.084"},
        %{"x" => "2770.249", "y" => "-5262.095"}
      ]
    },
    %{
      "name" => "Rock_B_02",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "1679.574", "y" => "-3472.637"},
        %{"x" => "2424.204", "y" => "-3167.99"},
        %{"x" => "1507.762", "y" => "-2334.03"},
        %{"x" => "1364.14", "y" => "-2668.228"}
      ]
    },
    %{
      "name" => "Rock_B_03_p1",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "-3284.909", "y" => "-5516.763"},
        %{"x" => "-2812.067", "y" => "-4680.898"},
        %{"x" => "-2219.798", "y" => "-5095.086"}
      ]
    },
    %{
      "name" => "Rock_B_03_p2",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "-2210.021", "y" => "-4205.354"},
        %{"x" => "-2851.062", "y" => "-3884.709"},
        %{"x" => "-2812.067", "y" => "-4680.898"},
        %{"x" => "-2219.798", "y" => "-5095.086"}
      ]
    },
    %{
      "name" => "Structure_M_TL11",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "-1103.271", "y" => "953.9656"},
        %{"x" => "-1270.857", "y" => "1168.57"},
        %{"x" => "-944.2617", "y" => "1393.617"},
        %{"x" => "-524.387", "y" => "1488.506"},
        %{"x" => "-495.594", "y" => "1196.877"}
      ]
    },
    %{
      "name" => "Structure_M_TL2",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "-1026.994", "y" => "1007.727"},
        %{"x" => "-1207.883", "y" => "1208.302"},
        %{"x" => "-1478.527", "y" => "879.8398"},
        %{"x" => "-1591.924", "y" => "429.7523"},
        %{"x" => "-1254.913", "y" => "437.194"}
      ]
    },
    %{
      "name" => "Structure_M_TR_11",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "445.6904", "y" => "1203.487"},
        %{"x" => "433.5128", "y" => "1476.568"},
        %{"x" => "975.9529", "y" => "1369.776"},
        %{"x" => "1289.609", "y" => "1153.917"},
        %{"x" => "1052.909", "y" => "902.122"}
      ]
    },
    %{
      "name" => "Structure_M_TR_2",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "1163.651", "y" => "433.5555"},
        %{"x" => "1506.128", "y" => "418.9511"},
        %{"x" => "1439.307", "y" => "846.0876"},
        %{"x" => "1162.038", "y" => "1177.602"},
        %{"x" => "949.548", "y" => "988.2453"}
      ]
    },
    %{
      "name" => "Structure_M_BR_1",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "388.6146", "y" => "-1226.758"},
        %{"x" => "427.698", "y" => "-1507.054"},
        %{"x" => "1212.376", "y" => "-1160.641"},
        %{"x" => "921.9347", "y" => "-995.4576"}
      ]
    },
    %{
      "name" => "Structure_M_BR_2",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "1146.973", "y" => "-475.0844"},
        %{"x" => "1409.96", "y" => "-482.7019"},
        %{"x" => "1212.376", "y" => "-1160.641"},
        %{"x" => "921.9347", "y" => "-995.4576"}
      ]
    },
    %{
      "name" => "Structure_M_BL_1",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "-1085.073", "y" => "-451.5762"},
        %{"x" => "-931.3317", "y" => "-1032.454"},
        %{"x" => "-1181.466", "y" => "-1175.406"},
        %{"x" => "-1393.571", "y" => "-454.3091"}
      ]
    },
    %{
      "name" => "Structure_M_BL_2",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "type" => "static",
      "vertices" => [
        %{"x" => "-384.2261", "y" => "-1187.122"},
        %{"x" => "-931.3317", "y" => "-1032.454"},
        %{"x" => "-1181.466", "y" => "-1175.406"},
        %{"x" => "-391.4726", "y" => "-1469.853"}
      ]
    }
  ],
  bushes: [
    %{
      "name" => "Bush_L_cshape",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-5157.514", "y" => "3506.771"},
        %{"x" => "-3884.762", "y" => "2924.171"},
        %{"x" => "-4166.649", "y" => "2380.814"},
        %{"x" => "-5359.784", "y" => "3028.084"}
      ]
    },
    %{
      "name" => "Bush_L_01",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-1726.511", "y" => "1509.119"},
        %{"x" => "-1461.806", "y" => "1236.191"},
        %{"x" => "-2000.816", "y" => "17.44251"},
        %{"x" => "-2379.591", "y" => "94.73076"}
      ]
    },
    %{
      "name" => "Bush_L_02",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-2242.885", "y" => "-1488.032"},
        %{"x" => "-2033.694", "y" => "-1831.04"},
        %{"x" => "-2960.76", "y" => "-2789.73"},
        %{"x" => "-3313.971", "y" => "-2570.724"}
      ]
    },
    %{
      "name" => "Bush_L_island",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-5994.002", "y" => "321.6628"},
        %{"x" => "-6598.221", "y" => "-815.4293"},
        %{"x" => "-5253.056", "y" => "-1134.551"}
      ]
    },
    %{
      "name" => "Bush_T_cshape",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "3613.491", "y" => "5084.046"},
        %{"x" => "2991.442", "y" => "3874.203"},
        %{"x" => "2413.875", "y" => "4192.751"},
        %{"x" => "3185.681", "y" => "5364.128"}
      ]
    },
    %{
      "name" => "Bush_T_01",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "1475.148", "y" => "1894.788"},
        %{"x" => "1272.097", "y" => "1619.064"},
        %{"x" => "12.1933", "y" => "2078.002"},
        %{"x" => "162.8254", "y" => "2409.733"}
      ]
    },
    %{
      "name" => "Bush_T_02",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-1481.342", "y" => "2465.74"},
        %{"x" => "-1721.525", "y" => "2073.964"},
        %{"x" => "-2739.646", "y" => "3115.903"},
        %{"x" => "-2545.367", "y" => "3416.882"}
      ]
    },
    %{
      "name" => "Bush_T_island",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "289.1804", "y" => "5952.137"},
        %{"x" => "-785.1105", "y" => "6537.438"},
        %{"x" => "-1021.93", "y" => "5283.718"}
      ]
    },
    %{
      "name" => "Bush_R_cshape",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "4281.373", "y" => "-2392.708"},
        %{"x" => "5387.699", "y" => "-3071.004"},
        %{"x" => "5120.566", "y" => "-3595.442"},
        %{"x" => "3971.13", "y" => "-2957.985"}
      ]
    },
    %{
      "name" => "Bush_R_01",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "1955.627", "y" => "9.792709"},
        %{"x" => "2380.753", "y" => "-152.2906"},
        %{"x" => "1864.56", "y" => "-1462.079"},
        %{"x" => "1526.821", "y" => "-1226.789"}
      ]
    },
    %{
      "name" => "Bush_R_02 ",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "3348.349", "y" => "2655.573"},
        %{"x" => "2401.388", "y" => "1553.669"},
        %{"x" => "2103.234", "y" => "1748.015"},
        %{"x" => "3082.343", "y" => "2805.086"}
      ]
    },
    %{
      "name" => "Bush_R_island",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "6749.867", "y" => "826.6964"},
        %{"x" => "5413.483", "y" => "1052.161"},
        %{"x" => "5907.448", "y" => "-258.0237"}
      ]
    },
    %{
      "name" => "Bush_B_cshape",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-3187.642", "y" => "-5294.691"},
        %{"x" => "-2596.555", "y" => "-4069.327"},
        %{"x" => "-3072.92", "y" => "-3948.402"},
        %{"x" => "-3539.842", "y" => "-5008.903"}
      ]
    },
    %{
      "name" => "Bush_B_01",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "27.76451", "y" => "-1930.305"},
        %{"x" => "11.83586", "y" => "-2296.283"},
        %{"x" => "-1349.111", "y" => "-1872.221"},
        %{"x" => "-1118.045", "y" => "-1551.602"}
      ]
    },
    %{
      "name" => "Bush_B_02",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "2869.763", "y" => "-3044.426"},
        %{"x" => "2587.075", "y" => "-3314.726"},
        %{"x" => "1564.604", "y" => "-2388.573"},
        %{"x" => "1805.244", "y" => "-2041.001"}
      ]
    },
    %{
      "name" => "Bush_B_island",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "468.0905", "y" => "-5245.852"},
        %{"x" => "-156.4262", "y" => "-6414.775"},
        %{"x" => "1315.218", "y" => "-6229.148"}
      ]
    }
  ],
  crates: [],
  pools: [
    %{
      "effect" => %{
        "allow_multiple_effects" => true,
        "disabled_outside_pool" => true,
        "duration_ms" => "180000",
        "effect_mechanics" => [
          %{
            "damage" => "30",
            "effect_delay_ms" => "1000",
            "execute_multiple_times" => true,
            "name" => "damage"
          }
        ],
        "name" => "damage_effect",
        "one_time_application" => true,
        "remove_on_action" => false
      },
      "name" => "Lava_T_L_s",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-6228.787", "y" => "5892.756"},
        %{"x" => "-5870", "y" => "6134.025"},
        %{"x" => "-4636.379", "y" => "4959.863"},
        %{"x" => "-4826.637", "y" => "4497.038"}
      ]
    },
    %{
      "effect" => %{
        "allow_multiple_effects" => true,
        "disabled_outside_pool" => true,
        "duration_ms" => "180000",
        "effect_mechanics" => [
          %{
            "damage" => "30",
            "effect_delay_ms" => "1000",
            "execute_multiple_times" => true,
            "name" => "damage"
          }
        ],
        "name" => "damage_effect",
        "one_time_application" => true,
        "remove_on_action" => false
      },
      "name" => "Lava_T_L",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-4483.661", "y" => "4178.818"},
        %{"x" => "-4325.283", "y" => "4648.48"},
        %{"x" => "-1193.775", "y" => "1515.677"},
        %{"x" => "-1540.612", "y" => "1220.493"}
      ]
    },
    %{
      "effect" => %{
        "allow_multiple_effects" => true,
        "disabled_outside_pool" => true,
        "duration_ms" => "180000",
        "effect_mechanics" => [
          %{
            "damage" => "30",
            "effect_delay_ms" => "1000",
            "execute_multiple_times" => true,
            "name" => "damage"
          }
        ],
        "name" => "damage_effect",
        "one_time_application" => true,
        "remove_on_action" => false
      },
      "name" => "Lava_T_R_s",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "5713.42", "y" => "5906.121"},
        %{"x" => "6125.13", "y" => "5639.894"},
        %{"x" => "5089.757", "y" => "4611.174"},
        %{"x" => "4617.9", "y" => "4790.271"}
      ]
    },
    %{
      "effect" => %{
        "allow_multiple_effects" => true,
        "disabled_outside_pool" => true,
        "duration_ms" => "180000",
        "effect_mechanics" => [
          %{
            "damage" => "30",
            "effect_delay_ms" => "1000",
            "execute_multiple_times" => true,
            "name" => "damage"
          }
        ],
        "name" => "damage_effect",
        "one_time_application" => true,
        "remove_on_action" => false
      },
      "name" => "Lava_T_R",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "4305.658", "y" => "4452.338"},
        %{"x" => "4765.873", "y" => "4273.772"},
        %{"x" => "1619.973", "y" => "1147.344"},
        %{"x" => "1309.234", "y" => "1459.771"}
      ]
    },
    %{
      "effect" => %{
        "allow_multiple_effects" => true,
        "disabled_outside_pool" => true,
        "duration_ms" => "180000",
        "effect_mechanics" => [
          %{
            "damage" => "30",
            "effect_delay_ms" => "1000",
            "execute_multiple_times" => true,
            "name" => "damage"
          }
        ],
        "name" => "damage_effect",
        "one_time_application" => true,
        "remove_on_action" => false
      },
      "name" => "Lava_B_L",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-4097.322", "y" => "-4589.48"},
        %{"x" => "-4587.197", "y" => "-4389.593"},
        %{"x" => "-1519.185", "y" => "-1339.063"},
        %{"x" => "-1135.502", "y" => "-1630.063"}
      ]
    },
    %{
      "effect" => %{
        "allow_multiple_effects" => true,
        "disabled_outside_pool" => true,
        "duration_ms" => "180000",
        "effect_mechanics" => [
          %{
            "damage" => "30",
            "effect_delay_ms" => "1000",
            "execute_multiple_times" => true,
            "name" => "damage"
          }
        ],
        "name" => "damage_effect",
        "one_time_application" => true,
        "remove_on_action" => false
      },
      "name" => "Lava_B_L_s",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-5954.249", "y" => "-6446.541"},
        %{"x" => "-6228.873", "y" => "-6163.637"},
        %{"x" => "-4941.389", "y" => "-4715.835"},
        %{"x" => "-4438.478", "y" => "-4906.552"}
      ]
    },
    %{
      "effect" => %{
        "allow_multiple_effects" => true,
        "disabled_outside_pool" => true,
        "duration_ms" => "180000",
        "effect_mechanics" => [
          %{
            "damage" => "30",
            "effect_delay_ms" => "1000",
            "execute_multiple_times" => true,
            "name" => "damage"
          }
        ],
        "name" => "damage_effect",
        "one_time_application" => true,
        "remove_on_action" => false
      },
      "name" => "Lava_B_R",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "4494.057", "y" => "-4188.89"},
        %{"x" => "4340.32", "y" => "-4661.753"},
        %{"x" => "1219.201", "y" => "-1571.758"},
        %{"x" => "1534.54", "y" => "-1229.803"}
      ]
    },
    %{
      "effect" => %{
        "allow_multiple_effects" => true,
        "disabled_outside_pool" => true,
        "duration_ms" => "180000",
        "effect_mechanics" => [
          %{
            "damage" => "30",
            "effect_delay_ms" => "1000",
            "execute_multiple_times" => true,
            "name" => "damage"
          }
        ],
        "name" => "damage_effect",
        "one_time_application" => true,
        "remove_on_action" => false
      },
      "name" => "Lava_B_R_s",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "6336.88", "y" => "-6090.804"},
        %{"x" => "6026.017", "y" => "-6397.371"},
        %{"x" => "4660.152", "y" => "-4993.641"},
        %{"x" => "4874.12", "y" => "-4530.465"}
      ]
    },
    %{
      "effect" => %{
        "allow_multiple_effects" => true,
        "disabled_outside_pool" => true,
        "duration_ms" => "180000",
        "effect_mechanics" => [
          %{
            "damage" => "30",
            "effect_delay_ms" => "1000",
            "execute_multiple_times" => true,
            "name" => "damage"
          }
        ],
        "name" => "damage_effect",
        "one_time_application" => true,
        "remove_on_action" => false
      },
      "name" => "Lava_M_T",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-266.0307", "y" => "1939.59"},
        %{"x" => "705.4561", "y" => "1802.05"},
        %{"x" => "1465.969", "y" => "1297.05"},
        %{"x" => "1187.064", "y" => "1045.797"},
        %{"x" => "-123.2952", "y" => "1509.82"}
      ]
    },
    %{
      "effect" => %{
        "allow_multiple_effects" => true,
        "disabled_outside_pool" => true,
        "duration_ms" => "180000",
        "effect_mechanics" => [
          %{
            "damage" => "30",
            "effect_delay_ms" => "1000",
            "execute_multiple_times" => true,
            "name" => "damage"
          }
        ],
        "name" => "damage_effect",
        "one_time_application" => true,
        "remove_on_action" => false
      },
      "name" => "Lava_M_T1",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "1396.628", "y" => "503.8064"},
        %{"x" => "1841.824", "y" => "688.5865"},
        %{"x" => "1465.969", "y" => "1297.05"},
        %{"x" => "1187.064", "y" => "1045.797"}
      ]
    },
    %{
      "effect" => %{
        "allow_multiple_effects" => true,
        "disabled_outside_pool" => true,
        "duration_ms" => "180000",
        "effect_mechanics" => [
          %{
            "damage" => "30",
            "effect_delay_ms" => "1000",
            "execute_multiple_times" => true,
            "name" => "damage"
          }
        ],
        "name" => "damage_effect",
        "one_time_application" => true,
        "remove_on_action" => false
      },
      "name" => "Lava_M_L",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "1878.059", "y" => "280.5017"},
        %{"x" => "1946.518", "y" => "36.83777"},
        %{"x" => "1829.031", "y" => "-634.7307"},
        %{"x" => "1357.55", "y" => "-588.7642"},
        %{"x" => "1493.295", "y" => "107.4883"}
      ]
    },
    %{
      "effect" => %{
        "allow_multiple_effects" => true,
        "disabled_outside_pool" => true,
        "duration_ms" => "180000",
        "effect_mechanics" => [
          %{
            "damage" => "30",
            "effect_delay_ms" => "1000",
            "execute_multiple_times" => true,
            "name" => "damage"
          }
        ],
        "name" => "damage_effect",
        "one_time_application" => true,
        "remove_on_action" => false
      },
      "name" => "Lava_M_L1",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "677.988", "y" => "-1818.792"},
        %{"x" => "1412.499", "y" => "-1445.245"},
        %{"x" => "1829.031", "y" => "-634.7307"},
        %{"x" => "1357.55", "y" => "-588.7642"},
        %{"x" => "523.1795", "y" => "-1444.89"}
      ]
    },
    %{
      "effect" => %{
        "allow_multiple_effects" => true,
        "disabled_outside_pool" => true,
        "duration_ms" => "180000",
        "effect_mechanics" => [
          %{
            "damage" => "30",
            "effect_delay_ms" => "1000",
            "execute_multiple_times" => true,
            "name" => "damage"
          }
        ],
        "name" => "damage_effect",
        "one_time_application" => true,
        "remove_on_action" => false
      },
      "name" => "Lava_M_B",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "265.4776", "y" => "-1913.465"},
        %{"x" => "-533.4549", "y" => "-1913.333"},
        %{"x" => "-1335.006", "y" => "-1391.035"},
        %{"x" => "-1036.319", "y" => "-1274.458"},
        %{"x" => "86.27892", "y" => "-1480.431"}
      ]
    },
    %{
      "effect" => %{
        "allow_multiple_effects" => true,
        "disabled_outside_pool" => true,
        "duration_ms" => "180000",
        "effect_mechanics" => [
          %{
            "damage" => "30",
            "effect_delay_ms" => "1000",
            "execute_multiple_times" => true,
            "name" => "damage"
          }
        ],
        "name" => "damage_effect",
        "one_time_application" => true,
        "remove_on_action" => false
      },
      "name" => "Lava_M_B1",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-1843.178", "y" => "-663.4233"},
        %{"x" => "-1602.128", "y" => "-1134.899"},
        %{"x" => "-1335.006", "y" => "-1391.035"},
        %{"x" => "-976.0599", "y" => "-1249.586"},
        %{"x" => "-1439.618", "y" => "-476.5906"}
      ]
    },
    %{
      "effect" => %{
        "allow_multiple_effects" => true,
        "disabled_outside_pool" => true,
        "duration_ms" => "180000",
        "effect_mechanics" => [
          %{
            "damage" => "30",
            "effect_delay_ms" => "1000",
            "execute_multiple_times" => true,
            "name" => "damage"
          }
        ],
        "name" => "damage_effect",
        "one_time_application" => true,
        "remove_on_action" => false
      },
      "name" => "Lava_M_R",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-1923.018", "y" => "-270.664"},
        %{"x" => "-1887.907", "y" => "569.2549"},
        %{"x" => "-1451.703", "y" => "1407.043"},
        %{"x" => "-1270.348", "y" => "1076.371"},
        %{"x" => "-1492.641", "y" => "-97.68877"}
      ]
    },
    %{
      "effect" => %{
        "allow_multiple_effects" => true,
        "disabled_outside_pool" => true,
        "duration_ms" => "180000",
        "effect_mechanics" => [
          %{
            "damage" => "30",
            "effect_delay_ms" => "1000",
            "execute_multiple_times" => true,
            "name" => "damage"
          }
        ],
        "name" => "damage_effect",
        "one_time_application" => true,
        "remove_on_action" => false
      },
      "name" => "Lava_M_R1",
      "position" => %{"x" => "0", "y" => "0"},
      "radius" => "0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-520.0995", "y" => "1398.698"},
        %{"x" => "-705.1613", "y" => "1832.864"},
        %{"x" => "-1451.703", "y" => "1407.043"},
        %{"x" => "-1270.348", "y" => "1076.371"}
      ]
    }
  ],
  version_id: version.id
}

merliot_map_config = %{
  name: "Merliot",
  radius: 15000.0,
  active: true,
  initial_positions: [
    %{x: -4961, y: 5001},
    %{x: -2417, y: 5103},
    %{x: 952, y: 5603},
    %{x: 4695, y: 4859},
    %{x: 5632, y: 2753},
    %{x: 5242, y: -316},
    %{x: 4908, y: -3698},
    %{x: 2442, y: -5476},
    %{x: -897, y: -5296},
    %{x: -4871, y: -4868},
    %{x: -4897, y: -2416},
    %{x: -5047, y: 853}
  ],
  obstacles: [
    %{
      "base_status" => nil,
      "name" => "East wall",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "6400", "y" => "12000"},
        %{"x" => "12000", "y" => "12000"},
        %{"x" => "12000", "y" => "-12000"},
        %{"x" => "6400", "y" => "-12000"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "North wall",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "12000", "y" => "12000"},
        %{"x" => "12000", "y" => "6400"},
        %{"x" => "-12000", "y" => "6400"},
        %{"x" => "-12000", "y" => "12000"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "West wall",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "-12000", "y" => "12000"},
        %{"x" => "-6400", "y" => "12000"},
        %{"x" => "-6400", "y" => "-12000"},
        %{"x" => "-12000", "y" => "-12000"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "South wall",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "-12000", "y" => "-6400"},
        %{"x" => "12000", "y" => "-6400"},
        %{"x" => "12000", "y" => "-12000"},
        %{"x" => "-12000", "y" => "-12000"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Center Bottom Left Top Wall",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "-2140", "y" => "-319"},
        %{"x" => "-1991", "y" => "-315"},
        %{"x" => "-1962", "y" => "-981"},
        %{"x" => "-2169", "y" => "-985"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Center Bottom Left Mid Wall",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "-2169", "y" => "-985"},
        %{"x" => "-1962", "y" => "-981"},
        %{"x" => "-1602", "y" => "-1295"},
        %{"x" => "-1743", "y" => "-1444"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Center Bottom Left Down Wall",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "-1289", "y" => "-1586"},
        %{"x" => "-836", "y" => "-2083"},
        %{"x" => "-938", "y" => "-2196"},
        %{"x" => "-1446", "y" => "-1746"},
        %{"x" => "-1446", "y" => "-1746"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Center Bottom Right Down Wall",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "341", "y" => "-2144"},
        %{"x" => "341", "y" => "-2010"},
        %{"x" => "982", "y" => "-2010"},
        %{"x" => "994", "y" => "-2185"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Center Bottom Right Mid Wall",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "994", "y" => "-2185"},
        %{"x" => "982", "y" => "-2010"},
        %{"x" => "1329", "y" => "-1615"},
        %{"x" => "1472", "y" => "-1751"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Center Bottom Right Top Wall",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "1777", "y" => "-1457"},
        %{"x" => "1608", "y" => "-1317"},
        %{"x" => "2108", "y" => "-854"},
        %{"x" => "2226", "y" => "-961"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Center Top Left Bottom Wall",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "-2173", "y" => "922"},
        %{"x" => "-1710", "y" => "1433"},
        %{"x" => "-1566", "y" => "1305"},
        %{"x" => "-2055", "y" => "826"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Center Top Left Mid Wall",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "-1281", "y" => "1622"},
        %{"x" => "-1412", "y" => "1722"},
        %{"x" => "-966", "y" => "2183"},
        %{"x" => "-961", "y" => "2006"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Center Top Left Top Wall",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "-966", "y" => "2183"},
        %{"x" => "-961", "y" => "2006"},
        %{"x" => "-310", "y" => "2013"},
        %{"x" => "-310", "y" => "2157"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Center Top Right Bottom Wall",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "2137", "y" => "355"},
        %{"x" => "1969", "y" => "342"},
        %{"x" => "1956", "y" => "990"},
        %{"x" => "2159", "y" => "990"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Center Top Right Mid Wall",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "2159", "y" => "990"},
        %{"x" => "1961", "y" => "990"},
        %{"x" => "1576", "y" => "1313"},
        %{"x" => "1712", "y" => "1449"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Center Top Right Top Wall",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "1410", "y" => "1748"},
        %{"x" => "1269", "y" => "1610"},
        %{"x" => "797", "y" => "2086"},
        %{"x" => "910", "y" => "2182"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Center altar",
      "position" => %{"x" => "31", "y" => "-140"},
      "radius" => "400",
      "shape" => "circle",
      "statuses_cycle" => nil,
      "type" => "static",
      "vertices" => []
    },
    %{
      "base_status" => nil,
      "name" => "Left Top Water 1",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "lake",
      "vertices" => [
        %{"x" => "-4360", "y" => "2759"},
        %{"x" => "-3167", "y" => "3087"},
        %{"x" => "-2743", "y" => "2204"},
        %{"x" => "-3500", "y" => "500"},
        %{"x" => "-4345", "y" => "400"},
        %{"x" => "-4900", "y" => "1800"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Left Bottom Water",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "lake",
      "vertices" => [
        %{"x" => "-3117", "y" => "-2705"},
        %{"x" => "-2539", "y" => "-2550"},
        %{"x" => "-837", "y" => "-3421"},
        %{"x" => "-532", "y" => "-4091"},
        %{"x" => "-1788", "y" => "-4935"},
        %{"x" => "-3029", "y" => "-4477"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Close to Wall Top Left Water",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "lake",
      "vertices" => [
        %{"x" => "-10458", "y" => "8000"},
        %{"x" => "-5150", "y" => "3016"},
        %{"x" => "-5600", "y" => "2132"},
        %{"x" => "-10439", "y" => "2505"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Close to Wall Top Right Water",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "lake",
      "vertices" => [
        %{"x" => "2380", "y" => "70000"},
        %{"x" => "3760", "y" => "70000"},
        %{"x" => "3760", "y" => "6300"},
        %{"x" => "3310", "y" => "5460"},
        %{"x" => "2380", "y" => "5820"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Close To Wall Bottom Left Water",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "lake",
      "vertices" => [
        %{"x" => "-3168", "y" => "-5127"},
        %{"x" => "-2062", "y" => "-5648"},
        %{"x" => "-2530", "y" => "-10395"},
        %{"x" => "-6000", "y" => "-10404"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Close To Wall Bottom Right Water",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "lake",
      "vertices" => [
        %{"x" => "70000", "y" => "-4620"},
        %{"x" => "6400", "y" => "-4620"},
        %{"x" => "5590", "y" => "-3400"},
        %{"x" => "6000", "y" => "-2300"},
        %{"x" => "70000", "y" => "-2300"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Bottom Mid Water",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "lake",
      "vertices" => [
        %{"x" => "-272", "y" => "-3195"},
        %{"x" => "2056", "y" => "-2643"},
        %{"x" => "2230", "y" => "-3450"},
        %{"x" => "80", "y" => "-3947"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Top Mid Water",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "lake",
      "vertices" => [
        %{"x" => "-2482", "y" => "3376"},
        %{"x" => "0", "y" => "4110"},
        %{"x" => "294", "y" => "3177"},
        %{"x" => "-2139", "y" => "2410"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Right Mid Water",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "lake",
      "vertices" => [
        %{"x" => "2664", "y" => "2310"},
        %{"x" => "3299", "y" => "2519"},
        %{"x" => "3659", "y" => "1608"},
        %{"x" => "4035", "y" => "-68"},
        %{"x" => "3478", "y" => "-200"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Left Mid Water",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "lake",
      "vertices" => [
        %{"x" => "-4107", "y" => "-343"},
        %{"x" => "-3368", "y" => "-169"},
        %{"x" => "-2826", "y" => "-2024"},
        %{"x" => "-3448", "y" => "-2203"},
        %{"x" => "-3957", "y" => "-1003"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Bottom Right Water",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "lake",
      "vertices" => [
        %{"x" => "2653", "y" => "-2438"},
        %{"x" => "2792", "y" => "-3186"},
        %{"x" => "4896", "y" => "-2963"},
        %{"x" => "5371", "y" => "-1881"},
        %{"x" => "4212", "y" => "-509"},
        %{"x" => "3615", "y" => "-694"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "Top Right Water",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "lake",
      "vertices" => [
        %{"x" => "2381", "y" => "2856"},
        %{"x" => "3029", "y" => "3061"},
        %{"x" => "3000", "y" => "4737"},
        %{"x" => "1802", "y" => "5366"},
        %{"x" => "565", "y" => "4300"},
        %{"x" => "808", "y" => "3500"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "zone 1 - obstacle 1 - rock tree",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "-5961.0", "y" => "6300.0"},
        %{"x" => "-6300.0", "y" => "5800.0"},
        %{"x" => "-10000.0", "y" => "5800.0"},
        %{"x" => "-5800.0", "y" => "10000.0"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "zone 1 - obstacle 2 - top rock",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "-3527.0", "y" => "4830.0"},
        %{"x" => "-4571.0", "y" => "5185.0"},
        %{"x" => "-4477.0", "y" => "5560.0"},
        %{"x" => "-3374.0", "y" => "5194.0"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "zone 1 - obstacle 3 - left rock",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "-5297.0", "y" => "4830.0"},
        %{"x" => "-4722.0", "y" => "4785.0"},
        %{"x" => "-4670.0", "y" => "3812.0"},
        %{"x" => "-4942.0", "y" => "3612.0"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "zone 2 - obstacle 1 - left rock",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "-5333.0", "y" => "-3496.0"},
        %{"x" => "-4775.0", "y" => "-3513.0"},
        %{"x" => "-5144.0", "y" => "-4439.0"},
        %{"x" => "-5577.0", "y" => "-4637.0"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "zone 2 - obstacle 2 - bottom rock",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "-4845.0", "y" => "-5448.0"},
        %{"x" => "-4948.0", "y" => "-4718.0"},
        %{"x" => "-3585.0", "y" => "-4811.0"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "zone 2 - obstacle 3 - rock tree",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "-5352.0", "y" => "-6300.0"},
        %{"x" => "-5352.0", "y" => "-70000.0"},
        %{"x" => "-70000.0", "y" => "-70000.0"},
        %{"x" => "-70000.0", "y" => "-5700.0"},
        %{"x" => "-6300.0", "y" => "-5753.0"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "zone 3 - obstacle 1 - rock tree",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "5273.0", "y" => "6300.0"},
        %{"x" => "5273.0", "y" => "10000.0"},
        %{"x" => "10000.0", "y" => "10000.0"},
        %{"x" => "10000.0", "y" => "5600.0"},
        %{"x" => "6300.0", "y" => "5600.0"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "zone 3 - obstacle 2 - right rock",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "5300.0", "y" => "4150.0"},
        %{"x" => "5700.0", "y" => "4210.0"},
        %{"x" => "5700.0", "y" => "3450.0"},
        %{"x" => "5360.0", "y" => "3030.0"},
        %{"x" => "5080.0", "y" => "3190.0"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "zone 3 - obstacle 3 - top rock",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "4020.0", "y" => "4730.0"},
        %{"x" => "5100.0", "y" => "4930.0"},
        %{"x" => "5170.0", "y" => "4420.0"},
        %{"x" => "3960.0", "y" => "4420.0"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "zone 4 - obstacle 1 - bottom rock",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "3468.0", "y" => "-5078.0"},
        %{"x" => "4650.0", "y" => "-5078.0"},
        %{"x" => "4490.0", "y" => "-5800.0"},
        %{"x" => "3772.0", "y" => "-5563.0"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "zone 4 - obstacle 2 - right rock",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "4610.0", "y" => "-3830.0"},
        %{"x" => "5000.0", "y" => "-3830.0"},
        %{"x" => "5320.0", "y" => "-4860.0"},
        %{"x" => "4710.0", "y" => "-4860.0"}
      ]
    },
    %{
      "base_status" => nil,
      "name" => "zone 4 - obstacle 3 - rock tree",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "statuses_cycle" => %{},
      "type" => "static",
      "vertices" => [
        %{"x" => "5624.0", "y" => "-6300.0"},
        %{"x" => "6300.0", "y" => "-5600.0"},
        %{"x" => "70000.0", "y" => "-5600.0"},
        %{"x" => "70000.0", "y" => "-70000.0"},
        %{"x" => "5624.0", "y" => "-70000.0"}
      ]
    }
  ],
  bushes: [
    %{
      "name" => "zone 1 - bush 1",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-6900.0", "y" => "6900.0"},
        %{"x" => "-5486.0", "y" => "6300.0"},
        %{"x" => "-6300.0", "y" => "5400.0"}
      ]
    },
    %{
      "name" => "zone 1 - bush 2",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-4755.0", "y" => "5171.0"},
        %{"x" => "-3774.0", "y" => "4857.0"},
        %{"x" => "-4516.0", "y" => "4060.0"}
      ]
    },
    %{
      "name" => "zone 1 - bush 3",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-1196.0", "y" => "7000.0"},
        %{"x" => "-1196.0", "y" => "6100.0"},
        %{"x" => "-2650.0", "y" => "6100.0"},
        %{"x" => "-2650.0", "y" => "7000.0"}
      ]
    },
    %{
      "name" => "zone 1 - bush 4",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-2190.0", "y" => "3861.0"},
        %{"x" => "-790.0", "y" => "4340.0"},
        %{"x" => "-444.0", "y" => "3460.0"},
        %{"x" => "-1780.0", "y" => "3070.0"}
      ]
    },
    %{
      "name" => "zone 2 - bush 1",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-5957.0", "y" => "-396.0"},
        %{"x" => "-5957.0", "y" => "-1942.0"},
        %{"x" => "-70000.0", "y" => "-1942.0"},
        %{"x" => "-70000.0", "y" => "-396.0"}
      ]
    },
    %{
      "name" => "zone 2 - bush 2",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-4557.0", "y" => "-533.0"},
        %{"x" => "-4204.0", "y" => "-359.0"},
        %{"x" => "-3758.0", "y" => "-1764.0"},
        %{"x" => "-4245.0", "y" => "-1886.0"}
      ]
    },
    %{
      "name" => "zone 2 - bush 3",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-4952.0", "y" => "-3813.0"},
        %{"x" => "-5257.0", "y" => "-4942.0"},
        %{"x" => "-3866.0", "y" => "-4664.0"}
      ]
    },
    %{
      "name" => "zone 2 - bush 4",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-6300.0", "y" => "-5320.0"},
        %{"x" => "-4973.0", "y" => "-6300.0"},
        %{"x" => "-6300.0", "y" => "-6300.0"}
      ]
    },
    %{
      "name" => "center - bush 1",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-2870.0", "y" => "2040.0"},
        %{"x" => "-2040.0", "y" => "1200.0"},
        %{"x" => "-3220.0", "y" => "870.0"}
      ]
    },
    %{
      "name" => "center - bush 2",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "1015.0", "y" => "3380.0"},
        %{"x" => "2295.0", "y" => "2642.0"},
        %{"x" => "1080.0", "y" => "2230.0"}
      ]
    },
    %{
      "name" => "center - bush 3",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "3450.0", "y" => "-790.0"},
        %{"x" => "2390.0", "y" => "-1070.0"},
        %{"x" => "2820.0", "y" => "-2050.0"}
      ]
    },
    %{
      "name" => "center - bush 4",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "-1474.0", "y" => "-2122.0"},
        %{"x" => "-1021.0", "y" => "-3211.0"},
        %{"x" => "-2153.0", "y" => "-2635.0"}
      ]
    },
    %{
      "name" => "zone 3 - bush 1",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "4837.0", "y" => "6063.0"},
        %{"x" => "6300.0", "y" => "6300.0"},
        %{"x" => "6300.0", "y" => "5278.0"}
      ]
    },
    %{
      "name" => "zone 3 - bush 2",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "5346.0", "y" => "4331.0"},
        %{"x" => "4971.0", "y" => "3370.0"},
        %{"x" => "4054.0", "y" => "4320.0"}
      ]
    },
    %{
      "name" => "zone 3 - bush 3",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "3775.0", "y" => "1621.0"},
        %{"x" => "4289.0", "y" => "1817.0"},
        %{"x" => "4568.0", "y" => "416.0"},
        %{"x" => "4050.0", "y" => "322.0"}
      ]
    },
    %{
      "name" => "zone 3 - bush 4",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "6122.0", "y" => "1330.0"},
        %{"x" => "6300.0", "y" => "1330.0"},
        %{"x" => "6300.0", "y" => "-50.0"},
        %{"x" => "6120.0", "y" => "-50.0"}
      ]
    },
    %{
      "name" => "zone 4 - bush 1",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "421.0", "y" => "-3970.0"},
        %{"x" => "1926.0", "y" => "-3622.0"},
        %{"x" => "1914.0", "y" => "-3828.0"},
        %{"x" => "685.0", "y" => "-4202.0"}
      ]
    },
    %{
      "name" => "zone 4 - bush 2",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "1198.0", "y" => "-5940.0"},
        %{"x" => "2740.0", "y" => "-5940.0"},
        %{"x" => "2740.0", "y" => "-6400.0"},
        %{"x" => "1198.0", "y" => "-6400.0"}
      ]
    },
    %{
      "name" => "zone 4 - bush 3",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "3621.0", "y" => "-4966.0"},
        %{"x" => "4519.0", "y" => "-4047.0"},
        %{"x" => "4893.0", "y" => "-5207.0"}
      ]
    },
    %{
      "name" => "zone 4 - bush 3",
      "position" => %{"x" => "0.0", "y" => "0.0"},
      "radius" => "0.0",
      "shape" => "polygon",
      "vertices" => [
        %{"x" => "5190.0", "y" => "-6300.0"},
        %{"x" => "6300.0", "y" => "-5100.0"},
        %{"x" => "6300.0", "y" => "-6300.0"}
      ]
    }
  ],
  pools: [],
  version_id: version.id,
  square_wall: %{
    right: 6400,
    left: -6400,
    bottom: -6400,
    top: 6400
  }
}

{:ok, araban_map_configuration} =
  GameBackend.Configuration.create_map_configuration(araban_map_config)

{:ok, merliot_map_configuration} =
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

battle_mode_params = %{
  version_id: version.id,
  type: "battle_royale",
  zone_enabled: true,
  bots_enabled: true,
  match_duration_ms: 180_000,
  team_size: 1,
  map_mode_params: [
    %{
      amount_of_players: 12,
      initial_positions: [
        %{x: -4961, y: 5001},
        %{x: -2417, y: 5103},
        %{x: 952, y: 5603},
        %{x: 4695, y: 4859},
        %{x: 5632, y: 2753},
        %{x: 5242, y: -316},
        %{x: 4908, y: -3698},
        %{x: 2442, y: -5476},
        %{x: -897, y: -5296},
        %{x: -4871, y: -4868},
        %{x: -4897, y: -2416},
        %{x: -5047, y: 853}
      ],
      map_id: merliot_map_configuration.id
    }
  ]
}

quick_game_params = %{
  version_id: version.id,
  type: "practice",
  zone_enabled: true,
  bots_enabled: true,
  team_size: 1,
  match_duration_ms: 180_000,
  map_mode_params: [
    %{
      amount_of_players: 12,
      initial_positions: [
        %{x: -4961, y: 5001},
        %{x: -2417, y: 5103},
        %{x: 952, y: 5603},
        %{x: 4695, y: 4859},
        %{x: 5632, y: 2753},
        %{x: 5242, y: -316},
        %{x: 4908, y: -3698},
        %{x: 2442, y: -5476},
        %{x: -897, y: -5296},
        %{x: -4871, y: -4868},
        %{x: -4897, y: -2416},
        %{x: -5047, y: 853}
      ],
      map_id: merliot_map_configuration.id
    }
  ]
}

deathmatch_mode_params = %{
  version_id: version.id,
  type: "deathmatch",
  zone_enabled: true,
  bots_enabled: true,
  team_size: 1,
  match_duration_ms: 180_000,
  respawn_time_ms: 5000,
  map_mode_params: [
    %{
      amount_of_players: 12,
      initial_positions: [
        %{x: -4961, y: 5001},
        %{x: -2417, y: 5103},
        %{x: 952, y: 5603},
        %{x: 4695, y: 4859},
        %{x: 5632, y: 2753},
        %{x: 5242, y: -316},
        %{x: 4908, y: -3698},
        %{x: 2442, y: -5476},
        %{x: -897, y: -5296},
        %{x: -4871, y: -4868},
        %{x: -4897, y: -2416},
        %{x: -5047, y: 853}
      ],
      map_id: merliot_map_configuration.id
    },
    %{
      amount_of_players: 7,
      initial_positions: [
        %{x: 5400, y: -400.0},
        %{x: -5300, y: 400.0},
        %{x: 1100, y: 5100},
        %{x: 3200, y: -4300},
        %{x: -3400, y: 3600},
        %{x: -1900, y: -5100},
        %{x: 4200, y: 3200}
      ],
      team_team_initial_positions: [],
      map_id: araban_map_configuration.id
    }
  ]
}

duo_mode_params = %{
  type: "battle_royale",
  zone_enabled: true,
  bots_enabled: true,
  match_duration_ms: 180_000,
  respawn_time_ms: 5000,
  team_size: 2,
  map_mode_params: [
    %{
      amount_of_players: 12,
      initial_positions: [
        %{x: -5346, y: 4709},
        %{x: -4632, y: 5222},
        %{x: 4631, y: 5480},
        %{x: 5359, y: 4872},
        %{x: 5457, y: 1768},
        %{x: 5431, y: 1322},
        %{x: 5344, y: -4468},
        %{x: 4439, y: -5333},
        %{x: -4730, y: -5243},
        %{x: -5381, y: -4555},
        %{x: -5554, y: -929},
        %{x: -5476, y: -330}
      ],
      map_id: merliot_map_configuration.id
    }
  ],
  version_id: version.id
}

trio_mode_params = %{
  type: "battle_royale",
  zone_enabled: true,
  bots_enabled: true,
  match_duration_ms: 180_000,
  respawn_time_ms: 5000,
  team_size: 3,
  map_mode_params: [
    %{
      amount_of_players: 12,
      initial_positions: [
        %{x: -5378, y: 4702},
        %{x: -4871, y: 4691},
        %{x: -4680, y: 4242},
        %{x: 4758, y: 5226},
        %{x: 5355, y: 4941},
        %{x: 4820, y: 4505},
        %{x: 4829, y: -4831},
        %{x: 4394, y: -5153},
        %{x: 5173, y: -5475},
        %{x: -3979, y: -5396},
        %{x: -4344, y: -5128},
        %{x: -4803, y: -5521}
      ],
      map_id: merliot_map_configuration.id
    }
  ],
  version_id: version.id
}

{:ok, _battle} = GameBackend.Configuration.create_game_mode_configuration(battle_mode_params)

{:ok, _deathmatch} =
  GameBackend.Configuration.create_game_mode_configuration(deathmatch_mode_params)

{:ok, _duo} = GameBackend.Configuration.create_game_mode_configuration(duo_mode_params)

{:ok, _trio} = GameBackend.Configuration.create_game_mode_configuration(trio_mode_params)

{:ok, _quick_game} = GameBackend.Configuration.create_game_mode_configuration(quick_game_params)

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
