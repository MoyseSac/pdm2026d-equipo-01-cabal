# Reglas de validación de producto

## Objetivo

Este documento define las reglas que deben cumplir los datos de un producto antes de poder guardarse.

Las reglas están escritas para que puedan traducirse directamente a validaciones de formulario en Flutter.

Este documento únicamente define las reglas y mensajes de error. La implementación en código queda fuera del alcance de este issue.

## Modelo relacionado

Las reglas corresponden al modelo `Producto`, definido en:

`app_cabal/lib/models/producto.dart`

El modelo contiene los siguientes campos:

- `id`
- `nombre`
- `precio`

El campo `id` es manejado internamente por la aplicación y no debe ser ingresado manualmente por el tendero.

Los campos que el tendero debe completar son:

- Nombre
- Precio

## Validación del nombre

### Campo obligatorio

El nombre del producto es obligatorio.

Antes de validar el contenido se deben eliminar los espacios al inicio y al final.

Casos inválidos:

- Campo vacío
- Solo espacios

Mensaje de error:

`Ingresa el nombre del producto.`

### Nombre válido

Después de aplicar `trim()`, cualquier texto no vacío se considera válido.

Ejemplos válidos:

- Coca Cola
- Pan dulce
- Agua pura
- Doritos

No se define en este documento una regla para evitar nombres repetidos.

## Validación del precio

### Campo obligatorio

El precio del producto es obligatorio.

Si el campo está vacío, debe mostrarse el siguiente mensaje:

`Ingresa el precio del producto.`

### Debe ser un número válido

El valor ingresado debe poder convertirse a un número decimal.

Casos inválidos:

- abc
- veinte
- Q10

Mensaje de error:

`Ingresa un precio válido.`

El símbolo de moneda no debe escribirse dentro del campo.

### Debe ser mayor que cero

El precio debe ser estrictamente mayor que `0`.

Casos inválidos:

- 0
- 0.00
- -5
- -10.50

Mensaje de error:

`El precio debe ser mayor que cero.`

### Máximo dos decimales

El precio puede tener como máximo dos cifras decimales.

Ejemplos válidos:

- 1
- 5.5
- 10.50
- 25.99

Ejemplos inválidos:

- 10.555
- 2.999

Mensaje de error:

`El precio puede tener máximo 2 decimales.`

## Resumen de validaciones

| Campo | Caso inválido | Mensaje de error |
| --- | --- | --- |
| Nombre | Vacío o solo espacios | `Ingresa el nombre del producto.` |
| Precio | Vacío | `Ingresa el precio del producto.` |
| Precio | No es un número | `Ingresa un precio válido.` |
| Precio | Es igual o menor que cero | `El precio debe ser mayor que cero.` |
| Precio | Tiene más de dos decimales | `El precio puede tener máximo 2 decimales.` |

## Comportamiento esperado del formulario

Al presionar el botón para guardar:

1. Se valida el nombre.
2. Se valida el precio.
3. Si existe algún error, el producto no se guarda.
4. El mensaje correspondiente debe mostrarse debajo del campo inválido.
5. Si todos los campos son válidos, el formulario puede continuar con la operación de agregar o editar el producto.

Estas reglas deben utilizarse tanto al agregar un producto nuevo como al editar uno existente.

## Traducción directa a validaciones en Flutter

### Nombre

La validación debe seguir esta lógica:

- Aplicar `trim()`.
- Si el valor queda vacío, devolver:
  `Ingresa el nombre del producto.`

### Precio

La validación debe seguir esta lógica:

- Si el campo está vacío, devolver:
  `Ingresa el precio del producto.`
- Intentar convertir el valor a número.
- Si no puede convertirse, devolver:
  `Ingresa un precio válido.`
- Si el valor es menor o igual a cero, devolver:
  `El precio debe ser mayor que cero.`
- Si tiene más de dos cifras decimales, devolver:
  `El precio puede tener máximo 2 decimales.`

