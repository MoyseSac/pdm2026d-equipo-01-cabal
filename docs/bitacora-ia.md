# Bitácora de uso de IA

## 2026-10-18 · Moisés Sac · Claude Code · Arreglar el CI en rojo

**Qué pedí:** revisar por qué `dart format` fallaba en el CI aunque en mi computadora pasaba, y arreglarlo.

**Qué respondió:** los 25 archivos sin formato eran salida de `dart format` aplicada en mi copia local pero nunca commiteada. El CI probaba el merge con el `main` actual, que tenía 34 archivos y no estaba formateado. Propuso una rama nueva, `chore/formato-dart`, con un commit solo de formato.

**Qué acepté:** el diagnóstico y el commit de formato, después de ver que `dart format`, `flutter analyze` y `flutter test` pasaban.

**Qué rechacé o corregí:**
- Su primera explicación (diferencia de versiones de Dart o cambios de otro integrante) era una suposición. Se corrigió al revisar `git diff` y ver que eran cambios de formato en mi copia local.
- Había sugerido commitear estos cambios en `chore/ci`, pero ese PR ya se había integrado. Se usó una rama nueva.

**Cómo lo verifiqué:** corrí los tres comandos del CI desde `app_cabal/` y revisé que el diff fuera solo formato.



## 2026-10-18 · Luis De Leon - Alexander Mendez - Julian Vasquez · ChatGPT · Implementación de cuatro estados en CatalogoScreen

**Qué pedí:** Revisar el repositorio Cabal y el laboratorio de CI para implementar correctamente los estados cargando, error, vacío y datos en la pantalla CatalogoScreen, incluyendo pruebas automatizadas.

**Qué respondió:** Propuso utilizar un FutureProvider de Riverpod conectado al servicio de productos existente, utilizar AsyncValue.when para manejar los cuatro estados y agregar un botón Reintentar que vuelva a consultar los productos mediante ref.invalidate. También propuso pruebas de widget utilizando un servicio falso mediante override.

**Qué acepté:** La creación de catalogo_provider.dart, la modificación de catalogo_screen.dart para manejar los cuatro estados y las pruebas automatizadas del catálogo.

**Qué rechacé o corregí:** Se decidió no actualizar Riverpod a la versión 3 ni reemplazar productoProvider, porque otras pantallas dependen de él. Se mantuvo el servicio SQLite existente, sin agregar funcionalidades nuevas ni modificar la base de datos.

**Cómo lo verifiqué:** Ejecuté dart format, flutter analyze y flutter test. El análisis terminó sin errores, las cuatro pruebas del catálogo fueron aprobadas y la suite completa finalizó con 105 pruebas aprobadas.