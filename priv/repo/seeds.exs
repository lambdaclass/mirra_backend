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
      damage: 15,
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
        damage: 17,
        effect_delay_ms: 220,
        execute_multiple_times: true
      }
    ]
  }

invisible_effect =
  %{
    name: "invisible",
    duration_ms: 4000,
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
        modifier: 0.25,
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
    one_time_application: false,
    allow_multiple_effects: true,
    disabled_outside_pool: true,
    effect_mechanics: [
      %{
        name: "defense_change",
        modifier: 0.75,
        effect_delay_ms: 0,
        execute_multiple_times: false
      }
    ]
  }

buff_singularity_effect =
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
      damage: 13,
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
      damage: 20,
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
      damage: 10,
      effect_delay_ms: 250,
      execute_multiple_times: true
    },
    %{
      name: "damage",
      damage: 50,
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
      "damage" => 58,
      "range" => 250.0,
      "offset" => 0
    }
  ],
  "on_collide_effect" => %{
    "apply_effect_to_entity_type" => [
      "pool"
    ],
    "effect" => buff_singularity_effect
  }
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
  "radius" => 400.0,
  "range" => 0.0,
  "shape" => "circle",
  "vertices" => [],
  "effect" => inferno_effect
}

toxic_onion_explosion = %{
  "name" => "toxic_onion_explosion",
  "type" => "circle_hit",
  "damage" => 58,
  "range" => 250.0,
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
  "range" => 700,
  "on_explode_mechanics" => [
    toxic_onion_explosion
  ]
}

putrid_elixir_bomb = %{
  "name" => "putrid_elixir_bomb",
  "type" => "spawn_pool",
  "activation_delay" => 250,
  "duration_ms" => 8000,
  "radius" => 400.0,
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
    ],
    "version_id" => version.id
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
    ],
    "version_id" => version.id
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
    ],
    "version_id" => version.id
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
        "effect" => denial_of_service
      }
    ],
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
    "on_owner_effect" => invisible_effect,
    "version_id" => version.id
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
    "on_owner_effect" => whirlwind_effect,
    "version_id" => version.id
  },
  %{
    "name" => "kenzu_pounce",
    "type" => "dash",
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
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 10000,
    "execution_duration_ms" => 525,
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
    "cooldown_mechanism" => "time",
    "cooldown_ms" => 4000,
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
        "speed" => 4,
        "duration_ms" => 250
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
  active: true,
  base_speed: 0.62,
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
  active: true,
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

shinko_params = %{
  name: "shinko",
  active: true,
  base_speed: 0.68,
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
  active: true,
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
  radius: 5520.0,
  active: false,
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
          y: 12000.0
        },
        %{
          x: 12000.0,
          y: 12000.0
        },
        %{
          x: 12000.0,
          y: -12000.0
        },
        %{
          x: 6400.0,
          y: -12000.0
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
          y: 12000.0
        },
        %{
          x: -6400.0,
          y: 12000.0
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
          y: 12000.0
        },
        %{
          x: -12000.0,
          y: 12000.0
        },
        %{
          x: -12000.0,
          y: -12000.0
        },
        %{
          x: -6400.0,
          y: -12000.0
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
          y: -12000.0
        },
        %{
          x: -6400.0,
          y: -12000.0
        }
      ]
    },
    %{
      name: "Center Bottom Left Top Wall",
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
        %{x: -2140, y: -319},
        %{x: -1991, y: -315},
        %{x: -1962, y: -981},
        %{x: -2169, y: -985}
      ]
    },
    %{
      name: "Center Bottom Left Mid Wall",
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
        %{x: -2169, y: -985},
        %{x: -1962, y: -981},
        %{x: -1602, y: -1295},
        %{x: -1743, y: -1444}
      ]
    },
    %{
      name: "Center Bottom Left Down Wall",
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
        %{x: -1289, y: -1586},
        %{x: -836, y: -2083},
        %{x: -938, y: -2196},
        %{x: -1446, y: -1746},
        %{x: -1446, y: -1746}
      ]
    },
    %{
      name: "Center Bottom Right Down Wall",
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
        %{x: 341, y: -2144},
        %{x: 341, y: -2010},
        %{x: 982, y: -2010},
        %{x: 994, y: -2185}
      ]
    },
    %{
      name: "Center Bottom Right Mid Wall",
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
        %{x: 994, y: -2185},
        %{x: 982, y: -2010},
        %{x: 1329, y: -1615},
        %{x: 1472, y: -1751}
      ]
    },
    %{
      name: "Center Bottom Right Top Wall",
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
        %{x: 1777, y: -1457},
        %{x: 1608, y: -1317},
        %{x: 2108, y: -854},
        %{x: 2226, y: -961}
      ]
    },
    %{
      name: "Center Top Left Bottom Wall",
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
        %{x: -2173, y: 922},
        %{x: -1710, y: 1433},
        %{x: -1566, y: 1305},
        %{x: -2055, y: 826}
      ]
    },
    %{
      name: "Center Top Left Mid Wall",
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
        %{x: -1281, y: 1622},
        %{x: -1412, y: 1722},
        %{x: -966, y: 2183},
        %{x: -961, y: 2006}
      ]
    },
    %{
      name: "Center Top Left Top Wall",
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
        %{x: -966, y: 2183},
        %{x: -961, y: 2006},
        %{x: -310, y: 2013},
        %{x: -310, y: 2157}
      ]
    },
    %{
      name: "Center Top Right Bottom Wall",
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
        %{x: 2137, y: 355},
        %{x: 1969, y: 342},
        %{x: 1956, y: 990},
        %{x: 2159, y: 990}
      ]
    },
    %{
      name: "Center Top Right Mid Wall",
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
        %{x: 2159, y: 990},
        %{x: 1961, y: 990},
        %{x: 1576, y: 1313},
        %{x: 1712, y: 1449}
      ]
    },
    %{
      name: "Center Top Right Top Wall",
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
        %{x: 1410, y: 1748},
        %{x: 1269, y: 1610},
        %{x: 797, y: 2086},
        %{x: 910, y: 2182}
      ]
    },
    %{
      name: "Bottom Mid Rock",
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
        %{x: 921, y: -6393},
        %{x: 987, y: -5753},
        %{x: 1873, y: -5819},
        %{x: 2669, y: -6131},
        %{x: 2653, y: -6443},
        %{x: 1775, y: -6509}
      ]
    },
    %{
      name: "Right Bottom Rock",
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
        %{x: 5571, y: -3342},
        %{x: 6721, y: -3586},
        %{x: 6530, y: -4611}
      ]
    },
    %{
      name: "Right Top Rock",
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
        %{x: 6538, y: 624},
        %{x: 5741, y: 548},
        %{x: 5850, y: 1513},
        %{x: 6110, y: 2243},
        %{x: 6538, y: 2268}
      ]
    },
    %{
      name: "Top Right Rock",
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
        %{x: 3691, y: 6589},
        %{x: 4221, y: 6589},
        %{x: 4641, y: 6069},
        %{x: 3751, y: 5499},
        %{x: 3236, y: 5565}
      ]
    },
    %{
      name: "Top Left Rock",
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
        %{x: -738, y: 5739},
        %{x: -738, y: 5959},
        %{x: -1078, y: 6619},
        %{x: -2568, y: 6539},
        %{x: -2578, y: 6189},
        %{x: -1938, y: 5789},
        %{x: -1288, y: 5659}
      ]
    },
    %{
      name: "Left Top Rock",
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
        %{x: -6458, y: 4619},
        %{x: -5866, y: 4027},
        %{x: -5648, y: 3000},
        %{x: -6596, y: 3000}
      ]
    },
    %{
      name: "Left Bottom Rock",
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
        %{x: -6398, y: -610},
        %{x: -5728, y: -660},
        %{x: -5718, y: -1290},
        %{x: -5818, y: -1810},
        %{x: -6278, y: -2290},
        %{x: -6478, y: -2320}
      ]
    },
    %{
      name: "Bottom Rock and Tree",
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
        %{x: 1259, y: -3918},
        %{x: 1266, y: -3457},
        %{x: 2030, y: -3319},
        %{x: 2188, y: -3622},
        %{x: 1775, y: -3897}
      ]
    },
    %{
      name: "TopLeft - RockTreeBush - Rock",
      type: "static",
      radius: 250,
      shape: "circle",
      position: %{x: -1283, y: 3909},
      vertices: []
    },
    %{
      name: "TopLeft - RockTreeBush - Tree",
      type: "static",
      radius: 250,
      shape: "circle",
      position: %{x: -1679, y: 3690},
      vertices: []
    },
    %{
      name: "MidBottomLeft - TreeBush - Trees",
      type: "static",
      radius: 550,
      shape: "circle",
      position: %{x: -1759, y: -3426},
      vertices: []
    },
    %{
      name: "MidBottomRight - TreeBush - Trees",
      type: "static",
      radius: 500,
      shape: "circle",
      position: %{x: 3424, y: -1564},
      vertices: []
    },
    %{
      name: "MidTopRight - TreeBush - Trees",
      type: "static",
      radius: 500,
      shape: "circle",
      position: %{x: 1873, y: 3276},
      vertices: []
    },
    %{
      name: "MidTopLeft - TreeBush - Trees",
      type: "static",
      radius: 400,
      shape: "circle",
      position: %{x: -3200, y: 1300},
      vertices: []
    },
    %{
      name: "Left Top Water 1",
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
        %{x: -4360, y: 2759},
        %{x: -3871, y: 2734},
        %{x: -3896, y: 1900},
        %{x: -4900, y: 1800}
      ]
    },
    %{
      name: "Left Top Water 2",
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
        %{x: -3871, y: 2734},
        %{x: -3167, y: 3087},
        %{x: -2743, y: 2204},
        %{x: -3896, y: 1900}
      ]
    },
    %{
      name: "Left Top Water 3",
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
        %{x: -4900, y: 1800},
        %{x: -3216, y: 2150},
        %{x: -3569, y: 1139},
        %{x: -4555, y: 1139}
      ]
    },
    %{
      name: "Left Top Water 4",
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
        %{x: -4555, y: 1139},
        %{x: -3569, y: 1139},
        %{x: -3500, y: 500},
        %{x: -4345, y: 400}
      ]
    },
    %{
      name: "Left Bottom Water 1",
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
        %{x: -3117, y: -2705},
        %{x: -2539, y: -2550},
        %{x: -1953, y: -3549},
        %{x: -2872, y: -3743}
      ]
    },
    %{
      name: "Left Bottom Water 2",
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
        %{x: -2872, y: -3743},
        %{x: -1953, y: -3549},
        %{x: -1788, y: -4935},
        %{x: -3029, y: -4477}
      ]
    },
    %{
      name: "Left Bottom Water 3",
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
        %{x: -1953, y: -3549},
        %{x: -837, y: -3421},
        %{x: -532, y: -4091},
        %{x: -1788, y: -4935}
      ]
    },
    %{
      name: "Close to Wall Top Left Water",
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
        %{x: -6430, y: 3520},
        %{x: -5150, y: 3016},
        %{x: -5600, y: 2132},
        %{x: -6439, y: 2505}
      ]
    },
    %{
      name: "Close to Wall Top Right Water",
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
        %{x: 2496, y: 6558},
        %{x: 3691, y: 6546},
        %{x: 3236, y: 5565},
        %{x: 2209, y: 6059}
      ]
    },
    %{
      name: "Close To Wall Bottom Left Water",
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
        %{x: -3168, y: -5127},
        %{x: -2062, y: -5648},
        %{x: -2530, y: -6395},
        %{x: -3665, y: -6404}
      ]
    },
    %{
      name: "Close To Wall Bottom Right Water",
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
        %{x: 6046, y: -2263},
        %{x: 6579, y: -2499},
        %{x: 6534, y: -3543},
        %{x: 5571, y: -3342}
      ]
    },
    %{
      name: "Bottom Mid Water 1",
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
        %{x: -272, y: -3195},
        %{x: 596, y: -3003},
        %{x: 808, y: -3648},
        %{x: -23, y: -3927}
      ]
    },
    %{
      name: "Bottom Mid Water 2",
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
        %{x: 596, y: -3003},
        %{x: 2056, y: -2643},
        %{x: 2260, y: -3295},
        %{x: 808, y: -3648}
      ]
    },
    %{
      name: "Top Mid Water 2",
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
        %{x: -2438, y: 3333},
        %{x: -50, y: 4148},
        %{x: 250, y: 3280},
        %{x: -2076, y: 2509}
      ]
    },
    %{
      name: "Right Mid Water 1",
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
        %{x: 2664, y: 2310},
        %{x: 3299, y: 2519},
        %{x: 3659, y: 1608},
        %{x: 2966, y: 1407}
      ]
    },
    %{
      name: "Right Mid Water 2",
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
        %{x: 2966, y: 1407},
        %{x: 3659, y: 1608},
        %{x: 4035, y: -68},
        %{x: 3478, y: -200}
      ]
    },
    %{
      name: "Left Mid Water 1",
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
        %{x: -4107, y: -343},
        %{x: -3368, y: -169},
        %{x: -3147, y: -871},
        %{x: -3957, y: -1003}
      ]
    },
    %{
      name: "Left Mid Water 2",
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
        %{x: -3952, y: -1002},
        %{x: -3142, y: -870},
        %{x: -2826, y: -2024},
        %{x: -3448, y: -2203}
      ]
    },
    %{
      name: "Bottom Right Water 1",
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
        %{x: 2653, y: -2438},
        %{x: 3633, y: -1502},
        %{x: 4470, y: -2860},
        %{x: 2792, y: -3186}
      ]
    },
    %{
      name: "Bottom Right Water 1 prima",
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
        %{x: 3633, y: -1502},
        %{x: 4896, y: -2963},
        %{x: 4470, y: -2860}
      ]
    },
    %{
      name: "Bottom Right Water 2",
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
        %{x: 3615, y: -694},
        %{x: 4212, y: -509},
        %{x: 4629, y: -1281},
        %{x: 3630, y: -1498}
      ]
    },
    %{
      name: "Bottom Right Water 3",
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
        %{x: 3630, y: -1498},
        %{x: 4629, y: -1281},
        %{x: 5371, y: -1881},
        %{x: 4896, y: -2963}
      ]
    },
    %{
      name: "Top Right Water 1",
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
        %{x: 3029, y: 3061},
        %{x: 2381, y: 2856},
        %{x: 1717, y: 3634},
        %{x: 2762, y: 4031}
      ]
    },
    %{
      name: "Top Right Water 2",
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
        %{x: 565, y: 4300},
        %{x: 1455, y: 4700},
        %{x: 1717, y: 3634},
        %{x: 808, y: 3500}
      ]
    },
    %{
      name: "Top Right Water 3",
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
        %{x: 1455, y: 4700},
        %{x: 1802, y: 5366},
        %{x: 3000, y: 4737},
        %{x: 2762, y: 4031},
        %{x: 1717, y: 3634}
      ]
    }
  ],
  bushes: [
    %{
      name: "Top Left Corner",
      radius: 1000,
      shape: "circle",
      position: %{x: -6390, y: 6550},
      vertices: []
    },
    %{
      name: "Top Right Corner",
      radius: 1000,
      shape: "circle",
      position: %{x: 6390, y: 6550},
      vertices: []
    },
    %{
      name: "Bottom Left Corner",
      radius: 1000,
      shape: "circle",
      position: %{x: -6390, y: -6550},
      vertices: []
    },
    %{
      name: "Bottom Right Corner",
      radius: 1000,
      shape: "circle",
      position: %{x: 6390, y: -6550},
      vertices: []
    },
    %{
      name: "TopLeft - RockTreeBush - Bush",
      radius: 250,
      shape: "circle",
      position: %{x: -1610, y: 3994},
      vertices: []
    },
    %{
      name: "MidBottomLeft - TreeBush - Bush",
      radius: 800,
      shape: "circle",
      position: %{x: -1759, y: -3426},
      vertices: []
    },
    %{
      name: "MidBottomRight - TreeBush - Bush",
      radius: 750,
      shape: "circle",
      position: %{x: 3350, y: -1634},
      vertices: []
    },
    %{
      name: "MidTopLeft - TreeBush - Bush",
      radius: 650,
      shape: "circle",
      position: %{x: -3200, y: 1300},
      vertices: []
    },
    %{
      name: "MidTopRight - TreeBush - Bush",
      radius: 700,
      shape: "circle",
      position: %{x: 1873, y: 3276},
      vertices: []
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

team_merliot_map_config = %{
  name: "Merliot",
  radius: 15000.0,
  active: false,
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
          y: 12000.0
        },
        %{
          x: 12000.0,
          y: 12000.0
        },
        %{
          x: 12000.0,
          y: -12000.0
        },
        %{
          x: 6400.0,
          y: -12000.0
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
          y: 12000.0
        },
        %{
          x: -6400.0,
          y: 12000.0
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
          y: 12000.0
        },
        %{
          x: -12000.0,
          y: 12000.0
        },
        %{
          x: -12000.0,
          y: -12000.0
        },
        %{
          x: -6400.0,
          y: -12000.0
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
          y: -12000.0
        },
        %{
          x: -6400.0,
          y: -12000.0
        }
      ]
    },
    %{
      name: "Center Bottom Left Top Wall",
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
        %{x: -2140, y: -319},
        %{x: -1991, y: -315},
        %{x: -1962, y: -981},
        %{x: -2169, y: -985}
      ]
    },
    %{
      name: "Center Bottom Left Mid Wall",
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
        %{x: -2169, y: -985},
        %{x: -1962, y: -981},
        %{x: -1602, y: -1295},
        %{x: -1743, y: -1444}
      ]
    },
    %{
      name: "Center Bottom Left Down Wall",
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
        %{x: -1289, y: -1586},
        %{x: -836, y: -2083},
        %{x: -938, y: -2196},
        %{x: -1446, y: -1746},
        %{x: -1446, y: -1746}
      ]
    },
    %{
      name: "Center Bottom Right Down Wall",
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
        %{x: 341, y: -2144},
        %{x: 341, y: -2010},
        %{x: 982, y: -2010},
        %{x: 994, y: -2185}
      ]
    },
    %{
      name: "Center Bottom Right Mid Wall",
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
        %{x: 994, y: -2185},
        %{x: 982, y: -2010},
        %{x: 1329, y: -1615},
        %{x: 1472, y: -1751}
      ]
    },
    %{
      name: "Center Bottom Right Top Wall",
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
        %{x: 1777, y: -1457},
        %{x: 1608, y: -1317},
        %{x: 2108, y: -854},
        %{x: 2226, y: -961}
      ]
    },
    %{
      name: "Center Top Left Bottom Wall",
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
        %{x: -2173, y: 922},
        %{x: -1710, y: 1433},
        %{x: -1566, y: 1305},
        %{x: -2055, y: 826}
      ]
    },
    %{
      name: "Center Top Left Mid Wall",
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
        %{x: -1281, y: 1622},
        %{x: -1412, y: 1722},
        %{x: -966, y: 2183},
        %{x: -961, y: 2006}
      ]
    },
    %{
      name: "Center Top Left Top Wall",
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
        %{x: -966, y: 2183},
        %{x: -961, y: 2006},
        %{x: -310, y: 2013},
        %{x: -310, y: 2157}
      ]
    },
    %{
      name: "Center Top Right Bottom Wall",
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
        %{x: 2137, y: 355},
        %{x: 1969, y: 342},
        %{x: 1956, y: 990},
        %{x: 2159, y: 990}
      ]
    },
    %{
      name: "Center Top Right Mid Wall",
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
        %{x: 2159, y: 990},
        %{x: 1961, y: 990},
        %{x: 1576, y: 1313},
        %{x: 1712, y: 1449}
      ]
    },
    %{
      name: "Center Top Right Top Wall",
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
        %{x: 1410, y: 1748},
        %{x: 1269, y: 1610},
        %{x: 797, y: 2086},
        %{x: 910, y: 2182}
      ]
    },
    %{
      name: "Bottom Mid Rock",
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
        %{x: 921, y: -6393},
        %{x: 987, y: -5753},
        %{x: 1873, y: -5819},
        %{x: 2669, y: -6131},
        %{x: 2653, y: -6443},
        %{x: 1775, y: -6509}
      ]
    },
    %{
      name: "Right Bottom Rock",
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
        %{x: 5571, y: -3342},
        %{x: 6721, y: -3586},
        %{x: 6530, y: -4611}
      ]
    },
    %{
      name: "Right Top Rock",
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
        %{x: 6538, y: 624},
        %{x: 5741, y: 548},
        %{x: 5850, y: 1513},
        %{x: 6110, y: 2243},
        %{x: 6538, y: 2268}
      ]
    },
    %{
      name: "Top Right Rock",
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
        %{x: 3691, y: 6589},
        %{x: 4221, y: 6589},
        %{x: 4641, y: 6069},
        %{x: 3751, y: 5499},
        %{x: 3236, y: 5565}
      ]
    },
    %{
      name: "Top Left Rock",
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
        %{x: -738, y: 5739},
        %{x: -738, y: 5959},
        %{x: -1078, y: 6619},
        %{x: -2568, y: 6539},
        %{x: -2578, y: 6189},
        %{x: -1938, y: 5789},
        %{x: -1288, y: 5659}
      ]
    },
    %{
      name: "Left Top Rock",
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
        %{x: -6458, y: 4619},
        %{x: -5866, y: 4027},
        %{x: -5648, y: 3000},
        %{x: -6596, y: 3000}
      ]
    },
    %{
      name: "Left Bottom Rock",
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
        %{x: -6398, y: -610},
        %{x: -5728, y: -660},
        %{x: -5718, y: -1290},
        %{x: -5818, y: -1810},
        %{x: -6278, y: -2290},
        %{x: -6478, y: -2320}
      ]
    },
    %{
      name: "Bottom Rock and Tree",
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
        %{x: 1259, y: -3918},
        %{x: 1266, y: -3457},
        %{x: 2030, y: -3319},
        %{x: 2188, y: -3622},
        %{x: 1775, y: -3897}
      ]
    },
    %{
      name: "TopLeft - RockTreeBush - Rock",
      type: "static",
      radius: 250,
      shape: "circle",
      position: %{x: -1283, y: 3909},
      vertices: []
    },
    %{
      name: "TopLeft - RockTreeBush - Tree",
      type: "static",
      radius: 250,
      shape: "circle",
      position: %{x: -1679, y: 3690},
      vertices: []
    },
    %{
      name: "MidBottomLeft - TreeBush - Trees",
      type: "static",
      radius: 550,
      shape: "circle",
      position: %{x: -1759, y: -3426},
      vertices: []
    },
    %{
      name: "MidBottomRight - TreeBush - Trees",
      type: "static",
      radius: 500,
      shape: "circle",
      position: %{x: 3424, y: -1564},
      vertices: []
    },
    %{
      name: "MidTopRight - TreeBush - Trees",
      type: "static",
      radius: 500,
      shape: "circle",
      position: %{x: 1873, y: 3276},
      vertices: []
    },
    %{
      name: "MidTopLeft - TreeBush - Trees",
      type: "static",
      radius: 400,
      shape: "circle",
      position: %{x: -3200, y: 1300},
      vertices: []
    },
    %{
      name: "Left Top Water 1",
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
        %{x: -4360, y: 2759},
        %{x: -3871, y: 2734},
        %{x: -3896, y: 1900},
        %{x: -4900, y: 1800}
      ]
    },
    %{
      name: "Left Top Water 2",
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
        %{x: -3871, y: 2734},
        %{x: -3167, y: 3087},
        %{x: -2743, y: 2204},
        %{x: -3896, y: 1900}
      ]
    },
    %{
      name: "Left Top Water 3",
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
        %{x: -4900, y: 1800},
        %{x: -3216, y: 2150},
        %{x: -3569, y: 1139},
        %{x: -4555, y: 1139}
      ]
    },
    %{
      name: "Left Top Water 4",
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
        %{x: -4555, y: 1139},
        %{x: -3569, y: 1139},
        %{x: -3500, y: 500},
        %{x: -4345, y: 400}
      ]
    },
    %{
      name: "Left Bottom Water 1",
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
        %{x: -3117, y: -2705},
        %{x: -2539, y: -2550},
        %{x: -1953, y: -3549},
        %{x: -2872, y: -3743}
      ]
    },
    %{
      name: "Left Bottom Water 2",
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
        %{x: -2872, y: -3743},
        %{x: -1953, y: -3549},
        %{x: -1788, y: -4935},
        %{x: -3029, y: -4477}
      ]
    },
    %{
      name: "Left Bottom Water 3",
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
        %{x: -1953, y: -3549},
        %{x: -837, y: -3421},
        %{x: -532, y: -4091},
        %{x: -1788, y: -4935}
      ]
    },
    %{
      name: "Close to Wall Top Left Water",
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
        %{x: -6430, y: 3520},
        %{x: -5150, y: 3016},
        %{x: -5600, y: 2132},
        %{x: -6439, y: 2505}
      ]
    },
    %{
      name: "Close to Wall Top Right Water",
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
        %{x: 2496, y: 6558},
        %{x: 3691, y: 6546},
        %{x: 3236, y: 5565},
        %{x: 2209, y: 6059}
      ]
    },
    %{
      name: "Close To Wall Bottom Left Water",
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
        %{x: -3168, y: -5127},
        %{x: -2062, y: -5648},
        %{x: -2530, y: -6395},
        %{x: -3665, y: -6404}
      ]
    },
    %{
      name: "Close To Wall Bottom Right Water",
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
        %{x: 6046, y: -2263},
        %{x: 6579, y: -2499},
        %{x: 6534, y: -3543},
        %{x: 5571, y: -3342}
      ]
    },
    %{
      name: "Bottom Mid Water 1",
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
        %{x: -272, y: -3195},
        %{x: 596, y: -3003},
        %{x: 808, y: -3648},
        %{x: -23, y: -3927}
      ]
    },
    %{
      name: "Bottom Mid Water 2",
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
        %{x: 596, y: -3003},
        %{x: 2056, y: -2643},
        %{x: 2260, y: -3295},
        %{x: 808, y: -3648}
      ]
    },
    %{
      name: "Top Mid Water 2",
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
        %{x: -2438, y: 3333},
        %{x: -50, y: 4148},
        %{x: 250, y: 3280},
        %{x: -2076, y: 2509}
      ]
    },
    %{
      name: "Right Mid Water 1",
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
        %{x: 2664, y: 2310},
        %{x: 3299, y: 2519},
        %{x: 3659, y: 1608},
        %{x: 2966, y: 1407}
      ]
    },
    %{
      name: "Right Mid Water 2",
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
        %{x: 2966, y: 1407},
        %{x: 3659, y: 1608},
        %{x: 4035, y: -68},
        %{x: 3478, y: -200}
      ]
    },
    %{
      name: "Left Mid Water 1",
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
        %{x: -4107, y: -343},
        %{x: -3368, y: -169},
        %{x: -3147, y: -871},
        %{x: -3957, y: -1003}
      ]
    },
    %{
      name: "Left Mid Water 2",
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
        %{x: -3952, y: -1002},
        %{x: -3142, y: -870},
        %{x: -2826, y: -2024},
        %{x: -3448, y: -2203}
      ]
    },
    %{
      name: "Bottom Right Water 1",
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
        %{x: 2653, y: -2438},
        %{x: 3633, y: -1502},
        %{x: 4470, y: -2860},
        %{x: 2792, y: -3186}
      ]
    },
    %{
      name: "Bottom Right Water 1 prima",
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
        %{x: 3633, y: -1502},
        %{x: 4896, y: -2963},
        %{x: 4470, y: -2860}
      ]
    },
    %{
      name: "Bottom Right Water 2",
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
        %{x: 3615, y: -694},
        %{x: 4212, y: -509},
        %{x: 4629, y: -1281},
        %{x: 3630, y: -1498}
      ]
    },
    %{
      name: "Bottom Right Water 3",
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
        %{x: 3630, y: -1498},
        %{x: 4629, y: -1281},
        %{x: 5371, y: -1881},
        %{x: 4896, y: -2963}
      ]
    },
    %{
      name: "Top Right Water 1",
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
        %{x: 3029, y: 3061},
        %{x: 2381, y: 2856},
        %{x: 1717, y: 3634},
        %{x: 2762, y: 4031}
      ]
    },
    %{
      name: "Top Right Water 2",
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
        %{x: 565, y: 4300},
        %{x: 1455, y: 4700},
        %{x: 1717, y: 3634},
        %{x: 808, y: 3500}
      ]
    },
    %{
      name: "Top Right Water 3",
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
        %{x: 1455, y: 4700},
        %{x: 1802, y: 5366},
        %{x: 3000, y: 4737},
        %{x: 2762, y: 4031},
        %{x: 1717, y: 3634}
      ]
    }
  ],
  bushes: [
    %{
      name: "Top Left Corner",
      radius: 1000,
      shape: "circle",
      position: %{x: -6390, y: 6550},
      vertices: []
    },
    %{
      name: "Top Right Corner",
      radius: 1000,
      shape: "circle",
      position: %{x: 6390, y: 6550},
      vertices: []
    },
    %{
      name: "Bottom Left Corner",
      radius: 1000,
      shape: "circle",
      position: %{x: -6390, y: -6550},
      vertices: []
    },
    %{
      name: "Bottom Right Corner",
      radius: 1000,
      shape: "circle",
      position: %{x: 6390, y: -6550},
      vertices: []
    },
    %{
      name: "TopLeft - RockTreeBush - Bush",
      radius: 250,
      shape: "circle",
      position: %{x: -1610, y: 3994},
      vertices: []
    },
    %{
      name: "MidBottomLeft - TreeBush - Bush",
      radius: 800,
      shape: "circle",
      position: %{x: -1759, y: -3426},
      vertices: []
    },
    %{
      name: "MidBottomRight - TreeBush - Bush",
      radius: 750,
      shape: "circle",
      position: %{x: 3350, y: -1634},
      vertices: []
    },
    %{
      name: "MidTopLeft - TreeBush - Bush",
      radius: 650,
      shape: "circle",
      position: %{x: -3200, y: 1300},
      vertices: []
    },
    %{
      name: "MidTopRight - TreeBush - Bush",
      radius: 700,
      shape: "circle",
      position: %{x: 1873, y: 3276},
      vertices: []
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

{:ok, _araban_map_configuration} =
  GameBackend.Configuration.create_map_configuration(araban_map_config)

{:ok, merliot_map_configuration} =
  GameBackend.Configuration.create_map_configuration(merliot_map_config)

{:ok, _team_merliot_map_configuration} =
  GameBackend.Configuration.create_map_configuration(team_merliot_map_config)

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
  name: "battle",
  type: "battle_royale",
  zone_enabled: true,
  bots_enabled: true,
  match_duration_ms: 180_000,
  amount_of_players: 12,
  map_mode_params: [
    %{
      solo_initial_positions: [
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
      team_team_initial_positions: [],
      map_id: merliot_map_configuration.id
    }
  ]
}

deathmatch_mode_params = %{
  version_id: version.id,
  name: "deathmatch",
  type: "deathmatch",
  zone_enabled: true,
  bots_enabled: true,
  match_duration_ms: 180_000,
  amount_of_players: 12,
  respawn_time_ms: 5000,
  map_mode_params: [
    %{
      solo_initial_positions: [
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
      team_team_initial_positions: [],
      map_id: merliot_map_configuration.id
    }
  ]
}

pair_mode_params = %{
  name: "pair",
  type: "battle_royale",
  zone_enabled: true,
  bots_enabled: true,
  team_enabled: true,
  match_duration_ms: 180_000,
  amount_of_players: 12,
  respawn_time_ms: 5000,
  map_mode_params: [
    %{
      solo_initial_positions: [],
      team_initial_positions: [
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

{:ok, _battle} = GameBackend.Configuration.create_game_mode_configuration(battle_mode_params)

{:ok, _deathmatch} =
  GameBackend.Configuration.create_game_mode_configuration(deathmatch_mode_params)

{:ok, _pair} = GameBackend.Configuration.create_game_mode_configuration(pair_mode_params)

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
