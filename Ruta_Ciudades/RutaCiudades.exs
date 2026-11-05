Code.require_file("../Util.exs", __DIR__)
Code.require_file("Conexion.exs", __DIR__)
Code.require_file("Depuracion.exs", __DIR__)
Code.require_file("Alcance.exs", __DIR__)
Code.require_file("Ruta.exs", __DIR__)
Code.require_file("BuscadorRutas.exs", __DIR__)

defmodule RutaCiudades do
  @conexiones "datos/conexiones.csv"
  @errores "datos/errores_conexiones.txt"
  @depuracion "datos/depuracion_conexiones.txt"
  @consultas "datos/consultas.txt"
  @alcance "datos/alcance.txt"
  @rutas "datos/rutas_encontradas.txt"

  def main do
    IO.puts("-> Leyendo y parseando conexiones")
    conexiones_crudas = generar_conexiones(@conexiones, @errores)

    IO.puts("-> Depurando conexiones con recursión")
    {:ok, conexiones_validas, _descartados} = Depuracion.validar(conexiones_crudas, @depuracion)

    IO.puts("-> Construyendo el grafo")
    grafo = generar_grafo(conexiones_validas)

    IO.puts("-> Procesando consultas y generando archivos de salida")
    procesar_consultas(@consultas, grafo, @alcance, @rutas)
  end

  def generar_conexiones(ruta_conexiones, ruta_errores) do
    File.write(ruta_errores, "")

    ruta_conexiones
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.with_index(1)
    |> Stream.reject(fn {linea, _indice} -> linea == "" or String.starts_with?(linea, "#") end)
    |> Stream.map(fn {linea, indice} ->
      case Conexion.parse(linea) do
        {:ok, conexion} ->
          {:ok, {conexion, indice}}

        {:error, mensaje} ->
          mensaje_error = "Línea #{indice}: #{linea} -> #{mensaje}\n"
          File.write(ruta_errores, mensaje_error, [:append])
          {:error, mensaje_error}
      end
    end)
    |> Stream.filter(fn
      {:ok, _} -> true
      {:error, _} -> false
    end)
    |> Stream.map(fn {:ok, data} -> data end)
    |> Enum.to_list()
  end

  def generar_grafo(conexiones) do
    Enum.reduce(conexiones, %{}, fn {conexion, _indice}, grafo ->
      Map.update(grafo, conexion.origen, [{conexion.destino, conexion.distancia}], fn vecinos ->
        [{conexion.destino, conexion.distancia} | vecinos]
      end)
    end)
  end

  def procesar_consultas(ruta_consultas, grafo, ruta_alcance, ruta_rutas) do
    File.write(ruta_alcance, "")
    File.write(ruta_rutas, "")

    ruta_consultas
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Enum.each(fn linea ->
      case String.split(linea, ",") do
        [origen, destino] ->
          # Normalizamos a minúsculas para asegurar que coincida con el grafo
          origen_norm = origen |> String.trim() |> String.downcase()
          destino_norm = destino |> String.trim() |> String.downcase()

          revisar_consulta(
            origen_norm,
            destino_norm,
            grafo,
            ruta_alcance,
            ruta_rutas
          )

        _ ->
          IO.puts("Línea de consulta inválida: #{linea}")
      end
    end)
  end

  defp revisar_consulta(origen, destino, grafo, ruta_alcance, ruta_rutas) do
    cond do
      not Map.has_key?(grafo, origen) ->
        escribir_error_consulta(
          origen,
          destino,
          "La ciudad de origen no existe en el grafo.",
          ruta_alcance,
          ruta_rutas
        )

      not Map.has_key?(grafo, destino) ->
        escribir_error_consulta(
          origen,
          destino,
          "La ciudad de destino no existe en el grafo.",
          ruta_alcance,
          ruta_rutas
        )

      true ->
        {_, final_set} = Alcance.alcance(grafo, origen, destino, ruta_alcance)

        if not MapSet.member?(final_set, destino) do
          File.write!(
            ruta_rutas,
            "=== #{origen} -> #{destino} ===\nEl destino no es alcanzable desde el origen (sin rutas).\n\n",
            [:append]
          )
        else
          rutas = BuscadorRutas.buscar_rutas(origen, destino, grafo)
          escribir_reporte_rutas(origen, destino, rutas, ruta_rutas)
        end
    end
  end

  defp escribir_error_consulta(origen, destino, mensaje, ruta_alcance, ruta_rutas) do
    if ruta_alcance do
      File.write!(ruta_alcance, "=== Alcance desde #{origen} ===\n#{mensaje}\n\n", [:append])
    end

    File.write!(ruta_rutas, "=== #{origen} -> #{destino} ===\n#{mensaje}\n\n", [:append])
  end

  defp escribir_reporte_rutas(origen, destino, rutas, ruta_rutas) do
    encabezado = "=== #{origen} -> #{destino} ===\n"

    lineas_rutas =
      rutas
      |> Enum.with_index(1)
      |> Enum.map(fn {r, i} ->
        ciudades_str = Enum.join(r.ciudades, " -> ")
        num_ciudades = length(r.ciudades)
        "Ruta #{i}: #{ciudades_str} (#{num_ciudades} ciudades, #{r.distancia} km)"
      end)
      |> Enum.join("\n")

    num_rutas = length(rutas)

    min_ciudades = Enum.min_by(rutas, &length(&1.ciudades))
    str_mas_corta = Enum.join(min_ciudades.ciudades, " -> ")

    min_distancia = Enum.min_by(rutas, & &1.distancia)

    str_menor_dist =
      "#{Enum.join(min_distancia.ciudades, " -> ")} (#{min_distancia.distancia} km)"

    resumen =
      "\nNúmero de rutas: #{num_rutas}\n" <>
        "Ruta más corta: #{str_mas_corta}\n" <>
        "Ruta de menor distancia: #{str_menor_dist}\n\n"

    contenido = encabezado <> lineas_rutas <> "\n" <> resumen
    File.write!(ruta_rutas, contenido, [:append])
  end
end

RutaCiudades.main()
