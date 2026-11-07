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
    verificar_archivo_entrada(@conexiones, "El archivo de conexiones no existe: #{@conexiones}")
    verificar_archivo_entrada(@consultas, "El archivo de consultas no existe: #{@consultas}")

    File.write(@errores, "")
    File.write(@depuracion, "")
    File.write(@alcance, "")
    File.write(@rutas, "")

    IO.puts("-> Leyendo y parseando conexiones con Streams")

    conexiones_validas =
      @conexiones
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
            File.write(@errores, mensaje_error, [:append])
            {:error, mensaje_error}
        end
      end)
      |> Stream.filter(fn
        {:ok, _} -> true
        {:error, _} -> false
      end)
      |> Stream.map(fn {:ok, data} -> data end)
      |> Enum.to_list()

    IO.puts("-> Depurando conexiones con recursión")

    {:ok, conexiones_depuradas, _descartados} =
      Depuracion.validar(conexiones_validas, @depuracion)

    IO.puts("-> Construyendo el grafo bidireccional")
    grafo = generar_grafo(conexiones_depuradas)

    IO.puts("-> Procesando consultas línea por línea y generando resultados")
    procesar_consultas(@consultas, grafo, @alcance, @rutas)
  end

  defp verificar_archivo_entrada(ruta, mensaje_error) do
    if not File.exists?(ruta) do
      IO.puts(:stderr, "Error: #{mensaje_error}")
      System.halt(1)
    end
  end

  def generar_grafo(conexiones) do
    Enum.reduce(conexiones, %{}, fn {conexion, _indice}, grafo ->
      grafo1 =
        Map.update(grafo, conexion.origen, [{conexion.destino, conexion.distancia}], fn vecinos ->
          [{conexion.destino, conexion.distancia} | vecinos]
        end)

      Map.update(grafo1, conexion.destino, [{conexion.origen, conexion.distancia}], fn vecinos ->
        [{conexion.origen, conexion.distancia} | vecinos]
      end)
    end)
  end

  def procesar_consultas(ruta_consultas, grafo, ruta_alcance, ruta_rutas) do
    ruta_consultas
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Enum.each(fn linea ->
      case String.split(linea, ",") do
        [origen, destino] ->
          origen_norm = origen |> String.trim() |> String.downcase()
          destino_norm = destino |> String.trim() |> String.downcase()

          revisar_consulta(origen_norm, destino_norm, grafo, ruta_alcance, ruta_rutas)

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
          texto =
            "=== #{origen} -> #{destino} ===\nEl destino no es alcanzable desde el origen (sin rutas).\n\n"

          File.write!(ruta_rutas, texto, [:append])
          IO.puts(texto)
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

    texto_final = "=== #{origen} -> #{destino} ===\n#{mensaje}\n\n"
    File.write!(ruta_rutas, texto_final, [:append])
    IO.puts(texto_final)
  end


defp escribir_reporte_rutas(origen, destino, rutas, ruta_rutas) do
  File.write!(ruta_rutas, "=== #{origen} -> #{destino} ===\n", [:append])
  IO.puts("=== #{origen} -> #{destino} ===")

  rutas
  |> Enum.with_index(1)
  |> Enum.each(fn {r, i} ->
    ciudades_str = Enum.join(r.ciudades, " -> ")
    num_ciudades = length(r.ciudades)
    linea = "Ruta #{i}: #{ciudades_str} (#{num_ciudades} ciudades, #{r.distancia} km)\n"
    File.write!(ruta_rutas, linea, [:append])
    IO.write(linea)
  end)

  num_rutas = length(rutas)

  min_ciudades_val = rutas |> Enum.map(&length(&1.ciudades)) |> Enum.min()
  rutas_min_ciudades = Enum.filter(rutas, &(length(&1.ciudades) == min_ciudades_val))

  str_mas_corta =
    rutas_min_ciudades
    |> Enum.map(fn r -> "#{Enum.join(r.ciudades, " -> ")} (#{length(r.ciudades)} ciudades)" end)
    |> Enum.join(" | ")

  min_dist_val = rutas |> Enum.map(& &1.distancia) |> Enum.min()
  rutas_min_dist = Enum.filter(rutas, &(&1.distancia == min_dist_val))

  str_menor_dist =
    rutas_min_dist
    |> Enum.map(fn r -> "#{Enum.join(r.ciudades, " -> ")} (#{r.distancia} km)" end)
    |> Enum.join(" | ")

  File.write!(ruta_rutas, "\nNúmero de rutas: #{num_rutas}\n", [:append])
  File.write!(ruta_rutas, "Ruta(s) más corta(s) (por ciudades): #{str_mas_corta}\n", [:append])
  File.write!(ruta_rutas, "Ruta(s) de menor distancia: #{str_menor_dist}\n\n", [:append])

  IO.puts("\nNúmero de rutas: #{num_rutas}")
  IO.puts("Ruta(s) más corta(s) (por ciudades): #{str_mas_corta}")
  IO.puts("Ruta(s) de menor distancia: #{str_menor_dist}\n")
end

end

RutaCiudades.main()
