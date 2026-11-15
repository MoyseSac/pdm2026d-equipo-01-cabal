import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/ilustracion_estado_vacio.dart';
import '../widgets/estadisticas_cierre.dart';

import '../models/cierre.dart';
import '../providers/cierre_provider.dart';
import '../providers/tab_provider.dart';
import '../utils/fecha.dart';
import '../utils/moneda.dart';

const mensajeErrorCierre = 'No se pudo cerrar el día. Intenta de nuevo.';

/// Cuantos productos se ven antes de "Ver los N restantes".
const productosVisibles = 5;

/// Cifras alineadas en columna: todos los digitos miden lo mismo.
const _cifras = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

/// Cierre del día de hoy: cuánto se vendió y qué productos dejaron más, y un
/// botón para guardarlo. Si ya se cerró, muestra la foto guardada y avisa
/// cuando hay ventas nuevas.
class CierreDiaScreen extends ConsumerStatefulWidget {
  const CierreDiaScreen({super.key});

  @override
  ConsumerState<CierreDiaScreen> createState() => _CierreDiaScreenState();
}

class _CierreDiaScreenState extends ConsumerState<CierreDiaScreen> {
  bool _cerrando = false;

  /// Cerrar el dia guarda el cierre (y puede reemplazar uno anterior), asi que
  /// primero se pide confirmacion: un toque sin querer no lo cierra.
  Future<void> _pedirConfirmacion(CierreHoy hoy) async {
    if (_cerrando) return;

    final ventas = hoy.enVivo.numeroVentas;
    final resumen =
        'Se guardará el cierre de hoy con '
        '${ventas == 1 ? '1 venta' : '$ventas ventas'} '
        'y un total de ${formatearQuetzales(hoy.enVivo.total)}.';

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          hoy.cerrado ? '¿Volver a cerrar el día?' : '¿Cerrar el día?',
        ),
        content: Text(
          hoy.cerrado ? '$resumen Reemplaza el cierre anterior.' : resumen,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cerrar'),
          ),
        ],
      ),
    );

    if (confirmado == true && mounted) await _cerrar();
  }

  Future<void> _cerrar() async {
    if (_cerrando) return;
    setState(() => _cerrando = true);

    try {
      await ref.read(cierreAccionesProvider).cerrarHoy();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(mensajeErrorCierre)));
      }
    } finally {
      if (mounted) setState(() => _cerrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cierre = ref.watch(cierreHoyProvider);
    final hoy = cierre.asData?.value;
    final mostrarBarra = hoy != null && (hoy.hayVentas || hoy.cerrado);

    return Scaffold(
      appBar: AppBar(title: const Text('Cierre del día')),
      // La barra va en esta ranura y no dentro del cuerpo: asi un SnackBar
      // (por ejemplo el de error al cerrar) aparece encima de ella en lugar
      // de taparla, y se puede volver a intentar. Tambien deja el total y el
      // boton a la vista aunque haya muchos productos.
      bottomNavigationBar: mostrarBarra
          ? _BarraCierre(
              hoy: hoy,
              cerrando: _cerrando,
              onCerrar: () => _pedirConfirmacion(hoy),
            )
          : null,
      body: cierre.when(
        // Conserva lo que se ve mientras se vuelve a leer al entrar a la
        // pestaña o al cerrar el día.
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            _ErrorCierre(onReintentar: () => ref.invalidate(cierreHoyProvider)),
        data: (hoy) {
          if (!hoy.hayVentas && !hoy.cerrado) {
            return ListView(
              children: [
                _SinVentasHoy(
                  onRegistrarVenta: () => ref
                      .read(tabProvider.notifier)
                      .seleccionar(Pestana.vender),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: EstadisticasCierre(cierre: hoy.enVivo),
                ),
              ],
            );
          }
          return _CierreConDatos(hoy: hoy);
        },
      ),
    );
  }
}

class _CierreConDatos extends StatefulWidget {
  final CierreHoy hoy;

  const _CierreConDatos({required this.hoy});

  @override
  State<_CierreConDatos> createState() => _CierreConDatosState();
}

class _CierreConDatosState extends State<_CierreConDatos> {
  bool _verTodos = false;
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hoy = widget.hoy;
    final vista = hoy.vista;
    final textos = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;

    final productos = vista.productos;
    final muchos = productos.length > productosVisibles;
    final consulta = _busqueda.text.trim().toLowerCase();

    // Con pocos productos se ven todos. Con muchos, los de arriba; al
    // desplegar aparece el buscador para no recorrer toda la lista.
    final List<CierreProducto> lista;
    if (!muchos) {
      lista = productos;
    } else if (!_verTodos) {
      lista = productos.take(productosVisibles).toList();
    } else if (consulta.isEmpty) {
      lista = productos;
    } else {
      lista = productos
          .where((p) => p.nombre.toLowerCase().contains(consulta))
          .toList();
    }

    return ListView(
      key: const PageStorageKey('cierre_dia_lista'),
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              'Hoy · ${formatearFechaLarga(vista.dia)}',
              style: textos.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            _EstadoCierre(hoy: hoy),
          ],
        ),
        if (hoy.hayVentasNuevas) ...[
          const SizedBox(height: 14),
          _Aviso(
            texto:
                '${hoy.ventasNuevas == 1 ? '1 venta nueva' : '${hoy.ventasNuevas} ventas nuevas'} '
                'desde el cierre de las '
                '${formatearHora(hoy.guardado!.cerradoEn!)}. '
                'El cierre guardado era de '
                '${formatearQuetzales(hoy.guardado!.total)}.',
          ),
        ],
        const SizedBox(height: 14),
        _Resumen(
          cierre: vista,
          montoNuevo: hoy.hayVentasNuevas ? hoy.montoNuevo : null,
        ),
        const SizedBox(height: 16),
        EstadisticasCierre(cierre: vista),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Vendidos',
              style: textos.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'de mayor a menor monto',
                textAlign: TextAlign.end,
                style: textos.bodySmall?.copyWith(
                  color: colores.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (muchos && _verTodos) ...[
          TextField(
            key: const ValueKey('cierre_buscador'),
            controller: _busqueda,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar entre los ${productos.length} productos',
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (lista.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Ningún producto coincide con "${_busqueda.text.trim()}".',
              textAlign: TextAlign.center,
              style: textos.bodyMedium?.copyWith(
                color: colores.onSurfaceVariant,
              ),
            ),
          )
        else
          _ListaVendidos(productos: lista, total: vista.total),
        if (muchos) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            key: const ValueKey('cierre_ver_todos'),
            onPressed: () => setState(() {
              _verTodos = !_verTodos;
              if (!_verTodos) _busqueda.clear();
            }),
            child: Text(
              _verTodos
                  ? 'Mostrar solo los $productosVisibles primeros'
                  : 'Ver los ${productos.length - productosVisibles} restantes',
            ),
          ),
        ],
      ],
    );
  }
}

/// Etiqueta con el estado del dia: sin cerrar, cerrado o con ventas nuevas.
class _EstadoCierre extends StatelessWidget {
  final CierreHoy hoy;

  const _EstadoCierre({required this.hoy});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    final String texto;
    final Color fondo;
    final Color letra;
    if (hoy.hayVentasNuevas) {
      texto = 'Ventas nuevas';
      fondo = colores.secondary;
      letra = colores.onSecondary;
    } else if (hoy.cerrado) {
      texto = 'Cerrado ${formatearHora(hoy.guardado!.cerradoEn!)}';
      fondo = colores.primaryContainer;
      letra = colores.onPrimaryContainer;
    } else {
      texto = 'Sin cerrar';
      fondo = colores.surfaceContainerHighest;
      letra = colores.onSurface;
    }

    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 240),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: letra, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              texto,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: letra,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloque principal: el total del dia en grande y, debajo, ventas, productos
/// y unidades.
class _Resumen extends StatelessWidget {
  final Cierre cierre;

  /// Lo vendido despues del cierre guardado; null si no aplica.
  final double? montoNuevo;

  const _Resumen({required this.cierre, this.montoNuevo});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;
    final suave = colores.onSecondary.withValues(alpha: 0.78);

    Widget cifra(String valor, String etiqueta) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: textos.titleMedium
                ?.copyWith(
                  color: colores.onSecondary,
                  fontWeight: FontWeight.bold,
                )
                .merge(_cifras),
          ),
          Text(etiqueta, style: textos.bodySmall?.copyWith(color: suave)),
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      color: colores.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colores.secondary, colores.primary],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TOTAL DEL DÍA',
              style: textos.labelSmall?.copyWith(
                color: suave,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Semantics(
              label: 'Total del día: ${formatearQuetzales(cierre.total)}',
              child: ExcludeSemantics(
                child: TweenAnimationBuilder<double>(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 480),
                  tween: Tween(begin: 0, end: cierre.total),
                  curve: Curves.easeOutCubic,
                  builder: (context, valor, _) => Text(
                    formatearQuetzales(valor),
                    style: textos.displaySmall
                        ?.copyWith(
                          color: colores.onSecondary,
                          fontWeight: FontWeight.bold,
                        )
                        .merge(_cifras),
                  ),
                ),
              ),
            ),
            if (montoNuevo != null)
              Text(
                '+${formatearQuetzales(montoNuevo!)} desde el cierre',
                style: textos.bodySmall
                    ?.copyWith(
                      color: colores.inversePrimary,
                      fontWeight: FontWeight.w600,
                    )
                    .merge(_cifras),
              ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: colores.onSecondary.withValues(alpha: .18),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                cifra(
                  '${cierre.numeroVentas}',
                  cierre.numeroVentas == 1 ? 'venta' : 'ventas',
                ),
                cifra(
                  '${cierre.productos.length}',
                  cierre.productos.length == 1 ? 'producto' : 'productos',
                ),
                cifra(
                  '${cierre.unidades}',
                  cierre.unidades == 1 ? 'unidad' : 'unidades',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Productos vendidos, cada uno con su monto y una barra que muestra cuanto
/// pesa en el total del dia.
class _ListaVendidos extends StatelessWidget {
  final List<CierreProducto> productos;
  final double total;

  const _ListaVendidos({required this.productos, required this.total});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colores.surfaceContainerLowest,
        border: Border.all(color: colores.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (var i = 0; i < productos.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colores.outlineVariant),
            _FilaVendido(
              key: ValueKey('vendido_${productos[i].productoId}'),
              producto: productos[i],
              total: total,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaVendido extends StatelessWidget {
  final CierreProducto producto;
  final double total;

  const _FilaVendido({super.key, required this.producto, required this.total});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;

    final peso = total > 0 ? (producto.subtotal / total).clamp(0.0, 1.0) : 0.0;
    final porcentaje = peso * 100;
    final textoPeso = porcentaje < 1 ? '<1 %' : '${porcentaje.round()} %';
    final unidades = producto.unidades == 1
        ? '1 unidad'
        : '${producto.unidades} unidades';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: textos.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$unidades · $textoPeso del total',
                      style: textos.bodySmall
                          ?.copyWith(color: colores.onSurfaceVariant)
                          .merge(_cifras),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatearQuetzales(producto.subtotal),
                style: textos.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold)
                    .merge(_cifras),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              tween: Tween(begin: 0, end: peso),
              curve: Curves.easeOutCubic,
              builder: (context, valor, _) => LinearProgressIndicator(
                value: valor,
                minHeight: 5,
                color: colores.primary,
                backgroundColor: colores.surfaceContainerHighest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra fija de abajo: lo que se va a cerrar y el boton, o la nota de que el
/// dia ya esta cerrado.
class _BarraCierre extends StatelessWidget {
  final CierreHoy hoy;
  final bool cerrando;
  final VoidCallback onCerrar;

  const _BarraCierre({
    required this.hoy,
    required this.cerrando,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;
    final ventas = hoy.enVivo.numeroVentas;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colores.surfaceContainerLowest,
        border: Border(top: BorderSide(color: colores.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: hoy.puedeCerrar
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ventas == 1 ? '1 venta' : '$ventas ventas',
                          style: textos.bodySmall
                              ?.copyWith(color: colores.onSurfaceVariant)
                              .merge(_cifras),
                        ),
                        Text(
                          formatearQuetzales(hoy.enVivo.total),
                          style: textos.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold)
                              .merge(_cifras),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: cerrando ? null : onCerrar,
                        child: cerrando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                hoy.cerrado ? 'Volver a cerrar' : 'Cerrar día',
                              ),
                      ),
                    ),
                  ],
                )
              : Text(
                  'Día cerrado a las '
                  '${formatearHora(hoy.guardado!.cerradoEn!)}. '
                  'No hay nada más que guardar.',
                  textAlign: TextAlign.center,
                  style: textos.bodySmall?.copyWith(
                    color: colores.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final String texto;

  const _Aviso({required this.texto});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colores.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: colores.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(color: colores.onPrimaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCierre extends StatelessWidget {
  final VoidCallback onReintentar;

  const _ErrorCierre({required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'No se pudo cargar el cierre del día.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SinVentasHoy extends StatelessWidget {
  final VoidCallback onRegistrarVenta;

  const _SinVentasHoy({required this.onRegistrarVenta});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IlustracionEstadoVacio(estado: EstadoVacio.periodo),
            const SizedBox(height: 16),
            Text(
              'Hoy no hay ventas para cerrar',
              style: textos.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando registres ventas, aquí verás el total del día y '
              'podrás cerrarlo.',
              style: textos.bodyMedium?.copyWith(
                color: colores.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRegistrarVenta,
              icon: const Icon(Icons.add),
              label: const Text('Registrar venta'),
            ),
          ],
        ),
      ),
    );
  }
}
