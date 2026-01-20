defmodule WeatherServer.Settings.NetworkDevice do
  @enforce_keys [:id, :name, :role, :metrics_instance]
  defstruct [:id, :name, :role, :metrics_instance]

  @role_values ["router", "server", "pc"]

  def roles, do: @role_values

  def empty do
    %__MODULE__{id: "", name: "", role: "server", metrics_instance: ""}
  end

  def from_map(%{} = attrs) do
    %__MODULE__{
      id: Map.get(attrs, "id", ""),
      name: Map.get(attrs, "name", ""),
      role: Map.get(attrs, "role", "server"),
      metrics_instance: Map.get(attrs, "metrics_instance", "")
    }
  end

  def to_map(%__MODULE__{} = device) do
    %{
      "id" => device.id,
      "name" => device.name,
      "role" => device.role,
      "metrics_instance" => device.metrics_instance
    }
  end

  def validate(%__MODULE__{} = device) do
    []
    |> validate_required(device, :id, "ID is required")
    |> validate_required(device, :name, "Name is required")
    |> validate_required(device, :metrics_instance, "Metrics instance is required")
    |> validate_role(device)
  end

  defp validate_required(errors, device, field, message) do
    value = Map.fetch!(device, field)

    if is_binary(value) && String.trim(value) != "" do
      errors
    else
      [{field, message} | errors]
    end
  end

  defp validate_role(errors, device) do
    if device.role in @role_values do
      errors
    else
      [{:role, "Role must be router, server, or pc"} | errors]
    end
  end
end
