defmodule WeatherServer.Repo.Migrations.CreateSettings do
  use Ecto.Migration

  def change do
    create table(:settings) do
      add :category, :string, null: false
      add :key, :string, null: false
      add :value, :map, null: false

      timestamps()
    end

    create unique_index(:settings, [:category, :key])
  end
end
