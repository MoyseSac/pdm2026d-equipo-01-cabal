import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cierre.dart';
import '../providers/cierre_provider.dart';
import '../providers/tab_provider.dart';
import '../utils/fecha.dart';
import '../utils/moneda.dart';

const mensajeErrorCierre = 'No se pudo cerrar el día. Intenta de nuevo.';

/// Cierre del día de hoy: cuánto se vendió, qué se movió y qué no, y un botón
/// para guardarlo. Si ya se cerró, muestra la foto guardada y avisa cuando
/// hay ventas nuevas.
class CierreDiaScreen extends ConsumerStatefulWidget {
  const CierreDiaScreen({super.key});

  @override
  ConsumerState<CierreDiaScreen> createState() => _CierreDiaScreenState();
}

class _CierreDiaScreenState extends ConsumerState<CierreDiaScreen> {
  bool _cerrando = false;

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

    return Scaffold(
      appBar: AppBar(title: const Text('Cierre del día')),
      // El boton va en esta ranura y no dentro del cuerpo: asi un SnackBar
      // (por ejemplo el de error al cerrar) aparece encima del boton en lugar
      // de taparlo, y se puede volver a intentar.
      bottomNavigationBar: hoy != null && hoy.puedeCerrar
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton(
                  onPressed: _cerrando ? null : _cerrar,
                  child: _cerrando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(hoy.cerrado ? 'Volver a cerrar' : 'Cerrar día'),
                ),
              ),
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
            return _SinVentasHoy(
              onRegistrarVenta: () =>
                  ref.read(tabProvider.notifier).seleccionar(Pestana.vender),
            );
          }
          return _CierreConDatos(hoy: hoy);
        },
      ),
    );
  }
}

class _CierreConDatos extends StatelessWidget {
  final CierreHoy hoy;

  const _CierreConDatos({required this.hoy});

  @override
  Widget build(BuildContext context) {
    final vista = hoy.vista;
    final textos = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;
    final vendidos = vista.vendidos;
    final sinVender = vista.sinVender;
    final cerradoSinCambios = !hoy.puedeCerrar;

    return ListView(
      key: const PageStorageKey('cierre_dia_lista'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(formatearFecha(vista.dia), style: textos.titleMedium),
        const SizedBox(height: 8),
        if (hoy.hayVentasNuevas) ...[
          _Aviso(
            icono: Icons.info_outline,
            texto:
                'Hay ventas nuevas desde el cierre de las '
                '${formatearFechaHora(hoy.guardado!.cerradoEn!)}.',
          ),
          const SizedBox(height: 12),
        ] else if (cerradoSinCambios) ...[
          _Aviso(
            icono: Icons.check_circle_outline,
            texto:
                'Día cerrado el '
                '${formatearFechaHora(hoy.guardado!.cerradoEn!)}.',
          ),
          const SizedBox(height: 12),
        ],
        _Resumen(total: vista.total, numeroVentas: vista.numeroVentas),
        const SizedBox(height: 24),
        Text('Vendidos (${vendidos.length})', style: textos.titleMedium),
        const SizedBox(height: 4),
        for (final producto in vendidos)
          ListTile(
            key: ValueKey('vendido_${producto.productoId}'),
            contentPadding: EdgeInsets.zero,
            title: Text(producto.nombre),
            subtitle: Text(
              producto.unidades == 1
                  ? '1 unidad'
                  : '${producto.unidades} unidades',
            ),
            trailing: Text(
              formatearQuetzales(producto.subtotal),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        const SizedBox(height: 16),
        Text('Sin vender (${sinVender.length})', style: textos.titleMedium),
        const SizedBox(height: 4),
        if (sinVender.isEmpty)
          Text(
            'Todo lo que tienes en el catálogo se vendió hoy.',
            style: textos.bodyMedium?.copyWith(color: colores.onSurfaceVariant),
          )
        else
          for (final producto in sinVender)
            ListTile(
              key: ValueKey('sin_vender_${producto.productoId}'),
              contentPadding: EdgeInsets.zero,
              title: Text(producto.nombre),
            ),
      ],
    );
  }
}

class _Resumen extends StatelessWidget {
  final double total;
  final int numeroVentas;

  const _Resumen({required this.total, required this.numeroVentas});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total del día',
              style: textos.bodyMedium?.copyWith(
                color: colores.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatearQuetzales(total),
              style: textos.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              numeroVentas == 1 ? '1 venta' : '$numeroVentas ventas',
              style: textos.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Aviso({required this.icono, required this.texto});

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
          children: [
            Icon(icono, color: colores.onPrimaryContainer),
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
            Icon(Icons.event_busy_outlined, size: 64, color: colores.outline),
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
