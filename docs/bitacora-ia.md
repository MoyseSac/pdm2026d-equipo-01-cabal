# Bitácora de uso de IA

## 2026-10-18 · Moisés Sac · Claude Code · Arreglar el CI en rojo

**Qué pedí:** revisar por qué `dart format` fallaba en el CI aunque en mi computadora pasaba, y arreglarlo.

**Qué respondió:** los 25 archivos sin formato eran salida de `dart format` aplicada en mi copia local pero nunca commiteada. El CI probaba el merge con el `main` actual, que tenía 34 archivos y no estaba formateado. Propuso una rama nueva, `chore/formato-dart`, con un commit solo de formato.

**Qué acepté:** el diagnóstico y el commit de formato, después de ver que `dart format`, `flutter analyze` y `flutter test` pasaban.

**Qué rechacé o corregí:**
- Su primera explicación (diferencia de versiones de Dart o cambios de otro integrante) era una suposición. Se corrigió al revisar `git diff` y ver que eran cambios de formato en mi copia local.
- Había sugerido commitear estos cambios en `chore/ci`, pero ese PR ya se había integrado. Se usó una rama nueva.

**Cómo lo verifiqué:** corrí los tres comandos del CI desde `app_cabal/` y revisé que el diff fuera solo formato.
