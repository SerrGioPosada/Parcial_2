defmodule Alcance do
  def alcance(grafo, origen, destino, ruta) do
    inicio = MapSet.new([origen])
    todos_los_pasos = calcular_pasos_alcance(inicio, grafo, [inicio])

    File.write!(ruta, "=== Alcance desde #{origen} ===\n", [:append])

    todos_los_pasos
    |> Enum.with_index(0)
    |> Enum.each(fn {conjunto, indice} ->
      ciudades_ordenadas = conjunto |> MapSet.to_list() |> Enum.sort() |> Enum.join(", ")
      File.write!(ruta, "Paso #{indice}: #{ciudades_ordenadas}\n", [:append])
    end)

    paso_estabilizacion = length(todos_los_pasos) - 1
    File.write!(ruta, "Se estabiliza en el paso #{paso_estabilizacion}\n\n", [:append])

    final = List.last(todos_los_pasos)
    alcanzable? = MapSet.member?(final, destino)

    {alcanzable?, final}
  end

  defp calcular_pasos_alcance(actual, grafo, acumulado) do
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
      Enum.reverse([siguiente_conjunto | acumulado])
    else
      calcular_pasos_alcance(siguiente_conjunto, grafo, [siguiente_conjunto | acumulado])
    end
  end
end
