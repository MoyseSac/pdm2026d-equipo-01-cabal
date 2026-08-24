# Guia de entrevistas — Tenderos de colonia

## Proposito

Esta guia se aplica a las entrevistas T2, T3 y T4. Su objetivo es confirmar o
corregir los hallazgos de la entrevista T1 (`docs/entrevista_tendero.md`) y
resolver decisiones pendientes del milestone M1.

Todas las entrevistas usan las mismas preguntas en el mismo orden, para que las
respuestas sean comparables entre si.

## Reglas para el entrevistador

- Preguntar por hechos pasados, nunca por opiniones o intenciones futuras.
  "Cuenteme la ultima vez que..." en lugar de "¿le gustaria...?".
- No mencionar la aplicacion ni describir la solucion durante la entrevista.
- No sugerir la respuesta dentro de la pregunta.
- Una pregunta a la vez. Esperar a que termine antes de seguir.
- El silencio es util. Si la persona se queda callada, esperar.
- Pedir permiso para tomar notas antes de empezar.
- Anotar tambien lo que se observa, no solo lo que se dice.

## Decisiones que estas entrevistas deben resolver

| Pregunta del equipo | La responde |
|---|---|
| ¿El patron de T1 se repite en otras tiendas? | Bloque 1 |
| ¿Una venta lleva uno o varios productos? | Bloque 2 |
| ¿Como deciden que comprar? | Bloque 3 |
| ¿Detectan los productos que no rotan y como? | Bloque 4 |
| ¿Hay tiempo de registrar mientras atienden? | Bloque 5 |

## Datos a registrar

| Campo | Dato |
|---|---|
| Entrevistador | |
| Alias del entrevistado | T_ |
| Edad aproximada | |
| Tipo de negocio | |
| Tiempo atendiendo el negocio | |
| Fecha | |
| Duracion | |
| Permiso para tomar notas | |

> **Privacidad:** no registrar nombre real, nombre del negocio ni ubicacion.
> Usar alias (T2, T3, T4). Los datos completos quedan fuera del repositorio.

## Preguntas

### Bloque 1 — Control de ventas

1. Pensando en el dia de ayer o en el ultimo dia que abrio, ¿como llevo el
   control de lo que vendio?

   Seguimiento: ¿en donde lo anoto?

   Seguimiento: ¿que informacion registro?

   Seguimiento: ¿hubo ventas que no anoto?

### Bloque 2 — Composicion de la compra

2. Piense en los ultimos clientes que atendio hoy. ¿Que se llevo cada uno?

   Seguimiento: ¿en un dia normal, hay clientes que llevan varias cosas de
   una sola vez?

### Bloque 3 — Compra a proveedores

3. Cuenteme sobre la ultima vez que tuvo que hacer un pedido o comprar
   productos para surtir la tienda.

   Seguimiento: ¿como decidio que productos comprar?

   Seguimiento: ¿como calculo las cantidades?

### Bloque 4 — Productos que no rotan

4. ¿Podria contarme de la ultima vez que noto que un producto no se vendia
   como esperaba? ¿Como se dio cuenta?

   Seguimiento: ¿que hizo despues?

### Bloque 5 — Atencion en horas de mayor demanda

5. Cuenteme como fue el ultimo dia que tuvo muchos clientes al mismo tiempo.

   Seguimiento: ¿quien estaba atendiendo ese dia?

   Seguimiento: ¿hubo algo que se le dificulto?

### Bloque 6 — Cierre abierto

6. ¿Hay alguna situacion importante sobre administrar la tienda que no le
   haya preguntado y que considere que deberia conocer?

## Que entregar

Un archivo `docs/entrevista_t<N>.md` con:

- La tabla de datos completa
- Las respuestas transcritas lo mas literal posible
- Las observaciones del entrevistador, marcadas como tales
- Las frases textuales mas relevantes

## Cambios respecto a T1

- Se elimino la pregunta sobre como empezo en la tienda y la de que hace al
  abrir: dieron contexto pero no informan decisiones de M1.
- Se agrego el bloque 2, que no existia en T1, para resolver el modelo de datos.
- Se reformulo la pregunta sobre productos que no rotan para incluir como se
  dio cuenta.
- Se elimino la pregunta sobre ventas fiadas: el fiado quedo fuera del alcance
  del MVP.