defmodule Users.Repo do
  use Ecto.Repo,
    otp_app: :users,
    adapter: Ecto.Adapters.Postgres
end

defmodule Users.Schema do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end
end
