defmodule GameBackend.Shared.CurrencyTransaction do
  @moduledoc """
  Demo CurrencyTransaction
  """

  defmacro __using__(prefix: prefix) do
    quote do
      use GameBackend.Schema
      import Ecto.Changeset

      @schema_prefix unquote(prefix)
      schema "currency_transactions" do
        field(:amount, :integer)

        belongs_to :user, GameBackend.Common.DemoUser
        belongs_to :demo_currency, GameBackend.Common.DemoCurrency

        timestamps()
      end

      def changeset(user, attrs) do
        user
        |> cast(attrs, [:amount, :user_id, :demo_currency_id])
        |> unique_constraint([:amount, :user_id, :demo_currency_id])
        |> validate_number(:amount, greater_than_or_equal_to: 0)
      end
    end
  end
end
