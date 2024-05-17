defmodule ArenaLoadTest.Utils do
  @moduledoc """
  Utils for loadtests Application.
  """

  def get_server_ip("Europe"), do: System.get_env("LOADTEST_EUROPE_HOST")
  def get_server_ip("Brazil"), do: System.get_env("LOADTEST_BRAZIL_HOST")
end
