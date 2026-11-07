# se creara una lista de columnas, donde cada numero representara la solucion

# solo se pone una reina por fila, asi jamas se tendran dos en una fila

# una reina no puede compartir columna ni idagonal con ninguna reina anterior

defmodule NReinas do
  def ejecutar do
  generar_tamaños_errores()
  generar_archivos_reinas()
  primera_solucion()
  verificar_propuestas()
  #generar_secuencia_reinas()
end

  def posicion?(columna, reinas) do
    # se coloca una reina, luego se guarda su columna al principio de la lista
    # la reina mas reciente esta en la fila anterior a la nueva.
    # se comienza comparando con la ultima fila ocupada y se retrocede
    asegurar(columna, reinas, 0)
  end

  # caso base
  defp asegurar(_columna, [], _distancia), do: true

  defp asegurar(columna, [cabeza | _cola], distancia)
       when columna == cabeza or abs(columna - cabeza) == distancia + 1, do: false

  defp asegurar(columna, [_cabeza | cola], distancia) do
    asegurar(columna, cola, distancia + 1)
  end

  # funcion que encuentra las soluciones, se prueba cada columna de una fila, si es seguro, se coloca la reina y se avanza
  # a la siguiente fila

  # produce soluciones perezosamente
  def encontrar(n), do: solucion(n, [])

  # caso base: tenemos N reinas, por eso se ecuentra la solucion

  defp solucion(n, reinas) when length(reinas) == n do
    Stream.map([reinas], fn solucion -> solucion end)
  end

  defp solucion(n, reinas) do
    0..(n - 1)
    |> Stream.map(fn columna -> comprobar_columna(n, columna, reinas) end)
    |> Stream.concat()
  end

  defp comprobar_columna(n, columna, reinas) do
    if posicion?(columna, reinas) do
      solucion(n, [columna | reinas])
    else
      Stream.map([], fn x -> x end)
    end
  end

  # se genera una fila, despues se extiende para representar todas las filas del tablero

  def mostrar_fila(reina_columna, n) do
    Enum.map(0..(n - 1), fn columna -> comparar_posicion(columna, reina_columna) end)
  end

  def comparar_posicion(columna, reina_columna) do
    if columna == reina_columna do
      "Q"
    else
      "."
    end
  end

  # funcion para mostrar tableros en terminal

  def mostrar_solucion(n) do
    encontrar(n)
    |> Stream.map(&Enum.reverse/1)
    |> Enum.each(fn solucion ->
      Enum.each(solucion, fn columna -> IO.puts(mostrar_fila(columna, n)) end)
    end)
  end

  # funcion para mostrar tableros en archivo

  def escribir_tablero(archivo, solucion, n, numero) do
    IO.puts(archivo, "solucion #{numero}:")

    solucion
    |> Enum.reverse()
    |> Enum.each(fn columna ->
      fila = mostrar_fila(columna, n)
      IO.puts(archivo, unir_casillas(fila))
    end)

    IO.puts(archivo, "")
  end

  def unir_casillas([ultima]), do: ultima

  def unir_casillas([casilla | resto]) do
    casilla <> " " <> unir_casillas(resto)
  end

  def leer_tamaños do
    if File.exists?("tamaños.txt") do
      File.stream!("tamaños.txt")
    else
      IO.puts("No se encontro el archivo tamaños.txt")
      []
    end
  end

  def generar_archivos_reinas do
    procesar_tamaños()
    |> Stream.filter(fn {_numero, _linea, resultado} ->
      case resultado do
        {:ok, _n} -> true
        {:error, _motivo} -> false
      end
    end)
    |> Enum.each(fn {_numero, _linea, {:ok, n}} ->
      guardar_soluciones(n)
      mostrar_solucion(n)
    end)
  end

  def procesar_tamaños do
    leer_tamaños()
    |> Stream.with_index(1)
    |> Stream.map(fn {linea, numero} -> {numero, String.trim(linea)} end)
    |> Stream.filter(fn {_numero, linea} -> linea != "" and !String.starts_with?(linea, "#") end)
    |> Stream.map(fn {numero, linea} -> {numero, linea, validar_tamaño(linea)} end)
  end

  def validar_tamaño(linea) do
    case Integer.parse(linea) do
      {n, ""} when n > 0 -> {:ok, n}
      _ -> {:error, "no es un entero positivo"}
    end
  end

  # se crea una funcion para escribir dentro del archivo los errores con la funcion file.open
  def generar_tamaños_errores do
    case File.open("errores_tamaños.txt", [:write]) do
      {:ok, archivo} ->
        procesar_tamaños()
        |> Stream.filter(&es_error?/1)
        |> Enum.each(fn error -> escribir_error(archivo, error) end)

        IO.puts("se genero el reporte puedes revisarlo :)")

      {:error, motivo} ->
        IO.inspect(motivo)
    end
  end

  # recibe una tupla con tres elementos: numero de la linea, contenido y resultado
  # se extrae el resultado y utiliza el case para comprobar si comienza con :error,
  # de esa forma devuelve tru, si no false, de esta manera con el stream.filter conserva las lineas validas

  def es_error?({_numero, _linea, resultado}) do
    case resultado do
      {:error, _} -> true
      _ -> false
    end
  end

  def escribir_error(archivo, {numero, linea, {:error, motivo}}) do
    IO.puts(archivo, "linea #{numero}: #{linea} - #{motivo}")
  end

  def escribir_solucion(solucion) do
    case File.write("soluciones.txt", "#{inspect(solucion)}\n", [:append]) do
      :ok -> :ok
      {:error, motivo} -> {:error, motivo}
    end
  end

  # se escriben progresivamente las soluciones

  def guardar_soluciones(n) do
    nombre = "reinas_n#{n}.txt"

    case File.open(nombre, [:write]) do
      {:ok, archivo} ->
        total =
          encontrar(n)
          |> Enum.reduce(0, fn solucion, numero ->
            escribir_tablero(archivo, solucion, n, numero + 1)
            numero + 1
          end)

        IO.puts(archivo, "total de soluciones: #{total}")

      {:error, motivo} ->
        IO.inspect(motivo)
    end
  end

  def primera_solucion do
    case File.open("primera_solucion_n20.txt", [:write]) do
      {:ok, archivo} ->
        encontrar(20)
        |> Stream.take(1)
        |> Enum.each(fn solucion -> escribir_tablero(archivo, solucion, 20, 1) end)

      {:error, motivo} ->
        IO.inspect(motivo)
    end
  end

  # Validación con recursión: verificar tableros propuestos
  def leer_propuestas do
    File.stream!("propuestas.txt")
  end

  def convertir_propuestas do
    leer_propuestas()
    |> Stream.map(&String.trim/1)
    |> Stream.filter(fn linea -> linea != "" and !String.starts_with?(linea, "#") end)
    |> Stream.map(fn linea ->
      linea
      |> String.split()
      |> Enum.map(fn numero -> String.to_integer(numero) end)
    end)
  end

  # VALIDACION DE TABLEROS PROPUESTOS

  def verificar_propuestas do
    if File.exists?("propuestas.txt") do
      case File.open("verificacion_reinas.txt", [:write]) do
        {:ok, archivo} ->
          File.stream!("propuestas.txt")
          |> Stream.with_index(1)
          |> Stream.map(fn {linea, numero} ->
            {numero, String.trim(linea)}
          end)
          |> Stream.filter(fn {_numero, linea} ->
            linea != "" and not String.starts_with?(linea, "#")
          end)
          |> Enum.each(fn {numero, linea} ->
            resultado =
              linea
              |> String.split()
              |> convertir_columnas()

            mensaje =
              case resultado do
                {:ok, columnas} ->
                  validar_tablero(columnas)

                {:error, motivo} ->
                  "inválida: #{motivo}"
              end

            IO.puts(archivo, "Línea #{numero}: #{linea} -> #{mensaje}")
            IO.puts("Línea #{numero}: #{linea} -> #{mensaje}")
          end)

          File.close(archivo)
          IO.puts("Se generó verificacion_reinas.txt")

        {:error, motivo} ->
          IO.inspect(motivo)
      end
    else
      IO.puts("No se encontró el archivo propuestas.txt")
    end
  end

  # Convierte los valores de texto a enteros mediante recursión

  defp convertir_columnas(lineas) do
    convertir_columnas(lineas, [])
  end

  defp convertir_columnas([], acumulado) do
  {:ok, invertir_lista(acumulado)}
end

  defp convertir_columnas([numero | resto], acumulado) do
    case Integer.parse(numero) do
      {valor, ""} ->
        convertir_columnas(resto, [valor | acumulado])

      _ ->
        {:error, "el valor #{numero} no es un entero"}
    end
  end

  # Cuenta los elementos de una lista mediante recursión

  defp contar_elementos([]), do: 0

  defp contar_elementos([_cabeza | cola]) do
    1 + contar_elementos(cola)
  end

  # Verifica todas las reinas del tablero

 defp validar_tablero(columnas) do
  n = contar_elementos(columnas)

  errores_limites = revisar_limites(columnas, 0, n, [])

  errores =
    case errores_limites do
      [] -> revisar_pares(columnas, 0, [])
      _ -> errores_limites
    end

  case errores do
    [] ->
      "válida"

    _ ->
      "inválida: " <> unir_errores(errores)
  end
end

  # Comprueba que ninguna columna esté fuera del tablero

  defp revisar_limites([], _fila, _n, errores) do
    invertir_lista(errores)
  end

  defp revisar_limites([columna | resto], fila, n, errores) do
    nuevos_errores =
      if columna < 0 or columna >= n do
        ["la columna #{columna} de la fila #{fila} está fuera del tablero" | errores]
      else
        errores
      end

    revisar_limites(resto, fila + 1, n, nuevos_errores)
  end

  # Compara cada reina con las que vienen después

  defp revisar_pares([], _fila, errores) do
    invertir_lista(errores)
  end

  defp revisar_pares([columna | resto], fila, errores) do
    nuevos_errores =
      comparar_reinas(columna, fila, resto, fila + 1, errores)

    revisar_pares(resto, fila + 1, nuevos_errores)
  end

  # Detecta conflictos de columna y diagonal

  defp comparar_reinas(_columna, _fila, [], _otra_fila, errores) do
    errores
  end

  defp comparar_reinas(columna, fila, [otra | resto], otra_fila, errores) do
    misma_columna = columna == otra

    misma_diagonal =
      abs(columna - otra) == abs(fila - otra_fila)

    nuevos_errores =
      cond do
        misma_columna ->
          ["reinas {#{fila},#{columna}} y {#{otra_fila},#{otra}} en la misma columna" | errores]

        misma_diagonal ->
          ["reinas {#{fila},#{columna}} y {#{otra_fila},#{otra}} en la misma diagonal" | errores]

        true ->
          errores
      end

    comparar_reinas(columna, fila, resto, otra_fila + 1, nuevos_errores)
  end

  # Invierte una lista mediante recursión

  defp invertir_lista(lista) do
    invertir_lista(lista, [])
  end

  defp invertir_lista([], acumulado), do: acumulado

  defp invertir_lista([cabeza | cola], acumulado) do
    invertir_lista(cola, [cabeza | acumulado])
  end

  # Une los mensajes de error

  defp unir_errores([ultimo]), do: ultimo

  defp unir_errores([cabeza | resto]) do
    cabeza <> "; " <> unir_errores(resto)
  end

  # SECUENCIA INFINITA DE N REINAS

  def generar_secuencia_reinas do
    case File.open("secuencia_reinas.csv", [:write]) do
      {:ok, archivo} ->
        IO.puts(archivo, "n;soluciones;tiempo_ms")

        Stream.iterate(1, fn n -> n + 1 end)
        |> Stream.map(fn n ->
          {tiempo, soluciones} =
            :timer.tc(fn ->
              Enum.count(encontrar(n))
            end)

          tiempo_ms = div(tiempo, 1000)

          {n, soluciones, tiempo_ms}
        end)
        |> Stream.take_while(fn {_n, _soluciones, tiempo} ->
          tiempo < 10_000
        end)
        |> Enum.each(fn {n, soluciones, tiempo} ->
          IO.puts(archivo, "#{n};#{soluciones};#{tiempo}")

          IO.puts(
            "N = #{n}: #{soluciones} soluciones, #{tiempo} ms"
          )

          comparar_oeis(n, soluciones)
        end)

        File.close(archivo)
        IO.puts("Se generó secuencia_reinas.csv")

      {:error, motivo} ->
        IO.inspect(motivo)
    end
  end

  # Comparación con la secuencia OEIS A000170

  defp comparar_oeis(n, soluciones) do
    esperado =
      case n do
        1 -> 1
        2 -> 0
        3 -> 0
        4 -> 2
        5 -> 10
        6 -> 4
        7 -> 40
        8 -> 92
        9 -> 352
        10 -> 724
        11 -> 2680
        12 -> 14200
        13 -> 73712
        14 -> 365596
        15 -> 2279184
        _ -> nil
      end

    case esperado do
      nil ->
        IO.puts("N = #{n}: sin comparación precargada")

      valor ->
        if soluciones == valor do
          IO.puts("Coincide con OEIS A000170")
        else
          IO.puts("No coincide con OEIS: se esperaban #{valor}")
        end
    end
  end


end

NReinas.ejecutar()

# Tablero.guardar_soluciones(5)

# Tablero.encontrar(20)
# |> Enum.take(1)
# |> IO.inspect()

# Tablero.generar_tamaños_errores()

# Tablero.procesar_tamaños() |> Enum.each(&IO.inspect/1)
# Tablero.mostrar_solucion(2)
# |> Stream.map(&Enum.reverse/1)
# |> Enum.to_list()
# |> IO.inspect()
