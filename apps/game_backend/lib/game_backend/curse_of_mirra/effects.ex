defmodule GameBackend.CurseOfMirra.Effects do
  @moduledoc """
  Operations with skills.
  """

  alias GameBackend.CurseOfMirra.Effects.Effect

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking effect changes.

  ## Examples

      iex> change_effect(effect)
      %Ecto.Changeset{data: %Effect{}}

  """
  def change_effect(%Effect{} = effect, attrs \\ %{}) do
    Effect.changeset(effect, attrs)
  end
end
