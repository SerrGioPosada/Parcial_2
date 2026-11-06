defmodule Alcance do
  # Calcula todas las ciudades alcanzables desde el origen, registra los pasos en un archivo y comprueba si se puede llegar al destino.
  def alcance(grafo, origen, destino, ruta) do
    inicio = MapSet.new([origen])
    File.write!(ruta, "=== Alcance desde #{origen} ===\n", [:append])

    pasos =
      Stream.iterate(inicio, fn conjunto_actual ->
        siguiente_conjunto(conjunto_actual, grafo)
      end)

    {final, paso_estabilizacion} =
      pasos
      |> Stream.with_index()
      |> Enum.reduce_while({nil, nil}, fn {conjunto, indice}, {anterior, _} ->
        ciudades =
          conjunto |> MapSet.to_list() |> Enum.sort() |> Enum.join(", ")

        File.write!(ruta, "Paso #{indice}: #{ciudades}\n", [:append])

        if not is_nil(anterior) and MapSet.equal?(anterior, conjunto) do
          {:halt, {conjunto, indice}}
        else
          {:cont, {conjunto, indice}}
        end
      end)

    File.write!(ruta, "Se estabiliza en el paso #{paso_estabilizacion}\n\n", [:append])

    alcanzable? = MapSet.member?(final, destino)
    {alcanzable?, final}
  end

  # Obtiene los vecinos de las ciudades actuales y los agrega al conjunto, evitando repetir ciudades.
  defp siguiente_conjunto(actual, grafo) do
    nuevos_vecinos =
      actual
      |> Enum.flat_map(fn ciudad ->
        vecinos = Map.get(grafo, ciudad, [])
        Enum.map(vecinos, fn {vecino, _distancia} -> vecino end)
      end)

    MapSet.union(actual, MapSet.new(nuevos_vecinos))
  end
end
