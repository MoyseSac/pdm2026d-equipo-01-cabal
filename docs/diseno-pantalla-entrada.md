# Diseño de la pantalla de entrada

Issue: #92. Código: `app_cabal/lib/screens/entrada_screen.dart`,
`lib/widgets/logo_cabal.dart`, `lib/widgets/palabra_cabal.dart`,
`lib/constants/colores_cabal.dart`.

## Por qué existe

Cabal no tiene usuario ni contraseña. Se descartaron porque obligarían a tener
un servicio en la nube para registrar usuarios o reiniciar contraseñas, y el
catedrático indicó que sería una implementación innecesaria. En su lugar, la
app se abre con una pantalla de marca y pasa sola al inicio. La protección
será la huella o el desbloqueo del teléfono, que se hará en otro issue y se
enganchará en `EntradaScreen._continuar`.

## Decisiones de diseño

| Tema | Decisión | Motivo |
|---|---|---|
| Paleta | "Marino y verde" (opción B de las propuestas) | El verde remite a una cuenta que cuadra, que es lo que significa "cabal" (README). El marino da confianza sin parecer un banco. |
| Logo | La C con visto: anillo abierto a la derecha y un visto adentro | Dice el nombre y la idea del producto con dos trazos gruesos que aguantan tamaños pequeños. |
| Palabra | CABAL en Montserrat ExtraBold, letra por letra, la L en menta | La L repite el color del visto. |
| Dibujo del logo | `CustomPainter`, sin `flutter_svg` ni imágenes | Permite animar el trazo y no agrega dependencias. |
| Fuente | Archivo incluido en `assets/fonts/` (licencia OFL) | Funciona sin conexión y se ve igual en Android e iOS. Es una fuente variable: el grosor se pide con `FontVariation('wght', 800)`. |

### Colores (`ColoresCabal`)

| Nombre | Hex | Uso | Contraste |
|---|---|---|---|
| marino | `#0A2342` | Fondo de la entrada, barras | blanco sobre marino 15.77 |
| menta | `#3DDC97` | Acento solo sobre marino | menta sobre marino 8.92 |
| verdeOscuro | `#1B7F5C` | Acento sobre fondo claro, botones con texto blanco | blanco sobre verde 4.96 |
| fondoClaro | `#F4F8F7` | Pantallas internas | |
| textoSuave | `#4B5F6B` | Texto secundario | sobre fondo claro 6.23 |

El menta sobre fondo claro casi no se ve; sobre claro se usa `verdeOscuro`.

## Línea de tiempo

Un solo `AnimationController` de 2000 ms. Cada parte toma su tramo con un
`Interval` (fracciones de 0 a 1):

| Tramo | Qué pasa | Curva |
|---|---|---|
| 0.00 - 0.28 | Se dibuja el anillo de la C | easeInOut |
| 0.26 - 0.40 | Se dibuja el visto | easeOut |
| 0.40 - 0.88 | Aparecen C, A, B, A, L: suben 14 dp y se hacen visibles. Cada letra empieza 0.07 después de la anterior y dura 0.20 | easeOutCubic |
| 0.88 - 1.00 | Pausa con todo visible. Al llegar a 1 se navega | |

La pausa final va dentro del mismo controlador, y no como un `Future.delayed`
aparte, para que el paso a inicio ocurra al completarse la animación. Así las
pruebas que usan `pumpAndSettle` esperan también la navegación.

## Comportamiento

- Al terminar, la app hace `pushReplacementNamed` a inicio: la entrada no
  queda en la pila, y el botón de retroceso desde inicio no vuelve a ella.
- Tocar la pantalla lleva la animación al final y navega sin esperar. El
  tendero abre la app muchas veces al día y el README señala que el tiempo es
  el mayor riesgo.
- Con las animaciones del sistema desactivadas (`MediaQuery.disableAnimations`)
  se muestra la marca completa desde el primer cuadro y se navega a los 300 ms.
- Lectores de pantalla: se anuncia "Cabal" una vez; las letras y el logo no se
  leen por separado.
- Barra de estado transparente con iconos claros y barra de navegación en
  marino, con `AnnotatedRegion`, para que el estilo vuelva solo al de la
  pantalla siguiente al salir.

## Cómo se prueba

- Automático: `test/entrada_screen_test.dart` (aparición letra por letra,
  navegación a los 2 s, salto con toque, animaciones desactivadas, sin
  retroceso) y `test/logo_cabal_test.dart` (logo y palabra).
- Manual: abrir la app en frío y comprobar el flujo entrada → catálogo (P3 de
  `docs/plan-pruebas-manuales-catalogo-producto.md`).

## Verificación en emulador (Android 17, Pixel 8 Pro)

- El logo se dibuja, CABAL aparece en Montserrat con la L en menta y la app
  pasa sola al Catálogo.
- La barra de navegación toma el marino.
- Los iconos de la barra de estado se vieron oscuros sobre el marino en ese
  emulador, aunque la app pide iconos claros (una prueba confirma que envía
  `statusBarIconBrightness: light`). En un teléfono real, el de Moisés, se ven
  claros y legibles al abrir la app, así que se trata de un detalle del
  emulador. No se anotó el modelo del teléfono.
- Antes de la entrada se ve unos instantes la pantalla de arranque nativa de
  Android: blanca con el logo de Flutter. Ver "Pendiente".

## Pendiente (fuera de este trabajo)

- Huella o desbloqueo del teléfono con `local_auth` (cambio de
  `MainActivity` a `FlutterFragmentActivity`, permiso `USE_BIOMETRIC`).
- Pantalla de arranque nativa en marino (Android y iOS) para que no haya un
  destello blanco antes de la animación, y el ícono de la app con el logo.
- Volver a pedir autenticación al volver de segundo plano.
