defmodule ConfiguratorWeb.CustomComponents do
  @moduledoc """
  Custom components to render shared templates
  """

  import ConfiguratorWeb.CoreComponents
  use Phoenix.Component

  def effect_show(%{effect: nil} = assigns) do
    ~H"""
    <.button type="button" phx-click={show_modal("no-effect")}>Show effect</.button>
    <.modal id="no-effect">
      <h3>No Effect</h3>
    </.modal>
    """
  end

  def effect_show(assigns) do
    ~H"""
    <.button type="button" phx-click={show_modal("effect-show-#{@effect.id}")}>Show effect</.button>
    <.modal id={"effect-show-#{@effect.id}"}>
      <.list>
        <:item title="Name"><%= @effect.name %></:item>
        <:item title="Duration ms"><%= @effect.duration_ms %></:item>
        <:item title="Remove on action"><%= @effect.remove_on_action %></:item>
        <:item title="Apply effect once"><%= @effect.one_time_application %></:item>
        <:item title="Allow more that one effect instance"><%= @effect.allow_multiple_effects %></:item>
        <:item title="Consume projectile"><%= @effect.consume_projectile %></:item>
      </.list>
      <%= for effect_mechanic <- @effect.effect_mechanics do %>
        <div class="w-full rounded overflow-hidden shadow-lg mt-4">
          <div class="px-6 py-4">
            <.list>
              <:item title="Name"><%= effect_mechanic.name %></:item>
              <:item title="Modifier"><%= effect_mechanic.modifier %></:item>
              <:item title="Force"><%= effect_mechanic.force %></:item>
              <:item title="Execute multiple times"><%= effect_mechanic.execute_multiple_times %></:item>
              <:item title="Damage"><%= effect_mechanic.damage %></:item>
              <:item title="Effect delay ms"><%= effect_mechanic.effect_delay_ms %></:item>
              <:item title="Additive duration add ms"><%= effect_mechanic.additive_duration_add_ms %></:item>
              <:item title="Stat multiplier"><%= effect_mechanic.stat_multiplier %></:item>
            </.list>
          </div>
        </div>
      <% end %>
    </.modal>
    """
  end

  attr :form, :map, required: true
  attr :field, :atom, required: true

  def effect_form(assigns) do
    ~H"""
    <.button type="button" phx-click={show_modal("effect-form")}>Edit effect</.button>
    <.modal id="effect-form">
      <.inputs_for :let={effect_f} field={@form[@field]}>
        <.input field={effect_f[:name]} type="text" label="Name" />
        <.input field={effect_f[:duration_ms]} type="number" label="Effect duration" />
        <.input field={effect_f[:remove_on_action]} type="checkbox" label="Remove effect on action" />
        <.input field={effect_f[:one_time_application]} type="checkbox" label="Apply effect once" />
        <.input field={effect_f[:allow_multiple_effects]} type="checkbox" label="Allow more that one effect instance" />
        <.input field={effect_f[:consume_projectile]} type="checkbox" label="Consume projectile" />
        <.inputs_for :let={mechanics_form} field={effect_f[:effect_mechanics]}>
          <div class="w-full rounded overflow-hidden shadow-lg mt-4">
            <div class="px-6 py-4">
              <.input
                field={mechanics_form[:name]}
                type="select"
                label="Effect mechanic name"
                prompt="-- Choose a value --"
                options={Ecto.Enum.values(GameBackend.CurseOfMirra.Effect.EffectMechanic, :name)}
              />
              <.input field={mechanics_form[:modifier]} type="number" label="Modifier" step="any" />
              <.input field={mechanics_form[:force]} type="number" label="Force" step="any" />
              <.input field={effect_f[:execute_multiple_times]} type="checkbox" label="Execute mechanic multiple times" />
              <.input field={mechanics_form[:damage]} type="number" label="Damage amount" />
              <.input field={mechanics_form[:effect_delay_ms]} type="number" label="Mechanic delay" />
              <.input field={mechanics_form[:additive_duration_add_ms]} type="number" label="Additive duration to add ms" />
              <.input
                field={mechanics_form[:stat_multiplier]}
                type="number"
                label="Stat multiplier"
                step="Start multiplier"
              />
            </div>
          </div>
        </.inputs_for>
      </.inputs_for>
    </.modal>
    """
  end
end
