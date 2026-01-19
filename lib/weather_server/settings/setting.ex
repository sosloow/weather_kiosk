defmodule WeatherServer.Settings.Setting do
  use Ecto.Schema

  import Ecto.Changeset

  schema "settings" do
    field :category, :string
    field :key, :string
    field :value, :map

    timestamps()
  end

  def changeset(setting, attrs) do
    setting
    |> cast(attrs, [:category, :key, :value])
    |> validate_required([:category, :key, :value])
  end
end
