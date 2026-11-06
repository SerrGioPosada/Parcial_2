# se creara una lista de columnas, donde cada numero representara la solucion

# solo se pone una reina por fila, asi jamas se tendran dos en una fila

# una reina no puede compartir columna ni idagonal con ninguna reina anterior

defmodule NReinas do
  def ejecutar do
    generar_tamaños_errores()
    generar_archivos_reinas()
    primera_solucion()
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

  # defp asegurar(columna, [cabeza | cola], distancia) do
  #   igual_columna = columna == cabeza

  #   igual_diagonal =
  #     abs(columna - cabeza) == distancia + 1

  #   if igual_columna or igual_diagonal do
  #     false
  #   else
  #     asegurar(columna, cola, distancia + 1)
  #   end
  #  end

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
