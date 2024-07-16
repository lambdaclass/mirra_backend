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
  skills: %{
    "1": "muflus_crush",
    "2": "muflus_leap",
    "3": "muflus_dash"
  }
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
  skills: %{
    "1": "h4ck_slingshot",
    "2": "h4ck_denial_of_service",
    "3": "h4ck_dash"
  }
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
  skills: %{
    "1": "uma_avenge",
    "2": "uma_veil_radiance",
    "3": "uma_sneak"
  }
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
  skills: %{
    "1": "valt_antimatter",
    "2": "valt_singularity",
    "3": "valt_warp"
  }
}

# Insert characters
[muflus_params, h4ck_params, uma_params, valtimer_params]
|> Enum.each(fn char_params ->
  Map.put(char_params, :game_id, curse_of_mirra_id)
  |> Map.put(:faction, "none")
  |> Characters.insert_character()
end)

game_configuration_1 = %{
  tick_rate_ms: 30,
  bounty_pick_time_ms: 5000,
  start_game_time_ms: 10000,
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
  match_timeout_ms: 300_000
}

{:ok, _game_configuration_1} =
  GameBackend.Configuration.create_game_configuration(game_configuration_1)

map_config = %{
  radius: 5520.0,
  initial_positions: [
    %{
      x: 4600.0,
      y: 0.0
    },
    %{
      x: -4600.0,
      y: 0.0
    },
    %{
      x: -1725.0,
      y: 4025.0
    },
    %{
      x: 1725.0,
      y: -4025.0
    },
    %{
      x: 1725.0,
      y: 4025.0
    },
    %{
      x: -1725.0,
      y: -4025.0
    },
    %{
      x: 4000.0,
      y: 2300.0
    },
    %{
      x: -4000.0,
      y: -2300.0
    },
    %{
      x: -4000.0,
      y: 2300.0
    },
    %{
      x: 4000.0,
      y: -2300.0
    }
  ],
  obstacles: [
    %{
      name: "door",
      position: %{
        x: -6957.6,
        y: -1657.85
      },
      radius: 1800.05,
      shape: "circle",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
      vertices: []
    },
    %{
      name: "sand_cascade",
      position: %{
        x: -3998.0,
        y: 3939.0
      },
      radius: 365.55,
      shape: "circle",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
      vertices: []
    },
    %{
      name: "top_right_spikes",
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "dynamic",
      vertices: [
        %{
          x: 2600.0,
          y: 3350.0
        },
        %{
          x: 2250.0,
          y: 3600.0
        },
        %{
          x: 3000.0,
          y: 4550.0
        },
        %{
          x: 3350.0,
          y: 4300.0
        }
      ],
      base_status: "underground",
      statuses_cycle: %{
        underground: %{
          transition_time_ms: 3000,
          on_activation_mechanics: %{},
          next_status: "raised",
          time_until_transition_ms: 10000,
          make_obstacle_collisionable: false
        },
        raised: %{
          transition_time_ms: 3000,
          on_activation_mechanics: %{
            polygon_hit: %{
              damage: 10,
              vertices: [
                %{
                  x: 2600.0,
                  y: 3350.0
                },
                %{
                  x: 2350.0,
                  y: 3700.0
                },
                %{
                  x: 3000.0,
                  y: 4550.0
                },
                %{
                  x: 3350.0,
                  y: 4300.0
                }
              ]
            }
          },
          next_status: "underground",
          time_until_transition_ms: 10000,
          make_obstacle_collisionable: true
        }
      }
    },
    %{
      name: "left_spikes",
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "dynamic",
      vertices: [
        %{
          x: -4000.0,
          y: -1250.0
        },
        %{
          x: -4000.0,
          y: -900.0
        },
        %{
          x: -5500.0,
          y: -900.0
        },
        %{
          x: -5500.0,
          y: -1250.0
        }
      ],
      base_status: "underground",
      statuses_cycle: %{
        underground: %{
          transition_time_ms: 3000,
          on_activation_mechanics: %{},
          next_status: "raised",
          time_until_transition_ms: 10000,
          make_obstacle_collisionable: false
        },
        raised: %{
          transition_time_ms: 3000,
          on_activation_mechanics: %{
            polygon_hit: %{
              damage: 10,
              vertices: [
                %{
                  x: -4000.0,
                  y: -1250.0
                },
                %{
                  x: -4000.0,
                  y: -900.0
                },
                %{
                  x: -5500.0,
                  y: -900.0
                },
                %{
                  x: -5500.0,
                  y: -1250.0
                }
              ]
            }
          },
          next_status: "underground",
          time_until_transition_ms: 10000,
          make_obstacle_collisionable: true
        }
      }
    },
    %{
      name: "center_left_spikes",
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "dynamic",
      vertices: [
        %{
          x: -1420.0,
          y: 2235.0
        },
        %{
          x: -1201.0,
          y: 2585.0
        },
        %{
          x: -180.0,
          y: 1899.0
        },
        %{
          x: -374.0,
          y: 1545.0
        }
      ],
      base_status: "underground",
      statuses_cycle: %{
        underground: %{
          transition_time_ms: 3000,
          on_activation_mechanics: %{},
          next_status: "raised",
          time_until_transition_ms: 10000,
          make_obstacle_collisionable: false
        },
        raised: %{
          transition_time_ms: 3000,
          on_activation_mechanics: %{
            polygon_hit: %{
              damage: 10,
              vertices: [
                %{
                  x: -1420.0,
                  y: 2235.0
                },
                %{
                  x: -1201.0,
                  y: 2585.0
                },
                %{
                  x: -180.0,
                  y: 1899.0
                },
                %{
                  x: -374.0,
                  y: 1545.0
                }
              ]
            }
          },
          next_status: "underground",
          time_until_transition_ms: 10000,
          make_obstacle_collisionable: true
        }
      }
    },
    %{
      name: "bottom_right_spikes",
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "dynamic",
      vertices: [
        %{
          x: 2717.0,
          y: -1951.0
        },
        %{
          x: 2411.0,
          y: -1687.0
        },
        %{
          x: 3296.0,
          y: -832.0
        },
        %{
          x: 3601.0,
          y: -1096.0
        }
      ],
      base_status: "underground",
      statuses_cycle: %{
        underground: %{
          transition_time_ms: 3000,
          on_activation_mechanics: %{},
          next_status: "raised",
          time_until_transition_ms: 10000,
          make_obstacle_collisionable: false
        },
        raised: %{
          transition_time_ms: 3000,
          on_activation_mechanics: %{
            polygon_hit: %{
              damage: 10,
              vertices: [
                %{
                  x: 2717.0,
                  y: -1951.0
                },
                %{
                  x: 2411.0,
                  y: -1687.0
                },
                %{
                  x: 3296.0,
                  y: -832.0
                },
                %{
                  x: 3601.0,
                  y: -1096.0
                }
              ]
            }
          },
          next_status: "underground",
          time_until_transition_ms: 10000,
          make_obstacle_collisionable: true
        }
      }
    },
    %{
      name: "middle stone north",
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
      name: "middle stone south",
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
      vertices: [
        %{
          x: -499.0,
          y: 1844.0
        },
        %{
          x: 222.0,
          y: 1937.0
        },
        %{
          x: 737.0,
          y: 1770.0
        },
        %{
          x: 831.0,
          y: 1570.0
        },
        %{
          x: 643.0,
          y: 1485.0
        },
        %{
          x: -425.0,
          y: 1416.0
        }
      ]
    },
    %{
      name: "carapace 1",
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
          y: -2600.0
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
          x: 4600.0,
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
      vertices: [
        %{
          x: 470.0,
          y: -4100.0
        },
        %{
          x: 790.0,
          y: -3950.0
        },
        %{
          x: 1300.0,
          y: -4450.0
        },
        %{
          x: 1300.0,
          y: -6500.0
        },
        %{
          x: 360.0,
          y: -6500.0
        },
        %{
          x: 360.0,
          y: -4700.0
        }
      ]
    },
    %{
      name: "cannon rock 1 b",
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
      vertices: [
        %{
          x: -770.0,
          y: -5850.0
        },
        %{
          x: 360.0,
          y: -4700.0
        },
        %{
          x: 1150.0,
          y: -5470.0
        },
        %{
          x: 1150.0,
          y: -8000.0
        },
        %{
          x: -770.0,
          y: -8000.0
        }
      ]
    },
    %{
      name: "cannon rock 2 a",
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
      vertices: [
        %{
          x: -849.0,
          y: 4252.0
        },
        %{
          x: -1120.0,
          y: 4900.0
        },
        %{
          x: -1120.0,
          y: 6500.0
        },
        %{
          x: -135.0,
          y: 6500.0
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
          y: 6500.0
        },
        %{
          x: 1226.0,
          y: 6500.0
        }
      ]
    },
    %{
      name: "halfmoon rock 1 a",
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 0.0,
      shape: "polygon",
      type: "static",
      statuses_cycle: %{},
      base_status: "",
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
          x: -5000.0,
          y: 3897.0
        },
        %{
          x: -5000.0,
          y: 5248.0
        }
      ]
    }
  ],
  bushes: []
}

{:ok, _map_configuration_1} = GameBackend.Configuration.create_map_configuration(map_config)

GameBackend.CurseOfMirra.Config.import_quest_descriptions_config()

################### END CURSE OF MIRRA ###################
