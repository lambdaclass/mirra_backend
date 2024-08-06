defmodule ConfiguratorWeb.ArenaServerController do
  use ConfiguratorWeb, :controller

  alias GameBackend.Configuration
  alias GameBackend.ArenaServers.ArenaServer

  def index(conn, _params) do
    arena_servers = Configuration.list_arena_servers()
    render(conn, :index, arena_servers: arena_servers)
  end

  def new(conn, _params) do
    changeset = Configuration.change_arena_server(%ArenaServer{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"arena_server" => arena_server_params}) do
    case Configuration.create_arena_server(arena_server_params) do
      {:ok, arena_server} ->
        conn
        |> put_flash(:info, "Arena server created successfully.")
        |> redirect(to: ~p"/arena_servers/#{arena_server}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    arena_server = Configuration.get_arena_server!(id)
    render(conn, :show, arena_server: arena_server)
  end

  def edit(conn, %{"id" => id}) do
    arena_server = Configuration.get_arena_server!(id)
    changeset = Configuration.change_arena_server(arena_server)
    render(conn, :edit, arena_server: arena_server, changeset: changeset)
  end

  def update(conn, %{"id" => id, "arena_server" => arena_server_params}) do
    arena_server = Configuration.get_arena_server!(id)

    case Configuration.update_arena_server(arena_server, arena_server_params) do
      {:ok, arena_server} ->
        conn
        |> put_flash(:info, "Arena server updated successfully.")
        |> redirect(to: ~p"/arena_servers/#{arena_server}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, arena_server: arena_server, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    arena_server = Configuration.get_arena_server!(id)

    case Configuration.delete_arena_server(arena_server) do
      {:error, _changeset} ->
        conn
        |> put_flash(:info, "Something went wrong.")
        |> redirect(to: ~p"/arena_servers/#{arena_server}")

      {:ok, _arena_server} ->
        conn
        |> put_flash(:info, "Arena server deleted successfully.")
        |> redirect(to: ~p"/arena_servers")
    end
  end
end
