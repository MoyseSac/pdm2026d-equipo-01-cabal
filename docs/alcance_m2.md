# Alcance y prioridades de M2

## Objetivo

El objetivo de M2 es tener funcionando de punta a punta el catálogo y el registro de productos.

Durante este milestone el equipo se enfocará en las pantallas y funcionalidades relacionadas con productos, dejando el registro de ventas y el cierre del día para milestones posteriores.

## Funcionalidades que sí entran en M2

### Catálogo de productos

M2 incluye la pantalla de catálogo, donde el tendero podrá consultar los productos registrados.

### Agregar producto

M2 incluye la funcionalidad para registrar un nuevo producto y agregarlo al catálogo.

### Editar producto

M2 incluye la funcionalidad para seleccionar un producto existente, modificar sus datos y guardar los cambios.

El flujo principal esperado para M2 es:

`Catálogo -> Agregar/editar producto -> Guardar -> Catálogo`

## Funcionalidades que no entran en M2

Las siguientes funcionalidades quedan fuera del alcance de M2:

- Registrar una venta.
- Confirmación de venta.
- Cierre del día.

Estas funcionalidades se dejan para milestones posteriores porque primero se necesita contar con un catálogo de productos funcional.

El registro de ventas dependerá de los productos existentes en el catálogo, por lo que se prioriza completar primero el manejo de productos antes de continuar con el flujo de ventas y cierre del día.

## Dependencias de M2

M2 depende de trabajo y decisiones realizadas previamente en M1.

### Modelos

Se utilizarán los modelos ya definidos en:

`app_cabal/lib/models/`

En particular, las funcionalidades de este milestone utilizarán el modelo `Producto` definido previamente.

M2 no redefine estos modelos, sino que los utiliza como base para implementar el catálogo y las operaciones de agregar y editar productos.

### Manejo de estado y almacenamiento

M2 utilizará la decisión de manejo de estado y almacenamiento documentada previamente en:

`docs/decision_estado_y_almacenamiento.md`

De acuerdo con esta decisión:

- El manejo de estado compartido se realizará con Riverpod.
- La persistencia local de los productos se realizará con sqflite (SQLite).

De esta forma, las pantallas relacionadas con productos utilizarán la misma estrategia definida por el equipo desde M1.

## Resultado esperado de M2

Al finalizar M2 debe ser posible:

1. Abrir el catálogo de productos.
2. Consultar los productos registrados.
3. Agregar un nuevo producto.
4. Guardar el producto.
5. Ver el producto dentro del catálogo.
6. Seleccionar un producto existente.
7. Editar sus datos.
8. Guardar los cambios.

El registro de ventas, la confirmación de venta y el cierre del día no son necesarios para considerar completado M2.

