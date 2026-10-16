# Evidencia — Consulta básica de ventas registradas

Prueba manual del issue #54: registrar varias ventas, consultarlas, y comprobar
que siguen ahí después de reiniciar la aplicación.

## Datos de la ejecución

| Dato | Valor |
|---|---|
| Fecha | 2026-10-15 |
| Quién ejecutó | Claude Code, a pedido de alexander (manejó la app real con mouse y teclado; no fue una persona a mano) |
| Dispositivo | Windows de escritorio con `sqflite_common_ffi`, ventana de 430×880 |
| Preparación | Instalación limpia y 7 productos cargados desde la app |

No se probó en Android (no hay Android SDK ni emulador en el entorno de ejecución).

## Pasos y resultado

| Paso | Qué se hizo | Resultado | Evidencia |
|---|---|---|---|
| 1 | Con instalación limpia, abrir "Ventas registradas" desde el ícono de recibo del Catálogo. | Estado vacío: "Aún no hay ventas registradas" y "Las ventas que registres aparecerán aquí." | [`01-sin-ventas.png`](01-sin-ventas.png) |
| 2 | Registrar tres ventas con un minuto de diferencia: Coca Cola ×2; Pan dulce ×3 + Agua pura ×1; Aceite ×1. | Las tres se guardan y muestran la confirmación. | — |
| 3 | Abrir "Ventas registradas". | Tres ventas de la más reciente a la más antigua: `21:40 · 1 producto · Q19.99`, `21:39 · 2 productos · Q15.50`, `21:38 · 1 producto · Q21.00`. | [`02-lista-ventas.png`](02-lista-ventas.png) |
| 4 | Tocar la venta de las 21:39. | Detalle: Agua pura `1 × Q8.00` = `Q8.00`; Pan dulce `3 × Q2.50` = `Q7.50`; total `Q15.50`. | [`03-detalle-venta.png`](03-detalle-venta.png) |
| 5 | Cerrar la app a la fuerza, abrirla de nuevo y volver a "Ventas registradas". | Las mismas tres ventas, en el mismo orden y con los mismos totales; el detalle de la venta de las 21:39 es idéntico. | [`04-lista-tras-reiniciar.png`](04-lista-tras-reiniciar.png) |
| 6 | Comparar con la base de datos. | Tres filas en `venta` y cuatro en `detalle_venta`, con las mismas cantidades y precios que muestra la pantalla. | [`05-base-de-datos.txt`](05-base-de-datos.txt) |

## Resultado

Los 6 pasos se comportaron como se esperaba. No se encontraron defectos.
