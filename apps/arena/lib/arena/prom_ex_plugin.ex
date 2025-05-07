defmodule Arena.PromExPlugin do
  @moduledoc """
  This module defines our custom PromEx plugin.
  It contains all our custom metrics that are displayed on the graphana dashboard.
  """

  use PromEx.Plugin

  @impl true
  def event_metrics(_opts) do
    []
  end

  @impl true
  def polling_metrics(_opts) do
    []
  end
end
