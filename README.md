# Cabal

> Ayudamos a tenderos de colonia a saber que productos les conviene seguir
> comprando y cuales no, a partir del registro de sus ventas diarias.

"Cabal" es la palabra que se usa en Guatemala cuando una cuenta sale exacta.
Ese es el resultado que buscamos entregar cada noche.

## El problema

Nuestro usuario primario es un tendero de 28 anos que administra desde hace
tres anos una tienda de colonia. Atiende solo durante buena parte del dia.

No lleva control de sus ventas comunes. En sus palabras: "realmente no se
lleva ningun control, solo tal vez al final contar todo lo que se junto en
efectivo". El cuaderno solo se usa para los productos que las empresas dejan
en consignacion, donde si es estricto porque debe cuadrar con el camion.

La consecuencia es que compra mercaderia sin datos. Al inicio pedia "a puro
calculo" y hoy decide que traer por lo que escucha que venden otras tiendas.
Cuando un producto no rota, lo descubre tarde: detecto un dulce que le costaba
mas pedir de lo que vendia solo porque ese producto si estaba en el cuaderno
de consignacion. Los productos que no pasan por ese cuaderno no tienen ese
filtro.

**Evidencia:** entrevista realizada por Julian el 11/07/2026, 30 minutos, con
autorizacion para tomar notas. Notas en `docs/entrevista_tendero.md`.

**Pendiente de verificar:** esta definicion se apoya en una sola entrevista.
Daniel, Alexander y Quique realizaran entrevistas adicionales
para confirmar si el patron se repite en otras tiendas o es un caso particular.

## Flujo principal del MVP

Abre la app -> registra cada venta durante el dia -> ve que productos se
movieron y cuales no


### Si entra en M1
1. Catalogo minimo de productos (nombre y precio)
2. Registro de venta como ingreso
3. Vista de cierre del dia 

### No entra todavia
1. Control de existencias (cantidades)
2. Alertas de stock bajo
3. Fechas de caducidad

Tambien quedan fuera: fiado, compras a proveedores, multiusuario y codigo de
barras. El fiado se descarta ademas por decision del propio usuario, que dejo
de otorgarlo tras una deuda impaga.

### Suposicion mas riesgosa
Que el tendero encuentre tiempo para registrar cada venta mientras atiende.
La entrevista confirma que en horas pico se forma cola, esta solo, y a veces
debe dejar el mostrador para ir a traer producto. Si el registro no es mas
rapido que no anotar nada, no lo va a usar.

### Fuera de nuestro alcance
El usuario senalo que su preocupacion mas grave es la inseguridad, no la
administracion. Lo registramos porque es cierto y porque condiciona cuanta
atencion puede dedicarle a cualquier herramienta nueva.

## Equipo y roles

Los roles rotan cada semana. Todos programan.

| Rol | Integrante | GitHub |
|---|---|---|
| Producto / PM | Julian | @JulianVgg |
| Arquitectura | Daniel | @DanielIxcot |
| UX / Investigacion | Alexander | @aemendez11 |
| QA | Quique | @Luisdl23 |
| Release | Moises | @MoyseSac |

## Como se trabaja aqui

Nadie hace push directo a `main`.

issue -> rama -> PR -> revision -> merge

1. Toma un issue asignado del milestone M1
2. Crea la rama: `issue-<numero>-<descripcion-corta>`
3. Commits que referencian el issue: `docs: definir alcance del MVP (#12)`
4. Abre PR contra `main` con `Closes #<numero>` en linea aparte
5. Asigna un reviewer que **no** hizo el cambio
6. El reviewer compara contra los criterios de aceptacion del issue
7. Con la aprobacion, se hace merge y el issue se cierra solo

## Documentación técnica
 
- [`docs/pantallas-navegacion-mvp.md`](docs/pantallas-navegacion-mvp.md) —
  pantallas del flujo principal del MVP y navegación entre ellas.
- [`docs/decision_estado_y_almacenamiento.md`](docs/decision_estado_y_almacenamiento.md) —
  decisión de manejo de estado (Provider) y almacenamiento local (sqflite),
  con las alternativas evaluadas.
  
## Privacidad

Los datos de las personas entrevistadas se manejan con alias. No publicamos
nombres, nombres de negocio ni ubicaciones en este repositorio.

## Uso de IA

**Nombre del proyecto:** la IA propuso una lista de nombres y el equipo eligio
InventaVenta, pero luego lo rechazamos por ser un juego de palabras dificil de
retener. Decidimos usar "Cabal", una palabra del habla comun en Guatemala.

**Roles del equipo:** la IA explico los cuatro roles y nos pregunto fortalezas
y disponibilidad uno por uno. Propuso una asignacion razonada y el equipo la
acepto sin cambios.

**Definicion del MVP:** la IA nos senalo que teniamos compra y venta invertidas
(compra es egreso, venta es ingreso) y lo corregimos. Tambien nos pregunto si
"inventario" significaba catalogo o control de existencias; el equipo decidio
dejar solo el catalogo en M1.

**Revision contra la evidencia:** al leer la entrevista, la IA detecto que el
borrador del README describia un problema que las notas no respaldaban (olvido
y perdida del cuaderno). El equipo verifico las notas, confirmo el error y
reescribio el problema con lo que el usuario dijo realmente.

**Convencion del repositorio:** la IA detecto que el nombre no cumplia el
formato pedido y lo corregimos a pdm2026d-equipo-01-cabal.

La evidencia, las entrevistas y las decisiones son del equipo.