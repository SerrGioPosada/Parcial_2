defmodule Alcance do
  def alcance(grafo, origen, destino, ruta) do
    inicio = MapSet.new([origen])

    pasos =
      Stream.unfold(inicio, fn actual ->
        nuevos_vecinos =
          actual
          |> Enum.flat_map(fn ciudad ->
            vecinos = Map.get(grafo, ciudad, [])

            Enum.map(vecinos, fn
              {vecino, _distancia} -> vecino
              vecino -> vecino
            end)
          end)

        siguiente_conjunto = MapSet.union(actual, MapSet.new(nuevos_vecinos))

        if MapSet.equal?(actual, siguiente_conjunto) do
          nil
        else
          {siguiente_conjunto, siguiente_conjunto}
        end
      end)

    todos_los_pasos = [inicio | Enum.to_list(pasos)]

    escribir_alcance(todos_los_pasos, origen, ruta)

    final = List.last(todos_los_pasos)

    alcanzable? = MapSet.member?(final, destino)

    {alcanzable?, final}
  end

  defp escribir_alcance(pasos_lista, origen, ruta) do
    encabezado = "=== Alcance desde #{origen} ===\n"

    lineas_pasos =
      pasos_lista
      |> Enum.with_index(0)
      |> Enum.map(fn {conjunto, indice} ->
        ciudades_ordenadas = conjunto |> MapSet.to_list() |> Enum.sort() |> Enum.join(", ")
        "Paso #{indice}: #{ciudades_ordenadas}"
      end)
      |> Enum.join("\n")

    paso_estabilizacion = length(pasos_lista) - 1
    estabilizacion = "\nSe estabiliza en el paso #{paso_estabilizacion}\n\n"

    contenido = encabezado <> lineas_pasos <> estabilizacion
    File.write!(ruta, contenido, [:append])
  end
end
