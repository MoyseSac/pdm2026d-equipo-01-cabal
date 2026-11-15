import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/actividad_ventas.dart';
import '../models/cierre.dart';
import '../providers/cierre_provider.dart';
import '../utils/fecha.dart';
import '../utils/moneda.dart';
import 'entrada_ventas.dart';
import 'transicion_venta.dart';

class EstadisticasCierre extends ConsumerWidget {
  const EstadisticasCierre({super.key, required this.cierre});
  final Cierre cierre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actividad = ref.watch(actividadSemanaProvider);
    return actividad.when(
      skipLoadingOnReload: true,
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(semanticsLabel: 'Cargando comparación'),
      ),
      error: (_, _) => TextButton.icon(
        onPressed: () => ref.invalidate(actividadSemanaProvider),
        icon: const Icon(Icons.refresh),
        label: const Text('Reintentar comparación semanal'),
      ),
      data: (dias) => dias.length != 7
          ? const SizedBox.shrink()
          : _ComparacionSemanal(dias: dias, cierre: cierre),
    );
  }
}

class _ComparacionSemanal extends StatefulWidget {
  const _ComparacionSemanal({required this.dias, required this.cierre});
  final List<ActividadVentasDia> dias;
  final Cierre cierre;

  @override
  State<_ComparacionSemanal> createState() => _ComparacionSemanalState();
}

class _ComparacionSemanalState extends State<_ComparacionSemanal> {
  int _seleccionado = 6;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final hoy = widget.cierre;
    final dias = [
      ...widget.dias.take(6),
      ActividadVentasDia(
        dia: hoy.dia,
        ventas: hoy.numeroVentas,
        centavos: (hoy.total * 100).round(),
      ),
    ];
    final ayer = dias[5];
    final diferencia = dias[6].centavos - ayer.centavos;
    final cambio = ayer.centavos == 0 ? null : diferencia * 100 / ayer.centavos;
    final seleccionado = dias[_seleccionado];
    final maximo = dias.fold<int>(
      0,
      (maximo, d) => math.max(maximo, d.centavos),
    );
    final promedio = hoy.numeroVentas == 0 ? 0.0 : hoy.total / hoy.numeroVentas;
    final reducir = MediaQuery.disableAnimationsOf(context);
    const etiquetas = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return EntradaVentas(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colores.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colores.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Así va tu día', style: textos.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Hoy en curso · Ayer completo',
              style: textos.bodySmall?.copyWith(
                color: colores.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _Indicador(
                  titulo: 'Frente a ayer',
                  valor: cambio == null
                      ? 'Sin base porcentual'
                      : '${cambio > 0 ? '+' : ''}${cambio.toStringAsFixed(1)}%',
                  descripcion: diferencia == 0
                      ? 'El mismo monto que ayer'
                      : '${formatearQuetzales(diferencia.abs() / 100)} ${diferencia > 0 ? 'más' : 'menos'} en ventas',
                  icono: diferencia == 0
                      ? Icons.trending_flat
                      : diferencia > 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                ),
                _Indicador(
                  titulo: 'Promedio por venta',
                  valor: formatearQuetzales(promedio),
                  descripcion: 'Total de hoy ÷ ventas',
                  icono: Icons.receipt_long_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Últimos 7 días', style: textos.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Toca un día para consultar su total.',
              style: textos.bodySmall?.copyWith(
                color: colores.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: reducir
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colores.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TransicionVenta(
                desplazar: true,
                alignment: Alignment.topLeft,
                child: Column(
                  key: ValueKey(seleccionado.dia),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _seleccionado == 6
                          ? 'Hoy · ${formatearFecha(seleccionado.dia)}'
                          : formatearFechaLarga(seleccionado.dia),
                      style: textos.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatearQuetzales(seleccionado.total),
                      style: textos.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      seleccionado.ventas == 1
                          ? '1 venta'
                          : '${seleccionado.ventas} ventas',
                      style: textos.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(
                    constraints.maxWidth,
                    7 *
                        math.max(
                          48,
                          MediaQuery.textScalerOf(context).scale(11) * 3 + 12,
                        ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < dias.length; i++)
                        Expanded(
                          child: Semantics(
                            button: true,
                            onTap: () => setState(() => _seleccionado = i),
                            selected: i == _seleccionado,
                            label:
                                '${formatearFecha(dias[i].dia)}: ${formatearQuetzales(dias[i].total)}, ${dias[i].ventas} ventas',
                            excludeSemantics: true,
                            child: InkWell(
                              key: ValueKey('actividad_dia_$i'),
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() => _seleccionado = i),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 104,
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: TweenAnimationBuilder<double>(
                                          duration: reducir
                                              ? Duration.zero
                                              : const Duration(
                                                  milliseconds: 520,
                                                ),
                                          tween: Tween(
                                            begin: 0,
                                            end: maximo == 0
                                                ? 0
                                                : dias[i].centavos / maximo,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          builder: (context, valor, _) =>
                                              AnimatedContainer(
                                                duration: reducir
                                                    ? Duration.zero
                                                    : const Duration(
                                                        milliseconds: 180,
                                                      ),
                                                height: math.max(
                                                  2,
                                                  valor * 104,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: i == _seleccionado
                                                      ? colores.primary
                                                      : colores.onSurfaceVariant
                                                            .withValues(
                                                              alpha: 0.75,
                                                            ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: i == _seleccionado
                                                      ? Border.all(
                                                          color: colores
                                                              .onPrimaryContainer,
                                                          width: 2,
                                                        )
                                                      : null,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      i == 6
                                          ? 'Hoy'
                                          : etiquetas[dias[i].dia.weekday - 1],
                                      style: textos.labelSmall?.copyWith(
                                        fontWeight: i == _seleccionado
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.titulo,
    required this.valor,
    required this.descripcion,
    required this.icono,
  });
  final String titulo;
  final String valor;
  final String descripcion;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: colores.primary, size: 24),
        const SizedBox(height: 8),
        Text(titulo, style: textos.bodySmall),
        Text(
          valor,
          style: textos.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          descripcion,
          style: textos.bodySmall?.copyWith(color: colores.onSurfaceVariant),
        ),
      ],
    );
  }
}
