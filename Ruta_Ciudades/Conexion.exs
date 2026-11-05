defmodule Util do
  # Normalizar la linea de texto

  def normalizar_linea(linea) when not is_binary(linea) do
    {:error, "La línea no es una cadena de texto"}
  end

  def normalizar_linea(linea) do
    campos =
      linea
      |> String.trim()
      |> String.downcase()
      |> String.split(",")

    case campos do
      [origen, destino, distancia] ->
        {:ok, [String.trim(origen), String.trim(destino), String.trim(distancia)]}

      _ ->
        {:error,
         "la linea no tiene el formato correcto. Debe contener 3 campos separados por comas"}
    end
  end

  # Parsear una cadena de texto a un number
  def parsear_entero(cadena) when not is_binary(cadena) do
    {:error, "El valor no es una cadena de texto"}
  end

  def parsear_entero(cadena) do
    case Integer.parse(cadena) do
      {numero, ""} -> {:ok, numero}
      {_, resto} -> {:error, "La distancia contiene caracteres inválidos: #{resto}"}
      :error -> {:error, "La distancia no es un número entero válido"}
    end
  end
end

defmodule Conexion do
  @enforce_keys [:origen, :destino, :distancia]
  defstruct [:origen, :destino, :distancia]

  def parse(linea) do
    case linea
         |> Util.normalizar_linea()
         |> validar_parametros()
         |> nuevo() do
      {:ok, conexion} -> {:ok, conexion}
      {:error, mensaje} -> {:error, mensaje}
    end
  end

  # Validar la linea
  def validar_parametros({:error, mensaje}), do: {:error, mensaje}

  def validar_parametros({:ok, [origen, destino, distancia]}) do
    with {:ok, origen} <- validar_ciudad(origen),
         {:ok, destino} <- validar_ciudad(destino),
         {:ok, distancia} <-
           Util.parsear_entero(distancia)
           |> validar_distancia() do
      {:ok, [origen, destino, distancia]}
    else
      {:error, mensaje} -> {:error, mensaje}
    end
  end

  # Validaciones de una ciudad
  def validar_ciudad(ciudad) when not is_binary(ciudad),
    do: {:error, "La ciudad debe ser una cadena de texto"}

  def validar_ciudad(ciudad) when byte_size(ciudad) == 0,
    do: {:error, "La ciudad no puede estar vacía"}

  def validar_ciudad(ciudad), do: {:ok, ciudad}

  # Validaciones de la distancia
  def validar_distancia({:error, mensaje}), do: {:error, mensaje}

  def validar_distancia({:ok, distancia}) when distancia < 0,
    do: {:error, "La distancia no puede ser negativa"}

  def validar_distancia({:ok, distancia}), do: {:ok, distancia}

  # Crear el Struct
  def nuevo({:error, mensaje}), do: {:error, mensaje}

  def nuevo({:ok, [origen, destino, distancia]}) do
    {:ok, %__MODULE__{origen: origen, destino: destino, distancia: distancia}}
  end
end
