# Tema de color

Issue: #94. Código: `app_cabal/lib/theme/tema_cabal.dart` y
`app_cabal/lib/constants/colores_cabal.dart`. Pruebas:
`app_cabal/test/tema_cabal_test.dart`.

## Por qué existe

La paleta B ("Marino y verde", ver `docs/diseno-pantalla-entrada.md`) solo la
usaba la pantalla de entrada. El resto de la app se veía con el tema morado
por defecto de Flutter, y había unos 45 colores fijos en el código
(`Colors.red`, `Colors.green`, `Colors.grey[...]`) que ignoraban cualquier
tema. Ahora hay un `ThemeData` con la paleta y las pantallas leen sus colores
de ahí.

Solo existe tema claro: la paleta no define modo oscuro.

## La regla

El color sale de `Theme.of(context).colorScheme`, no de `Colors.x` ni de un
`Color(0x...)` escrito en la pantalla. Así, cambiar un color de la paleta es
editar `colores_cabal.dart` y nada más. Las excepciones son
`Colors.transparent` y los parámetros del logo de la entrada
(`LogoCabal`, `PalabraCabal`), que se pensaron para fondo marino.

## Roles del `ColorScheme`

El esquema se arma a mano, sin `ColorScheme.fromSeed`, para que los colores
sean exactamente los aprobados y no tonos derivados de uno.

| Rol | Color | Uso | Contraste |
|---|---|---|---|
| `primary` / `onPrimary` | verde oscuro `#1B7F5C` / blanco | Botones llenos, botón flotante, foco de campos, botones de texto | 4.96 |
| `secondary` | marino `#0A2342` | Texto de botones con borde | |
| `surface` / `onSurface` | `#F4F8F7` / marino | Fondo de pantalla y texto principal | 14.7 |
| `onSurfaceVariant` | `#4B5F6B` | Textos secundarios | 6.23 sobre el fondo, 6.67 sobre blanco |
| `primaryContainer` / `onPrimaryContainer` | menta claro `#D3F5E6` / marino | Indicador de la barra de navegación | 13.49 |
| `error` / `onError` | `#B3261E` / blanco | Errores, borrar | 6.54 |
| `outline` | `#738884` | Bordes de campos y botones, iconos de estados vacíos | 3.51 sobre el fondo, 3.76 sobre blanco |
| `outlineVariant` | `#D5E0DD` | Borde decorativo de tarjetas y divisores | no lleva información |
| `surfaceContainerHighest` | `#E3EBE8` | Fondo de la imagen genérica de un producto | 5.50 con texto suave |
| `inverseSurface` | marino | Fondo de los avisos (SnackBar) | 15.77 con texto blanco |
| `surfaceContainer*` | blanco | Tarjetas, hojas inferiores, diálogos, barra de navegación | |

Los colores nuevos respecto a la paleta aprobada son `error`, `mentaClaro`,
`borde`, `bordeSuave` y `superficieTenue`. Se eligieron con el mismo
criterio que el resto: contraste calculado (WCAG 2.1) y no a ojo. Mínimos: 4.5
para texto y 3 para bordes e iconos.

Dos casos que conviene recordar:

- El verde oscuro sobre menta claro da 4.24, por debajo de 4.5. Sobre menta
  claro el texto va en marino, no en verde.
- El menta `#3DDC97` solo se usa sobre marino (8.92). Sobre fondo claro casi no
  se ve.

## Componentes

- **AppBar:** marino con título e iconos blancos, y barra de estado del
  teléfono con iconos claros. Sin elevación al desplazar.
- **Botones:** los llenos y los elevados son verde oscuro con texto blanco,
  forma de pastilla. Los de borde llevan texto marino y borde `outline`.
- **NavigationBar:** fondo blanco; la pestaña activa se marca con menta claro.
- **Tarjetas:** blancas, sin sombra, borde fino `outlineVariant`.
- **Campos de texto:** sin tema propio. Con este esquema el borde sale de
  `outline`, el foco y la etiqueta de `primary` y los errores de `error`. Un
  tema fijo pintaba la etiqueta de verde incluso en un campo con error.
- **Precio de un producto:** marino y negrita. El verde se reserva para
  acciones y para decir que algo salió bien (venta registrada).

## Cómo se prueba

- `test/tema_cabal_test.dart` comprueba los roles del esquema, el contraste de
  cada pareja texto/fondo de la tabla (4.5 para texto, 3 para bordes) y el
  aspecto del AppBar, de los botones y de la barra de navegación. Si alguien
  cambia un color y baja la legibilidad, la prueba falla.
- Capturas en `docs/evidencia-tema-de-color/`, tomadas en un emulador Android
  (Pixel 8 Pro) con la app compilada en modo release.

## Qué no cubre

- Modo oscuro.
- La tipografía Montserrat solo se usa en la pantalla de entrada; el resto de
  la app sigue con la fuente de Material.
- El ícono de la app y la pantalla de arranque nativa de Android (blanca con el
  logo de Flutter) no cambian con este tema.
- La insignia roja con la cantidad de productos en la pestaña Vender usa el
  color de error del tema (comportamiento por defecto de `Badge`).
