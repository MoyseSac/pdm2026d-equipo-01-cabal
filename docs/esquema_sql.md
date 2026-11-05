# Esquema SQL para sqflite

## Contexto

A partir del diagrama entidad-relación definido en el issue #28, se establece
el esquema SQL que servirá como base para la persistencia local de los modelos
Producto, Venta y DetalleVenta mediante SQLite y sqflite.

Este documento define únicamente las tablas, columnas, tipos de datos, llaves
primarias y llaves foráneas. La implementación del acceso a la base de datos
en Dart se realizará en un issue posterior.

## Correspondencia de tipos

Los tipos utilizados en los modelos Dart se representan en SQLite de la
siguiente forma:

| Dart | SQLite |
|---|---|
| String | TEXT |
| double | REAL |
| int | INTEGER |
| DateTime | TEXT |

`DateTime` será almacenado como `TEXT` utilizando formato ISO 8601.

---

## Tabla producto

Representa los productos disponibles en el catálogo.

```sql
CREATE TABLE producto (
    id TEXT PRIMARY KEY,
    nombre TEXT NOT NULL,
    precio REAL NOT NULL,
    eliminado_en TEXT,
    imagen TEXT,
    icono TEXT,
    archivado_en TEXT
);
```

### Correspondencia con Producto

| Atributo Dart | Columna SQL | Tipo |
|---|---|---|
| id | id | TEXT |
| nombre | nombre | TEXT |
| precio | precio | REAL |
| imagen | imagen | TEXT (nullable) |
| icono | icono | TEXT (nullable) |

`eliminado_en` no tiene atributo en el modelo: guarda la fecha del borrado
lógico y el catálogo solo muestra los productos donde es `NULL`.
`archivado_en` guarda la fecha en que se archivó el producto; el catálogo
activo muestra solo los que no están borrados ni archivados.

`imagen` guarda solo el nombre del archivo de la foto, no la ruta completa.
`icono` guarda una clave del registro fijo de iconos
(`app_cabal/lib/constants/iconos_producto.dart`). Un producto tiene foto, o
icono, o ninguno de los dos, nunca ambos. Ver `docs/imagen_producto.md`.

---

## Tabla venta

Representa una venta realizada dentro del sistema.

```sql
CREATE TABLE venta (
    id TEXT PRIMARY KEY,
    fecha_hora TEXT NOT NULL
);
```

### Correspondencia con Venta

| Atributo Dart | Columna SQL | Tipo |
|---|---|---|
| id | id | TEXT |
| fechaHora | fecha_hora | TEXT |

El atributo `detalles` del modelo `Venta` no se almacena como una columna,
debido a que representa una relación con varios elementos de `DetalleVenta`.

Dicha relación se implementa mediante la tabla `detalle_venta`.

---

## Tabla detalle_venta

Representa cada producto incluido dentro de una venta.

```sql
CREATE TABLE detalle_venta (
    venta_id TEXT NOT NULL,
    producto_id TEXT NOT NULL,
    cantidad INTEGER NOT NULL,
    precio_al_momento REAL NOT NULL,

    PRIMARY KEY (venta_id, producto_id),

    FOREIGN KEY (venta_id)
        REFERENCES venta(id),

    FOREIGN KEY (producto_id)
        REFERENCES producto(id)
);
```

### Correspondencia con DetalleVenta

| Atributo Dart | Columna SQL | Tipo |
|---|---|---|
| producto | producto_id | TEXT |
| cantidad | cantidad | INTEGER |
| precioAlMomento | precio_al_momento | REAL |

La columna `venta_id` se agrega para establecer a qué venta pertenece cada
detalle.

---

## Tabla cierre

Representa el cierre de un día: una foto de lo que se vendió, guardada para
consultarla después aunque cambie el catálogo.

```sql
CREATE TABLE cierre (
    id TEXT PRIMARY KEY,
    dia TEXT NOT NULL,
    cerrado_en TEXT NOT NULL,
    numero_ventas INTEGER NOT NULL,
    total_centavos INTEGER NOT NULL
);

CREATE UNIQUE INDEX idx_cierre_dia ON cierre(dia);
```

### Correspondencia con Cierre

| Atributo Dart | Columna SQL | Tipo |
|---|---|---|
| id | id | TEXT |
| dia | dia | TEXT, `aaaa-mm-dd` en hora local |
| cerradoEn | cerrado_en | TEXT, ISO 8601 |
| numeroVentas | numero_ventas | INTEGER |
| total | total_centavos | INTEGER, centavos |

El dinero va en **centavos enteros**; el modelo Dart lo expone como `double`
dividiendo entre 100. El índice único deja un solo cierre por día: cerrar el
mismo día otra vez reemplaza el anterior.

---

## Tabla cierre_producto

Una fila por producto dentro de un cierre.

```sql
CREATE TABLE cierre_producto (
    cierre_id TEXT NOT NULL,
    producto_id TEXT NOT NULL,
    nombre_producto TEXT NOT NULL,
    unidades INTEGER NOT NULL,
    subtotal_centavos INTEGER NOT NULL,

    PRIMARY KEY (cierre_id, producto_id),

    FOREIGN KEY (cierre_id)
        REFERENCES cierre(id)
        ON DELETE CASCADE
);
```

### Correspondencia con CierreProducto

| Atributo Dart | Columna SQL | Tipo |
|---|---|---|
| productoId | producto_id | TEXT |
| nombre | nombre_producto | TEXT |
| unidades | unidades | INTEGER |
| subtotal | subtotal_centavos | INTEGER, centavos |

`unidades = 0` significa que el producto estaba en el catálogo activo y no
salió en las ventas del día ("sin vender"). Los archivados y borrados que no
se vendieron no se guardan.

`producto_id` **no** tiene llave foránea hacia `producto`: el cierre es una
foto, y el producto se puede archivar o borrar después sin afectarla. Por la
misma razón se copia el nombre, igual que `detalle_venta.nombre_producto`.

---

# Relaciones

## Venta y DetalleVenta

Una venta contiene uno o varios detalles de venta.

La relación se implementa mediante:

```text
venta.id → detalle_venta.venta_id
```

Cardinalidad:

```text
Venta 1 → N DetalleVenta
```

## Cierre y CierreProducto

Un cierre contiene una fila por cada producto que se vendió o que estaba sin
vender ese día.

```text
cierre.id → cierre_producto.cierre_id
```

Cardinalidad:

```text
Cierre 1 → N CierreProducto
```

`Cierre` no se relaciona con `venta` por llaves: se calcula agregando las
ventas del día (`SUM(cantidad * CAST(ROUND(precio_al_momento * 100) AS
INTEGER))` agrupado por `producto_id`) y se guarda el resultado.

## Producto y DetalleVenta

Cada detalle referencia un producto.

Un producto puede aparecer en ninguno o en múltiples detalles de venta.

La relación se implementa mediante:

```text
producto.id → detalle_venta.producto_id
```

Cardinalidad:

```text
Producto 1 → 0..N DetalleVenta
```

---

# Llaves

## Llaves primarias

- `producto.id`
- `venta.id`
- `detalle_venta (venta_id, producto_id)`
- `cierre.id`
- `cierre_producto (cierre_id, producto_id)`

La tabla `detalle_venta` utiliza una llave primaria compuesta porque un mismo
producto se representa una sola vez dentro de una venta. La cantidad de
unidades compradas se almacena en `cantidad`.

## Llaves foráneas

```text
detalle_venta.venta_id
    → venta.id

detalle_venta.producto_id
    → producto.id

cierre_producto.cierre_id
    → cierre.id
```

Estas llaves mantienen las relaciones definidas previamente en el diagrama
entidad-relación.

---

# Esquema general

```text
Producto
--------
id PK
nombre
precio
imagen
icono
archivado_en
    │
    │ 1
    │
    │ 0..N
    ▼
DetalleVenta
------------
venta_id PK, FK
producto_id PK, FK
cantidad
precio_al_momento
    ▲
    │ N
    │
    │ 1
Venta
-----
id PK
fecha_hora

Cierre
------
id PK
dia (único)
cerrado_en
numero_ventas
total_centavos
    │
    │ 1
    │
    │ N
    ▼
CierreProducto
--------------
cierre_id PK, FK
producto_id PK
nombre_producto
unidades
subtotal_centavos
```

`CierreProducto.producto_id` no es llave foránea (ver arriba).

## Versiones del esquema

La base se abre con `version: 5` en
`app_cabal/lib/services/database_service.dart`. Una instalación nueva crea
las tablas completas; una base anterior se actualiza en `onUpgrade`.

| Versión | Cambio |
|---|---|
| 1 | Tablas `producto`, `venta` y `detalle_venta`. |
| 2 | `producto.eliminado_en` y `detalle_venta.nombre_producto`, con el nombre copiado a las ventas existentes. |
| 3 | `producto.imagen` y `producto.icono`, ambas nullable. Los productos existentes quedan sin imagen; no se rellena nada. |
| 4 | `producto.archivado_en` (nullable) e índice único `idx_producto_nombre` sobre el nombre, sin distinguir mayúsculas, entre los productos no borrados. Los nombres repetidos que ya existían se renombran antes de crear el índice. |
| 5 | Tablas `cierre` y `cierre_producto` con el índice único `idx_cierre_dia`. No toca ninguna tabla anterior. |

Cada paso de `onUpgrade` se puede repetir sin fallar (`IF NOT EXISTS`, o se
comprueba con `PRAGMA table_info` antes de agregar una columna).

## Alcance

Este documento únicamente define el esquema SQL que utilizará la aplicación.

No se incluye todavía:

- apertura o creación de la base de datos desde Dart;
- ejecución de las sentencias mediante sqflite;
- operaciones CRUD;
- DAO o servicios;
- integración con Riverpod.

Estas funcionalidades corresponden a los siguientes issues.