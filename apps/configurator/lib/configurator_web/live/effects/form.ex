defmodule ConfiguratorWeb.EffectsLive.Form do
  alias GameBackend.Units.Skills
  use ConfiguratorWeb, :live_view

  alias GameBackend.CurseOfMirra.Effects
  alias GameBackend.CurseOfMirra.Effects.Effect
  alias GameBackend.CurseOfMirra.Effects.Effect.EffectMechanic
  alias GameBackend.Configuration

  def mount(
        _params,
        %{"effect" => nil, "version" => version, "skill" => skill},
        socket
      ) do
    changeset = Effects.change_effect(%Effect{effect_mechanics: [%EffectMechanic{}]})

    socket =
      assign(socket, skill: skill, changeset: changeset, action: "save", version: version)

    {:ok, socket}
  end

  def mount(
        _params,
        %{"effect" => effect, "version" => version, "skill" => skill},
        socket
      ) do
    changeset = Effects.change_effect(effect)

    socket = assign(socket, skill: skill, changeset: changeset, action: "save", version: version)
    {:ok, socket}
  end

  def handle_event("validate", %{"effect" => effect_params}, socket) do
    changeset = socket.assigns.changeset
    changeset = Effect.changeset(changeset, effect_params)

    {:noreply, assign(socket, changeset: changeset, effect: changeset)}
  end

  def handle_event("add_effect_mechanics", _params, socket) do
    changeset = socket.assigns.changeset
    effect_mechanics = Ecto.Changeset.get_field(changeset, :effect_mechanics) || []
    changeset = Ecto.Changeset.put_embed(changeset, :effect_mechanics, effect_mechanics ++ [%EffectMechanic{}])

    {:noreply, assign(socket, changeset: changeset, effect: changeset)}
  end

  def handle_event("remove_effect_mechanics", _params, socket) do
    changeset = socket.assigns.changeset
    effect_mechanics = Ecto.Changeset.get_field(changeset, :effect_mechanics) |> List.delete_at(-1)
    changeset = Ecto.Changeset.put_change(changeset, :effect_mechanics, effect_mechanics)

    {:noreply, assign(socket, changeset: changeset, effect: changeset)}
  end

  def handle_event("save", %{"effect" => effect_params}, socket) do
    IO.inspect(effect_params, label: :aver_params)

    socket =
      case Skills.update_skill(socket.assigns.skill, %{on_owner_effect: effect_params}) do
        {:ok, skill} ->
          socket
          |> put_flash(:info, "Effect created successfully.")
          |> redirect(to: ~p"/versions/#{skill.version_id}/skills/#{skill.id}")

        {:error, %Ecto.Changeset{} = changeset} ->
          version = Configuration.get_version!(effect_params["version_id"])

          socket
          |> put_flash(:error, "Please correct the errors below.")
          |> assign(changeset: changeset, version: version)
      end

    {:noreply, socket}
  end
end
