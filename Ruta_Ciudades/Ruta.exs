defmodule Ruta do
  @enforce_keys [:ciudades, :distancia]
  defstruct [:ciudades, :distancia]

  def nuevo(ciudades, distancia) do
    {:ok, %__MODULE__{ciudades: ciudades, distancia: distancia}}
  end
end
