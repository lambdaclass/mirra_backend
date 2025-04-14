defmodule ConfiguratorWeb.LevelUpLive.Form do
alias GameBackend.Utils
alias GameBackend.Users.Currencies
alias GameBackend.CurseOfMirra.LevelUpConfiguration
  use ConfiguratorWeb, :live_view

  alias GameBackend.Configuration

  def mount(
        _params,
        %{"level_up_config" => level_up_config, "version" => version},
        socket
      ) do

    changeset = LevelUpConfiguration.changeset(level_up_config, %{})

    {:ok, currency} = Currencies.get_currency_by_name_and_game("Gold", Utils.get_game_id(:curse_of_mirra))

    currency_options = [currency]
      |> Enum.map(fn curr -> {curr.name, curr.id} end)

    socket =
      assign(socket, changeset: changeset, action: "update", level_up_config: level_up_config, version: version, currency_options: currency_options)

    {:ok, socket}
  end

  def handle_event("validate", %{"level_up_configuration" => level_up_config_params}, socket) do
    changeset = socket.assigns.changeset
    changeset = LevelUpConfiguration.changeset(changeset, level_up_config_params)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("update", %{"level_up_configuration" => level_up_config_params}, socket) do
    level_up_config = socket.assigns.level_up_config

    socket =
      case Configuration.update_level_up_configuration(level_up_config, level_up_config_params) do
        {:ok, level_up_config} ->
          socket
          |> put_flash(:info, "Config updated successfully.")
          |> redirect(to: ~p"/versions/#{socket.assigns.version.id}/level_up")

        {:error, %Ecto.Changeset{} = changeset} ->
          version = Configuration.get_version!(socket.assigns.version_id)

          socket
          |> put_flash(:error, "Please correct the errors below.")
          |> assign(changeset: changeset, version: version)
      end

    {:noreply, socket}
  end
end
