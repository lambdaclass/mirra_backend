# defmodule GameBackend.Units.Skills.Effects.Execution do
#   @moduledoc """
#   Executions are more complex ways to deal with attributes, for example, dealing damage.

#   Depending on the execution calc used, different things will happen. For example, in the case of Damage, it can:

#   - Prevent the damage from happening, through stats like Dodge
#   - Determine how much energy the target will recover when being damaged by that skill.
#       - Note that any individual instance of a skill should only be able to charge energy to the same target once,
#         so if a skill hits all targets 5 times, only the first time will trigger energy gain.
#   - Reduce the damage taken based on the defense, or stats like damage reduction.
#   - Etc.

#   Examples:
#       # DealDamage effect that hits for 80% of attack, gives 50 energy to its target and has no delay
#       %Effect{
#         "type" => "DealDamage",
#         "attack_ratio" => 0.8,
#         "energy_recharge" => 50,
#         "delay" => 0
#       }
#   """

#   use Ecto.Type

#   def type(), do: :string

#   def cast(%{
#         "type" => "DealDamage",
#         "attack_ratio" => attack_ratio,
#         "energy_recharge" => energy_recharge,
#         "delay" => delay
#       }),
#       do:
#         {:ok,
#          %{
#            "type" => "DealDamage",
#            "attack_ratio" => attack_ratio,
#            "energy_recharge" => energy_recharge,
#            "delay" => delay
#          }}

#   def cast(%{
#         "type" => "Heal",
#         "attack_ratio" => attack_ratio,
#         "delay" => delay
#       }),
#       do:
#         {:ok,
#          %{
#            "type" => "Heal",
#            "attack_ratio" => attack_ratio,
#            "delay" => delay
#          }}

#   def cast(%{
#         "type" => "AddEnergy",
#         "amount" => amount
#       }),
#       do:
#         {:ok,
#          %{
#            "type" => "AddEnergy",
#            "amount" => amount
#          }}

#   def load(string), do: {:ok, execution_from_string(string)}

#   def dump(execution), do: {:ok, execution_to_string(execution)}

#   defp execution_to_string(execution) do
#     case execution do
#       %{
#         "type" => "DealDamage",
#         "attack_ratio" => attack_ratio,
#         "energy_recharge" => energy_recharge,
#         "delay" => delay
#       } ->
#         "DealDamage,#{attack_ratio},#{energy_recharge},#{delay}"

#       %{
#         "type" => "Heal",
#         "attack_ratio" => attack_ratio,
#         "delay" => delay
#       } ->
#         "Heal,#{attack_ratio},#{delay}"

#       %{
#         "type" => "AddEnergy",
#         "amount" => amount
#       } ->
#         "AddEnergy,#{amount}"
#     end
#   end

#   defp execution_from_string(string) when is_binary(string) do
#     case String.split(string, ",") do
#       ["DealDamage", attack_ratio, energy_recharge, delay] ->
#         %{
#           type: "DealDamage",
#           attack_ratio: String.to_float(attack_ratio),
#           energy_recharge: String.to_integer(energy_recharge),
#           delay: String.to_integer(delay)
#         }

#       ["Heal", attack_ratio, delay] ->
#         %{type: "Heal", attack_ratio: String.to_float(attack_ratio), delay: String.to_integer(delay)}

#       ["AddEnergy", amount] ->
#         %{type: "AddEnergy", amount: String.to_integer(amount)}

#       _ ->
#         nil
#     end
#   end
# end
