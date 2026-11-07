# Parcial 2 – Programación 3

Soluciones en **Elixir** de dos de los problemas del Parcial 2:

- **Problema 1:** Rutas entre ciudades.
- **Problema 4:** N reinas.

**Integrantes:** 

                 Jhonatan Perilla Betancur
                 Sergio Posada Garcia
                 Sara Benjumea Gallego
**Repositorio:** (https://github.com/SerrGioPosada/Parcial_2.git)

---

## Requisitos

- Elixir instalado (se comprueba con `elixir --version`).
- Los programas se ejecutan como scripts (`.exs`) desde la terminal, **parados en la carpeta de cada problema**, porque usan rutas relativas para leer y escribir archivos.
- En Windows, si en la terminal aparecen símbolos raros (`�`) en lugar de tildes, ejecutar antes `chcp 65001`. Los archivos generados se ven bien.

## Estructura del repositorio


```
Parcial_2/
├── README.md
├── Util.exs                  (si se usa desde RutaCiudades.exs)
├── Rutas/
│   ├── RutaCiudades.exs      programa principal
│   ├── Conexion.exs          struct %Conexion{} y parse/1
│   ├── Ruta.exs              struct %Ruta{}
│   ├── Depuracion.exs        validación previa con recursión
│   ├── Alcance.exs           ciudades alcanzables
│   ├── BuscadorRutas.exs     búsqueda recursiva de rutas
│   └── datos/                entradas y salidas
└── Nreinas/
    ├── nReinas.exs           programa principal
    ├── tamaños.txt           entrada: tamaños N
    └── propuestas.txt        entrada: tableros a verificar
```

---

## Problema 1: Rutas entre ciudades

Dadas una ciudad de origen y una de destino, encuentra todas las rutas posibles sin repetir ciudades, con su número de ciudades y su distancia total.

### Ejecución

```
cd Rutas
elixir RutaCiudades.exs
```

### Archivos

| Archivo | Tipo | Contenido |
|---|---|---|
| `datos/conexiones.csv` | entrada | `ciudad_a,ciudad_b,distancia_km`, una conexión por línea |
| `datos/consultas.txt` | entrada | `origen,destino`, una consulta por línea |
| `datos/errores_conexiones.txt` | salida | líneas mal formadas: número de línea, contenido y motivo |
| `datos/depuracion_conexiones.txt` | salida | conexiones descartadas por la depuración, con el motivo |
| `datos/alcance.txt` | salida | pasos del cálculo de ciudades alcanzables por consulta |
| `datos/rutas_encontradas.txt` | salida | rutas, número de rutas, ruta más corta y de menor distancia |

En los archivos de entrada se ignoran las líneas vacías y las que empiezan con `#`. Los números de línea cuentan todas las líneas del archivo. Los nombres de ciudad se normalizan a minúsculas, por eso aparecen así en las salidas.

### Cómo está resuelto

1. **Lectura con Streams.** `conexiones.csv` se lee con `File.stream!/1` y se limpia, numera, filtra y convierte de forma perezosa. Cada línea válida pasa por `Conexion.parse/1`, que devuelve `{:ok, %Conexion{}}` o `{:error, motivo}`. Las líneas con campos faltantes, ciudad vacía, distancia no numérica o negativa se reportan en `errores_conexiones.txt`.
2. **Depuración con recursión** (`Depuracion`). Antes de construir el grafo se recorre la lista de conexiones con funciones recursivas. Se descarta una conexión repetida (en el mismo sentido o en el contrario), una ciudad conectada consigo misma, y una conexión con distancia distinta a la de la primera aparición del mismo par. Cada descarte se escribe en `depuracion_conexiones.txt`.
3. **Grafo.** Se construye un mapa `ciudad => [{vecino, distancia}]`, con las conexiones en ambos sentidos.
4. **Consultas.** Cada línea de `consultas.txt` se procesa por separado. Si una ciudad no existe en el grafo, se indica en la salida y no se busca. Si existe, se calcula el alcance y solo si el destino es alcanzable se ejecuta la búsqueda recursiva. Si no lo es, se reporta "sin rutas".
5. **Alcance** (`Alcance`). Parte de un conjunto con solo el origen y en cada paso agrega los vecinos de las ciudades del paso anterior, hasta que un paso es igual al anterior. Los pasos se escriben en `alcance.txt`.
6. **Búsqueda de rutas** (`BuscadorRutas`). Recursión con retroceso: desde la ciudad actual se exploran los vecinos que todavía no están en el camino, acumulando el camino y la distancia. Al llegar al destino se devuelve un `%Ruta{ciudades, distancia}`.
7. **Reporte.** Para cada consulta se escriben, en pantalla y en archivo, todas las rutas con su número de ciudades y su distancia, el número de rutas, la ruta (o rutas) con menos ciudades y la de menor distancia.

### Structs

- `%Conexion{origen, destino, distancia}`
- `%Ruta{ciudades, distancia}`

### Ejemplo de salida (`rutas_encontradas.txt`)

```
=== armenia -> manizales ===
Ruta 1: armenia -> caicedonia -> sevilla -> cartago -> pereira -> santa rosa -> manizales (7 ciudades, 165 km)
Ruta 2: armenia -> caicedonia -> sevilla -> cartago -> pereira -> manizales (6 ciudades, 177 km)
Ruta 3: armenia -> cartago -> pereira -> santa rosa -> manizales (5 ciudades, 125 km)
Ruta 4: armenia -> cartago -> pereira -> manizales (4 ciudades, 137 km)
Ruta 5: armenia -> pereira -> santa rosa -> manizales (4 ciudades, 85 km)
Ruta 6: armenia -> pereira -> manizales (3 ciudades, 97 km)

Número de rutas: 6
Ruta(s) más corta(s) (por ciudades): armenia -> pereira -> manizales (3 ciudades)
Ruta(s) de menor distancia: armenia -> pereira -> santa rosa -> manizales (85 km)
```

Ejemplo de consulta sin rutas (`armenia,bogota`, porque Bogotá y Medellín quedan en otra componente del grafo):

```
=== armenia -> bogota ===
El destino no es alcanzable desde el origen (sin rutas).
```

Ejemplo de depuración (`depuracion_conexiones.txt`):

```
Linea 6: pereira, armenia, 45 -> repetida (Linea 2); se descarta
Linea 7: manizales, manizales, 0 -> conecta una ciudad consigo misma; se descarta
Linea 8: cartago, pereira, 30 -> distancia distinta a la original de la Linea 5; se descarta
```

---

## Problema 4: N reinas

Encuentra todas las formas de ubicar N reinas en un tablero N × N sin que se ataquen, verifica tableros propuestos y construye la secuencia del número de soluciones.

### Ejecución

```
cd Nreinas
elixir nReinas.exs
```

El programa ejecuta, en orden: lectura de tamaños y reporte de errores, búsqueda de soluciones por cada tamaño, primera solución de N=20, verificación de propuestas y secuencia infinita de N reinas. **La secuencia infinita es la parte lenta**, porque sigue hasta que el cálculo de un N tarda 10 segundos o más.

### Archivos

| Archivo | Tipo | Contenido |
|---|---|---|
| `tamaños.txt` | entrada | un valor de N por línea |
| `propuestas.txt` | entrada | un tablero por línea: el valor en la posición `i` es la columna de la reina de la fila `i` |
| `errores_tamaños.txt` | salida | tamaños no válidos, con número de línea, contenido y motivo |
| `reinas_n<N>.txt` | salida | todos los tableros numerados y el total de soluciones |
| `primera_solucion_n20.txt` | salida | primera solución para N=20 |
| `verificacion_reinas.txt` | salida | resultado de cada tablero propuesto |
| `secuencia_reinas.csv` | salida | `n;soluciones;tiempo_ms` |

Los nombres de archivo llevan ñ (`tamaños.txt`, `errores_tamaños.txt`). Si el programa dice que no encuentra el archivo en otro computador, revisar que el nombre se conservó con la ñ.

### Cómo está resuelto

1. **Representación.** Una solución es una lista de columnas, con la reina de la fila más reciente primero. Solo se coloca una reina por fila, así que nunca hay dos en la misma fila.
2. **Búsqueda recursiva y perezosa.** `encontrar/1` devuelve un `Stream` de soluciones. Para cada fila se prueba cada columna con `posicion?/2`, que usa la función recursiva `asegurar/3` para comparar la columna y las diagonales con las reinas ya colocadas. Si es seguro, se coloca la reina y se avanza a la fila siguiente. Si no, se descarta esa rama. Una solución solo se calcula cuando alguien la consume.
3. **Escritura progresiva.** Las soluciones se escriben en `reinas_n<N>.txt` a medida que el Stream las produce, sin guardarlas antes en una lista.
4. **Primera solución de N=20.** Se toma con `Stream.take(1)`. Termina rápido porque la búsqueda se detiene en cuanto aparece la primera solución, sin explorar el resto del árbol. Buscar todas las soluciones de N=20 no es viable por la cantidad de ramas que habría que recorrer.
5. **Validación de propuestas con recursión.** Cada línea de `propuestas.txt` se convierte a enteros y se verifica con funciones recursivas propias (sin `Enum` ni `Stream` en la validación): se revisan los límites y luego cada par de reinas, y se reportan todos los pares que se atacan (misma columna o misma diagonal) o las columnas fuera del tablero.
6. **Secuencia infinita.** `Stream.iterate(1, &(&1 + 1))` genera N = 1, 2, 3, … y se transforma en tuplas `{n, soluciones, tiempo_ms}`, midiendo cada cálculo con `:timer.tc/1`. Se toman términos mientras el cálculo tarde menos de 10 segundos y se escriben en `secuencia_reinas.csv` a medida que se calculan. Los resultados se comparan con la secuencia A000170 de la OEIS.
   - El término que supera el límite se calcula completo (no se interrumpe), pero no se escribe en el archivo.

### Resultados de ejemplo

| N | Soluciones |
|---|---|
| 4 | 2 |
| 5 | 10 |
| 6 | 4 |
| 8 | 92 |

Primeros términos de `secuencia_reinas.csv` (los tiempos dependen del computador):

```
n;soluciones;tiempo_ms
1;1;0
2;0;0
3;0;0
4;2;0
5;10;1
6;4;1
7;40;4
8;92;19
9;352;92
10;724;386
11;2680;1975
```

Ejemplo de `reinas_n4.txt`:

```
Solución 1:
. Q . .
. . . Q
Q . . .
. . Q .

Solución 2:
. . Q .
Q . . .
. . . Q
. Q . .

total de soluciones: 2
```

Ejemplo de `verificacion_reinas.txt`:

```
1 3 0 2 -> válida
0 2 1 3 -> inválida: reinas {0,0} y {3,3} en la misma diagonal; reinas {1,2} y {2,1} en la misma diagonal
1 3 0 0 -> inválida: reinas {2,0} y {3,0} en la misma columna
2 4 1 -> inválida: la columna 4 está fuera de un tablero de 3 × 3
```

---

## Informe

El documento PDF de entrega (datos y resultados, pruebas de escritorio, árboles de llamadas recursivas y reflexión sobre el uso de inteligencia artificial) se entrega por separado.
