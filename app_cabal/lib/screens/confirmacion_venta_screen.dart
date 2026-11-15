import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tab_provider.dart';
import '../providers/venta_provider.dart';
import '../utils/moneda.dart';
import '../widgets/logo_cabal.dart';

/// Pantalla de confirmacion de venta. Se muestra solo cuando la venta se
/// guardo correctamente. Permite empezar otra venta de inmediato o volver
/// al catalogo.
class ConfirmacionVentaScreen extends ConsumerStatefulWidget {
  const ConfirmacionVentaScreen({super.key});

  @override
  ConsumerState<ConfirmacionVentaScreen> createState() =>
      _ConfirmacionVentaScreenState();
}

class _ConfirmacionVentaScreenState
    extends ConsumerState<ConfirmacionVentaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  bool _iniciada = false;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controlador.value = 1;
    } else if (!_iniciada) {
      _controlador.forward();
    }
    _iniciada = true;
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Widget _entrada(Widget child, double inicio) {
    final animacion = _controlador.drive(
      CurveTween(curve: Interval(inicio, 1, curve: Curves.easeOutCubic)),
    );
    return FadeTransition(
      opacity: animacion,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(animacion),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venta = ref.watch(ventaProvider).ventaConfirmada;

    return Scaffold(
      appBar: AppBar(title: const Text('Venta confirmada')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: LogoCabal(
                    tamano: 112,
                    colorTrazo: Theme.of(context).colorScheme.primary,
                    colorAcento: Theme.of(context).colorScheme.primary,
                    anillo: _controlador.drive(
                      CurveTween(
                        curve: const Interval(
                          0,
                          0.55,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    ),
                    visto: _controlador.drive(
                      CurveTween(
                        curve: const Interval(
                          0.3,
                          0.8,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Venta registrada',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                if (venta != null) ...[
                  const SizedBox(height: 8),
                  _entrada(
                    Text(
                      'Total: ${formatearQuetzales(totalDe(venta.detalles))}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    0.2,
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: _entrada(
                    ElevatedButton.icon(
                      onPressed: () => _nuevaVenta(context, ref),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Nueva venta'),
                    ),
                    0.35,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        _irAPestana(context, ref, Pestana.catalogo),
                    child: const Text('Volver al catálogo'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _irAPestana(context, ref, Pestana.ventas),
                    child: const Text('Ver ventas'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Empieza la siguiente venta donde se eligen los productos.
  void _nuevaVenta(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(ventaProvider.notifier);
    notifier.limpiar();
    _irAPestana(context, ref, Pestana.catalogo);
  }

  /// Desapila registrar venta y esta confirmacion hasta la barra de
  /// navegacion y muestra la pestana pedida.
  void _irAPestana(BuildContext context, WidgetRef ref, Pestana pestana) {
    ref.read(tabProvider.notifier).seleccionar(pestana);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
