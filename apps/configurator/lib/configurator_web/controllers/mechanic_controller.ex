defmodule ConfiguratorWeb.MechanicController do
  use ConfiguratorWeb, :controller

  alias GameBackend.CurseOfMirra.Configuration
  alias GameBackend.CurseOfMirra.Configuration.Mechanic

  def index(conn, _params) do
    mechanics = Configuration.list_mechanics()
    render(conn, :index, mechanics: mechanics)
  end

  def new(conn, _params) do
    changeset = Configuration.change_mechanic(%Mechanic{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"mechanic" => mechanic_params}) do
    case Configuration.create_mechanic(mechanic_params) do
      {:ok, mechanic} ->
        conn
        |> put_flash(:info, "Mechanic created successfully.")
        |> redirect(to: ~p"/mechanics/#{mechanic}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    mechanic = Configuration.get_mechanic!(id)
    render(conn, :show, mechanic: mechanic)
  end

  def edit(conn, %{"id" => id}) do
    mechanic = Configuration.get_mechanic!(id)
    changeset = Configuration.change_mechanic(mechanic)
    render(conn, :edit, mechanic: mechanic, changeset: changeset)
  end

  def update(conn, %{"id" => id, "mechanic" => mechanic_params}) do
    mechanic = Configuration.get_mechanic!(id)

    case Configuration.update_mechanic(mechanic, mechanic_params) do
      {:ok, mechanic} ->
        conn
        |> put_flash(:info, "Mechanic updated successfully.")
        |> redirect(to: ~p"/mechanics/#{mechanic}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, mechanic: mechanic, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    mechanic = Configuration.get_mechanic!(id)
    {:ok, _mechanic} = Configuration.delete_mechanic(mechanic)

    conn
    |> put_flash(:info, "Mechanic deleted successfully.")
    |> redirect(to: ~p"/mechanics")
  end
end
