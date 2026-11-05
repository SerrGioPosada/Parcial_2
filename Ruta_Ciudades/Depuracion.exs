defmodule Depuracion do
  # Velidar y escribir las lineas depuradas
  def validar(conexiones, ruta), do: validar_tail(conexiones, ruta, [], [])

  def validar_tail([], _ruta, conexiones_validas, descartados) do
    {:ok, Enum.reverse(conexiones_validas), Enum.reverse(descartados)}
  end

  def validar_tail([conexion | resto], ruta, conexiones_validas, descartados) do
    case validaciones(conexion, conexiones_validas) do
      {:ok, conexion_valida} ->
        validar_tail(resto, ruta, [conexion_valida | conexiones_validas], descartados)

      {:error, mensaje} ->
        escribir_depuraciones(mensaje, ruta)
        validar_tail(resto, ruta, conexiones_validas, [{:error, mensaje} | descartados])
    end
  end

  def validaciones(conexion, conexiones_validas) do
    with {:ok, conexion_valida} <- validar_iguales(conexion),
         {:ok, conexion_valida} <- validar_duplicados(conexion_valida, conexiones_validas) do
      {:ok, conexion_valida}
    else
      {:error, mensaje} -> {:error, mensaje}
    end
  end

  # Validar que el origen y destino no sean iguales
  def validar_iguales({conexion, linea}) when conexion.origen == conexion.destino do
    {:error,
     "Linea #{linea}: #{conexion.origen}, #{conexion.destino}, #{conexion.distancia} -> conecta una ciudad consigo misma; se descarta"}
  end

  def validar_iguales(conexion), do: {:ok, conexion}

  # Validar que no haya duplicados
  def validar_duplicados(conexion, []), do: {:ok, conexion}

  def validar_duplicados({conexion, linea} = conexion_actual, [{conexion2, linea2} | cola]) do
    if es_duplicado?(conexion, conexion2) do
      if conexion.distancia == conexion2.distancia do
        {:error,
         "Linea #{linea}: #{conexion.origen}, #{conexion.destino}, #{conexion.distancia} -> repetida (Linea #{linea2}); se descarta"}
      else
        {:error,
         "Linea #{linea}: #{conexion.origen}, #{conexion.destino}, #{conexion.distancia} -> distancia distinta a la original de la Linea #{linea2}; se descarta"}
      end
    else
      validar_duplicados(conexion_actual, cola)
    end
  end

  def es_duplicado?(conexion, conexion2) do
    (conexion.origen == conexion2.origen and conexion.destino == conexion2.destino) or
      (conexion.origen == conexion2.destino and conexion.destino == conexion2.origen)
  end

  def escribir_depuraciones(mensaje, ruta) do
    File.write(ruta, mensaje <> "\n", [:append])
  end
end
