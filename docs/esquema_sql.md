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
    precio REAL NOT NULL
);
```

### Correspondencia con Producto

| Atributo Dart | Columna SQL | Tipo |
|---|---|---|
| id | id | TEXT |
| nombre | nombre | TEXT |
| precio | precio | REAL |

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

La tabla `detalle_venta` utiliza una llave primaria compuesta porque un mismo
producto se representa una sola vez dentro de una venta. La cantidad de
unidades compradas se almacena en `cantidad`.

## Llaves foráneas

```text
detalle_venta.venta_id
    → venta.id

detalle_venta.producto_id
    → producto.id
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
```

## Alcance

Este documento únicamente define el esquema SQL que utilizará la aplicación.

No se incluye todavía:

- apertura o creación de la base de datos desde Dart;
- ejecución de las sentencias mediante sqflite;
- operaciones CRUD;
- DAO o servicios;
- integración con Riverpod.

Estas funcionalidades corresponden a los siguientes issues.