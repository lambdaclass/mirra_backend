defmodule ConfiguratorWeb.MapConfigurationHTML do
  use ConfiguratorWeb, :html

  embed_templates "map_configuration_html/*"

  @doc """
  Renders a map_configuration form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def map_configuration_form(assigns)

  def embed_to_string(embeds) when is_list(embeds) do
    embeds
    |> Enum.map(&embed_to_string/1)
    |> Enum.reject(&(&1 == nil))
    |> json_encode
  end

  def embed_to_string(nil), do: nil
  def embed_to_string([]), do: ""
  def embed_to_string(string) when is_binary(string), do: string

  def embed_to_string(%Ecto.Changeset{action: :replace}) do
    nil
  end

  def embed_to_string(%Ecto.Changeset{} = changeset) do
    changeset.params
  end

  def embed_to_string(struct) when is_map(struct) do
    struct
  end

  def json_encode(value) do
    value
    |> Jason.encode!()
    |> Jason.Formatter.pretty_print()
  end
end
