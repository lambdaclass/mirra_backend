defmodule GatewayWeb.ChampionsOfMirraController do
  use GatewayWeb, :controller

  def get_campaigns(conn, _params) do
    response = ChampionsOfMirra.process(:get_campaigns)
    json(conn, format_response(response))
  end

  defp format_response(campaigns) do
    Enum.map(campaigns, fn campaign ->
      Enum.map(campaign, fn units ->
        Enum.map(units, fn unit -> Map.from_struct(unit) |> Map.drop([:__meta__, :user, :character]) end)
      end)
    end)
  end
end
