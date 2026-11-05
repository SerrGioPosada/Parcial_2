defmodule BuscadorRutas do
  def buscar_rutas(origen, destino, grafo) do
    camino_inicial = [origen]
    explorar_caminos(origen, destino, grafo, camino_inicial, 0)
  end

  defp explorar_caminos(ciudad_actual, destino, grafo, camino_actual, distancia_acumulada) do
    if ciudad_actual == destino do
      {:ok, ruta} =
        Ruta.nuevo(
          Enum.reverse(camino_actual),
          distancia_acumulada
        )

      [ruta]
    else
      vecinos = Map.get(grafo, ciudad_actual, [])

      vecinos
      |> Enum.reject(fn vecino_con_distancia ->
        case vecino_con_distancia do
          {vecino, _distancia} -> vecino in camino_actual
          vecino -> vecino in camino_actual
        end
      end)
      |> Enum.flat_map(fn vecino_con_distancia ->
        {vecino, distancia} =
          case vecino_con_distancia do
            {v, d} -> {v, d}
            v -> {v, 0}
          end

        explorar_caminos(
          vecino,
          destino,
          grafo,
          [vecino | camino_actual],
          distancia_acumulada + distancia
        )
      end)
    end
  end
end
