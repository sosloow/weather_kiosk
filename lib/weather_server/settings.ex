defmodule WeatherServer.Settings do
  alias WeatherServer.Repo
  alias WeatherServer.Settings.NetworkDevice
  alias WeatherServer.Settings.Setting

  @appearance_category "appearance"
  @theme_key "daisyui_theme"
  @network_category "network"
  @devices_key "devices"

  def get_theme(default \\ "night") do
    get_setting_value(@appearance_category, @theme_key, default)
  end

  def set_theme(theme) do
    upsert_setting_value(@appearance_category, @theme_key, theme)
  end

  def get_devices do
    @network_category
    |> get_setting_value(@devices_key, [])
    |> List.wrap()
    |> Enum.map(&NetworkDevice.from_map/1)
  end

  def update_devices(devices) do
    device_maps = Enum.map(devices, &NetworkDevice.to_map/1)
    upsert_setting_value(@network_category, @devices_key, device_maps)
  end

  def validate_devices(devices) do
    devices
    |> Enum.with_index()
    |> Enum.flat_map(fn {device, index} ->
      NetworkDevice.validate(device)
      |> Enum.map(fn {field, message} -> {index, field, message} end)
    end)
  end

  def get_setting_value(category, key, default \\ nil) do
    case Repo.get_by(Setting, category: category, key: key) do
      nil ->
        default

      %Setting{value: %{"value" => value}} ->
        value

      %Setting{value: value} ->
        value
    end
  end

  def upsert_setting_value(category, key, value) do
    payload = %{category: category, key: key, value: %{"value" => value}}
    changeset = Setting.changeset(%Setting{}, payload)
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Repo.insert(changeset,
      on_conflict: [set: [value: payload.value, updated_at: now]],
      conflict_target: [:category, :key]
    )
  end
end
