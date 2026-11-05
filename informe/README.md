# Parcial 2 – Programación III (Elixir)

Universidad del Quindío · Ingeniería de Sistemas y Computación · Docente: Julián Esteban Gutiérrez Posada

**Problemas elegidos: 1 y 2** (combinación válida: el 1 cubre Streams infinitos y structs, el 2 cubre structs y SVG).

| Problema | Qué hace | Entradas | Salidas |
|---|---|---|---|
| 1. Rutas de entrega | Todos los itinerarios simples entre dos centros, óptimos por tramos/tiempo/costo, depuración recursiva y Stream infinito de alcance | `tramos.csv`, `consultas.txt` | `itinerarios.txt`, `errores_tramos.txt`, `depuracion_tramos.txt`, `alcance_centros.txt` |
| 2. Regiones de un mapa | Regiones conectadas (flood fill recursivo), área, perímetro, caja envolvente, validación recursiva y SVG | `mapa.txt`, `paleta.csv` | `regiones.csv`, `mapa_regiones.svg`, `resumen_regiones.txt`, `validacion_mapa.txt` |

## Cómo ejecutar

```bash
mix compile
```

```bash
mix run problema1.exs datos/problema1/ejemplo
```

```bash
mix run problema2.exs datos/problema2/ejemplo
```

Cada caso deja sus resultados en `salidas/problemaN/<caso>/`. También se puede indicar la carpeta de salida:

```bash
mix run problema1.exs datos/problema1/invalido salidas/prueba
```

Para ejecutar **todos** los casos de los dos problemas:

```bash
mix run ejecutar_todo.exs
```

Menú interactivo (usa `Util` y `Util2` para leer la opción):

```bash
mix run menu.exs
```

Pruebas automáticas (31 pruebas con ExUnit):

```bash
mix test
```

Desde la consola interactiva:

```bash
iex -S mix
```

```elixir
Problema1.main("datos/problema1/ejemplo")
Problema2.main("datos/problema2/ejemplo")
```

## Casos de prueba incluidos

| Carpeta | Tipo | Qué prueba |
|---|---|---|
| `datos/problema1/ejemplo` | válido | Red del enunciado: 4 itinerarios A→D, B→A sin itinerarios |
| `datos/problema1/invalido` | inválido | Campos de más/menos, texto en lugar de número, 0, negativos, origen vacío, bucle, repetidos (uno escrito con espacios), centro inexistente y consulta mal escrita |
| `datos/problema1/limite` | límite | Un solo tramo; consulta en sentido contrario; origen = destino |
| `datos/problema1/vacio` | límite | Archivo sin tramos (solo comentarios y líneas en blanco) |
| `datos/problema1/grande` | tamaño | 12 centros y 68 tramos: 3940 itinerarios N01→N12 |
| `datos/problema1/faltante` | error | Falta `consultas.txt`: lo informa sin excepción |
| `datos/problema2/ejemplo` | válido | Mapa del enunciado: 4 regiones, CSV idéntico al del PDF |
| `datos/problema2/invalido` | inválido | Filas de distinta longitud, símbolo sin color, color mal escrito, símbolo repetido, línea incompleta y falta de `.` |
| `datos/problema2/limite` | límite | Mapa de 1 × 1 |
| `datos/problema2/mapa_vacio` | límite | Mapa sin filas (solo comentarios): la validación lo reporta |
| `datos/problema2/solo_fondo` | límite | Solo fondo: 0 regiones |
| `datos/problema2/empates` | límite | 5 regiones empatadas; las diagonales no unen; nombre con `& " < >` para probar el escape XML |
| `datos/problema2/grande` | tamaño | Mapa de 24 × 36: 79 regiones |
| `datos/problema2/faltante` | error | Falta `paleta.csv` |

## Estructura del código

```
lib/
  util/util.ex, util/util2.ex   Módulos del curso, sin cambios
  comun/entrada.ex              Lectura perezosa con File.stream!/1 (comentarios, líneas en blanco, línea física)
  comun/salida.ex               Escritura por flujo (Stream.into / dispositivo abierto)
  comun/lista.ex                invertir/1 y contar/1 recursivas, para las validaciones
  problema1/tramo.ex            %Tramo{} y Tramo.parse/1
  problema1/itinerario.ex       %Itinerario{}
  problema1/depuracion.ex       Validación previa recursiva (bucles y repetidos)
  problema1/busqueda.ex         Grafo, búsqueda recursiva (backtracking) y óptimos con empates
  problema1/alcance.ex          Stream infinito de centros alcanzables
  problema1/problema1.ex        Programa principal del problema 1
  problema2/color.ex            %Color{}
  problema2/region.ex           %Region{}: área, perímetro, caja envolvente
  problema2/validacion.ex       Validación previa recursiva de mapa y paleta
  problema2/regiones.ex         recorrer_casillas/5 + explorar/5 (flood fill recursivo)
  problema2/svg.ex              SVG por fragmentos con escape XML
  problema2/problema2.ex        Programa principal del problema 2
test/                           Pruebas ExUnit
datos/                          Archivos de entrada de cada caso
```

## Cómo se cumplen los requisitos generales

1. **Lectura en flujo**: `Entrada.lineas_utiles/1` usa `File.stream!/1`. En todo el proyecto, incluidas las pruebas, nunca se usa `File.read!/1`.
2. **Transformaciones perezosas**: `Stream.with_index`, `Stream.map` y `Stream.reject`; el grafo y el mapa se arman después de consumir el Stream.
3. **Comentarios y espacios**: se ignoran las líneas en blanco y las que empiezan por `#` (después de espacios); cada línea conserva su número físico.
4. **Salidas por flujo**: `Salida.escribir/2` (con `Stream.into`) y `Salida.con_archivo/2`; el SVG es un `Stream.concat` de encabezado, casillas, etiquetas y cierre.
5. **Pantalla y archivo**: resúmenes con `Util2.mostrar/2`; el detalle va a los archivos.
6. **Errores de entrada**: `Entrada.verificar_archivos/1` informa qué archivo falta; los registros inválidos se reportan con línea y motivo.
7. **Validación recursiva sin Enum ni Stream**: `Rutas.Depuracion` y `Mapa.Validacion`, más `Lista`; una prueba automática verifica que esos archivos no usen `Enum.` ni `Stream.`.
8. **Convenciones**: coordenadas `{fila, columna}` desde 0; CSV con `;`.

### Decisiones de diseño

- Las líneas en blanco se ignoran también en `mapa.txt` (regla general 3). Por eso «fila vacía» solo puede pasar si el mapa no tiene filas, y así se reporta.
- Si falta el `.` en la paleta, se informa **una vez** y no en cada casilla de fondo.
- Si la validación del problema 2 falla, se borran `regiones.csv`, `mapa_regiones.svg` y `resumen_regiones.txt` de ejecuciones anteriores para que no queden resultados viejos.
- Una consulta con origen igual al destino da un itinerario de 0 tramos.

## Repositorio

URL: https://github.com/Joans-sebastian/https-github.com-usuario-parcial2elixir
