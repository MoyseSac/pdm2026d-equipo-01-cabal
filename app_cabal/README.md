# Cabal

App para ayudar a tenderos de colonia a registrar sus ventas diarias y saber
qué productos conviene seguir comprando.

## Cómo ejecutar el proyecto

1. Clonar el repositorio:
   ```bash
   git clone <url-del-repo>
   cd app_cabal
   ```
2. Instalar las dependencias:
   ```bash
   flutter pub get
   ```
3. Correr la app (con un emulador o dispositivo conectado):
   ```bash
   flutter run
   ```

Si `flutter run` no detecta ningún dispositivo, revisa que tengas un emulador
abierto o un celular conectado con depuración USB activada. Puedes verificar
los dispositivos disponibles con:
```bash
flutter devices
```

## Sobre el `pubspec.yaml`

Es el archivo de configuración principal del proyecto, ubicado en la raíz
(no dentro de `lib/`). Ahí se define:

- **Nombre, descripción y versión** de la app.
- **Dependencias** (`dependencies:`): los paquetes que la app necesita para
  funcionar, por ejemplo `provider` para manejo de estado o `sqflite` para
  base de datos local.
- **Dependencias de desarrollo** (`dev_dependencies:`): paquetes que solo se
  usan mientras se programa, como los de testing o linting, no van en la
  app final.
- **Assets** (`assets:`): imágenes, fuentes u otros archivos estáticos que
  la app debe incluir.

Cada vez que alguien agrega, quita o actualiza un paquete, tiene que
modificar este archivo y correr `flutter pub get` para que el cambio se
aplique. Ejemplo de cómo se agrega un paquete:

```bash
flutter pub add provider
```

Este comando edita `pubspec.yaml` automáticamente y descarga el paquete; no
hace falta escribirlo a mano.

> Cualquier cambio a `pubspec.yaml` se sube al repositorio (no está en
> `.gitignore`), porque es lo que le dice a cada integrante qué paquetes
> necesita instalar con `flutter pub get`.

El proyecto también trae `pubspec.lock`, generado automáticamente. Guarda
las versiones exactas de cada dependencia instalada, para que todo el
equipo trabaje con las mismas versiones de los paquetes. No se edita a
mano; se actualiza solo al correr `flutter pub get`.

## Estructura del proyecto

Todo el código de la aplicación vive dentro de `lib/`, organizado por capas
para separar responsabilidades y evitar que todo termine en un solo archivo:

```text
lib/
├── main.dart
├── app.dart
├── constants/
├── models/
├── providers/
├── screens/
├── services/
├── utils/
└── widgets/
```

Se eligió una estructura por capas (no por feature) porque el MVP es chico
(catálogo, registro de venta, cierre del día). Si el proyecto crece a más
features grandes, se evaluará migrar a una estructura feature-first.

### `main.dart`

Punto de entrada de la app. Contiene únicamente:

```dart
void main() {
  runApp(const MyApp());
}
```

No debe tener lógica ni configuración; solo inicia la aplicación. Mantenerlo
así evita que varias personas lo modifiquen al mismo tiempo y genere
conflictos de merge.

### `app.dart`

Configuración principal de la app: `MaterialApp`, tema visual, rutas,
navegación y pantalla inicial. Se separa de `main.dart` para que el punto de
entrada quede simple.

### `models/`

Clases que representan los datos que maneja el sistema, por ejemplo
`Producto` y `Venta`. Sin lógica de UI ni de red — solo la forma de los
datos y métodos como `toJson`/`fromJson` si aplica.

### `screens/`

Cada pantalla completa de la app, en su propio archivo (catálogo, registro
de venta, cierre del día, etc.). Mantener cada pantalla en su archivo
permite modificarlas de forma independiente sin afectar a las demás.

### `widgets/`

Componentes visuales reutilizados en más de una pantalla: botones
personalizados, tarjetas, campos de texto, diálogos. Evita repetir el mismo
componente en varios lugares y mantiene la interfaz consistente.

### `services/`

Lógica que no es UI: peticiones a una API, acceso a base de datos local,
autenticación, cálculos de negocio (por ejemplo, el cierre del día). Separar
esto de las pantallas mantiene la arquitectura limpia y permite probar la
lógica sin depender de la interfaz.

### `providers/`

Manejo y distribución del estado de la app. Permite que distintas pantallas
o widgets accedan a información compartida (por ejemplo, el catálogo de
productos) sin tener que pasarla manualmente entre ellas.

### `utils/`

Funciones auxiliares reutilizables: validaciones, formateo de fechas,
formateo de moneda, conversiones. Evita duplicar código repetido en
distintas partes del proyecto.

### `constants/`

Valores fijos usados en varias partes de la app: colores del tema, textos
repetidos, rutas con nombre, configuraciones generales.

### Flujo recomendado dentro de `lib/`

1. El usuario interactúa con una pantalla en `screens/`.
2. La pantalla usa componentes reutilizables de `widgets/`.
3. El estado compartido se gestiona mediante `providers/`.
4. Los datos se representan con los modelos de `models/`.
5. Las operaciones con base de datos o API se resuelven en `services/`.
6. Funciones auxiliares y validaciones viven en `utils/`.
7. Valores fijos y configuraciones generales se guardan en `constants/`.

### Sobre los archivos `.gitkeep`

Las carpetas dentro de `lib/` todavía están vacías porque el MVP recién
empieza. Git no sube carpetas vacías, así que cada una tiene un archivo
`.gitkeep` con un comentario explicando su propósito. Al agregar el primer
archivo real de esa carpeta (por ejemplo, `models/venta.dart`), se borra el
`.gitkeep` correspondiente; ya no hace falta.

## Convenciones

- Nombres de archivo en `snake_case`, coincidiendo con la clase principal
  que contienen (`venta_service.dart` → clase `VentaService`).
- Nadie hace push directo a `main`. Flujo: issue → rama → PR → revisión → merge.
- Rama: `issue-<numero>-<descripcion-corta>`.
- Commits que referencian el issue: `feat: agregar modelo Venta (#12)`.

## Equipo y roles

Los roles rotan cada semana. Todos programan.

| Rol | Integrante | GitHub |
|---|---|---|
| Producto / PM | Julian | @JulianVgg |
| Arquitectura | Daniel | @DanielIxcot |
| UX / Investigacion | Alexander | @aemendez11 |
| QA | Quique | @Luisdl23 |
| Release | Moises | @MoyseSac |