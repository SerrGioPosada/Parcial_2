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

    escribir_alcance(todos_los_pasos, ruta)

    final = List.last(todos_los_pasos)

    alcanzable? = MapSet.member?(final, destino)

    {alcanzable?, final}
  end

  defp escribir_alcance(pasos, ruta) do
    contenido =
      pasos
      |> Enum.with_index()
      |> Enum.map(fn {conjunto, indice} ->
        ciudades_ordenadas = conjunto |> MapSet.to_list() |> Enum.sort()
        "Paso #{indice}: #{inspect(ciudades_ordenadas)}\n"
      end)

    File.write!(ruta, contenido)
  end
end
