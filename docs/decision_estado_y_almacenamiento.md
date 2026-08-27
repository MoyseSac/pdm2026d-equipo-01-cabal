# Decisión: manejo de estado y almacenamiento local

## Contexto

La app necesita guardar productos y ventas, y compartir esa información
entre pantallas (catálogo, registro de venta, cierre del día — ver
`docs/pantallas-navegacion-mvp.md`). Si cada integrante resuelve esto a su
manera, el código queda inconsistente y no se puede integrar. Esta decisión
queda escrita para que cualquiera la siga y entienda por qué se tomó.

**Fuera de alcance:** este documento no implementa la solución, solo la
decide y la documenta. Tampoco cubre sincronización con servidor.

**Depende de:** [#1](https://github.com/MoyseSac/pdm2026d-equipo-01-cabal/issues/1)
(modelos `Producto`, `DetalleVenta` y `Venta`, ya definidos en
`app_cabal/lib/models/`).

## Decisión 1: manejo de estado — Provider

Usaremos [`provider`](https://pub.dev/packages/provider) para compartir el
estado de productos y ventas entre pantallas (catálogo, registrar venta,
cierre del día).

**Por qué:**

- El flujo del MVP es lineal y el estado que se comparte es simple: una
  lista de productos y las ventas del día. No hay necesidad de manejar
  estados asíncronos complejos, cancelación de streams, ni composición
  profunda de dependencias.
- Es el paquete recomendado por el equipo de Flutter para apps de este
  tamaño, tiene poca curva de aprendizaje y poco boilerplate, lo cual
  importa porque todo el equipo programa (no hay un rol dedicado solo a
  arquitectura) y estamos en un MVP con tiempo limitado.
- Ya existe una carpeta `lib/providers/` en la estructura del proyecto, lo
  que confirma que esta era la dirección esperada al definir el esqueleto
  del proyecto.
- Se integra directamente con `ChangeNotifier`, que combina bien con clases
  de datos simples como las que ya definimos en `lib/models/`.

**Cómo se usará (a alto nivel, sin implementar todavía):**

- Un `ProductoProvider` (o similar) expone la lista de productos y las
  operaciones de catálogo (agregar/editar producto).
- Un `VentaProvider` expone las ventas del día y la operación de registrar
  una venta.
- Las pantallas leen estos providers con `context.watch` / `Consumer` y
  escriben con `context.read`.

## Decisión 2: almacenamiento local — sqflite (SQLite)

Usaremos [`sqflite`](https://pub.dev/packages/sqflite) para persistir
productos y ventas en el dispositivo.

**Por qué:**

- Los datos son relacionales por diseño: una `Venta` tiene una lista de
  `DetalleVenta`, y cada `DetalleVenta` referencia un `Producto`. Esto es
  exactamente el caso de uso para el que existe SQL (llaves foráneas,
  joins), y evita tener que reimplementar esa lógica de relación a mano en
  Dart.
- La pantalla de cierre del día (ver `docs/pantallas-navegacion-mvp.md`)
  necesita agregaciones por fecha ("qué productos se vendieron y cuáles
  no"). Eso es una consulta SQL directa (`WHERE fecha = ...`, `GROUP BY
  producto_id`) en vez de lógica manual de filtrado sobre listas en
  memoria cada vez que se reconstruye la vista.
- Los datos deben sobrevivir el cierre de la app (el tendero abre y cierra
  la app durante el día de atención), por lo que necesitamos persistencia
  real en disco, no solo estado en memoria.

## Alternativas evaluadas y descartadas

### Manejo de estado

| Alternativa | Por qué se descartó |
|---|---|
| **Riverpod** | Resuelve los mismos problemas que Provider pero con más conceptos (providers tipados, generación de código opcional, `ref` en vez de `context`). Para el tamaño de estado que maneja este MVP (dos listas compartidas) es complejidad adicional sin beneficio claro, y alarga la curva de aprendizaje para un equipo donde todos rotan de rol y programan. |
| **Bloc/Cubit** | Obliga a modelar cada acción como evento/estado explícito (mucho boilerplate: `Event`, `State`, `Bloc`) incluso para operaciones simples como "agregar producto" o "registrar venta". Tiene sentido en apps con lógica de negocio compleja o mucho estado asíncrono encadenado; aquí sería sobre-ingeniería para el alcance de M1. |
| **`setState` / `InheritedWidget` a mano** | No resuelve el problema real del issue: compartir el mismo catálogo y las mismas ventas entre pantallas distintas (Home, Registrar venta, Cierre del día) sin pasar callbacks manualmente por cada nivel del árbol de widgets. Cada integrante terminaría resolviéndolo distinto, que es justo la inconsistencia que este documento busca evitar. |

### Almacenamiento local

| Alternativa | Por qué se descartó |
|---|---|
| **Hive** | Es una base NoSQL de tipo clave-valor, rápida y fácil de usar, pero no maneja relaciones ni consultas tipo SQL de forma nativa. Con `Venta` → `List<DetalleVenta>` → `Producto`, tendríamos que hacer los "joins" y las agregaciones de cierre del día a mano en Dart, lo cual es exactamente el trabajo que SQLite ya resuelve. |
| **`shared_preferences`** | Solo sirve para pares clave-valor simples (strings, bools, números). No está pensado para colecciones de registros como productos y ventas, y no soporta consultas. Es una opción válida para configuración de la app (por ejemplo, una preferencia de usuario), pero no para el catálogo ni el historial de ventas. |

