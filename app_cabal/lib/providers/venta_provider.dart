import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/detalle_venta.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import '../services/venta_service.dart';

const mensajeVentaSinProductos = 'Agrega al menos un producto a la venta.';
const mensajeCantidadInvalida = 'La cantidad debe ser mayor que cero.';
const mensajeErrorGuardado = 'No se pudo registrar la venta. Intenta de nuevo.';

enum EstadoRegistroVenta { inactivo, guardando, exito, error }

/// Suma de subtotales (cantidad x precio al momento), redondeada a 2
/// decimales trabajando en centavos para evitar errores de representacion.
double totalDe(List<DetalleVenta> detalles) {
  final centavos = detalles.fold<int>(
    0,
    (suma, d) => suma + (d.cantidad * d.precioAlMomento * 100).round(),
  );
  return centavos / 100;
}

class VentaState {
  /// Venta en curso: un detalle por producto distinto.
  final List<DetalleVenta> detalles;
  final EstadoRegistroVenta estado;
  final String? mensajeError;

  /// Ultima venta guardada correctamente (para la pantalla de confirmacion).
  final Venta? ventaConfirmada;

  const VentaState({
    this.detalles = const [],
    this.estado = EstadoRegistroVenta.inactivo,
    this.mensajeError,
    this.ventaConfirmada,
  });

  bool get guardando => estado == EstadoRegistroVenta.guardando;

  double get total => totalDe(detalles);

  VentaState copyWith({
    List<DetalleVenta>? detalles,
    EstadoRegistroVenta? estado,
    String? mensajeError,
    bool limpiarError = false,
    bool limpiarConfirmada = false,
  }) {
    return VentaState(
      detalles: detalles ?? this.detalles,
      estado: estado ?? this.estado,
      mensajeError: limpiarError ? null : (mensajeError ?? this.mensajeError),
      ventaConfirmada: limpiarConfirmada ? null : ventaConfirmada,
    );
  }
}

final ventaServiceProvider = Provider<VentaService>((ref) {
  return VentaService();
});

final ventaProvider = StateNotifierProvider<VentaNotifier, VentaState>((ref) {
  final ventaService = ref.watch(ventaServiceProvider);

  return VentaNotifier(ventaService);
});

class VentaNotifier extends StateNotifier<VentaState> {
  final VentaService _ventaService;

  VentaNotifier(this._ventaService) : super(const VentaState());

  /// Agrega un producto a la venta en curso. Si ya estaba, suma la cantidad
  /// al detalle existente y conserva su precio al momento (regla R8).
  /// Devuelve false (con el mensaje en el estado) si la cantidad no es
  /// valida, o false sin cambios si hay un guardado en curso.
  bool agregarProducto(Producto producto, int cantidad) {
    if (state.guardando) return false;

    if (cantidad <= 0) {
      state = state.copyWith(
        estado: EstadoRegistroVenta.error,
        mensajeError: mensajeCantidadInvalida,
      );
      return false;
    }

    final detalles = [...state.detalles];
    final indice = detalles.indexWhere((d) => d.producto.id == producto.id);

    if (indice == -1) {
      detalles.add(
        DetalleVenta(
          producto: producto,
          cantidad: cantidad,
          precioAlMomento: producto.precio,
        ),
      );
    } else {
      final existente = detalles[indice];
      detalles[indice] = DetalleVenta(
        producto: existente.producto,
        cantidad: existente.cantidad + cantidad,
        precioAlMomento: existente.precioAlMomento,
      );
    }

    state = state.copyWith(
      detalles: detalles,
      estado: EstadoRegistroVenta.inactivo,
      limpiarError: true,
      limpiarConfirmada: true,
    );
    return true;
  }

  void quitarProducto(String productoId) {
    if (state.guardando) return;

    state = state.copyWith(
      detalles:
          state.detalles.where((d) => d.producto.id != productoId).toList(),
      estado: EstadoRegistroVenta.inactivo,
      limpiarError: true,
    );
  }

  /// Descarta la venta en curso y cualquier resultado anterior.
  void limpiar() {
    if (state.guardando) return;

    state = const VentaState();
  }

  /// Registra la venta en curso. Devuelve true solo si se guardo.
  /// Si falla, la venta en curso se conserva para poder reintentar (R11).
  /// Mientras se guarda, nuevas llamadas se ignoran para no duplicar la
  /// venta.
  Future<bool> confirmarVenta() async {
    if (state.guardando) return false;

    if (state.detalles.isEmpty) {
      state = state.copyWith(
        estado: EstadoRegistroVenta.error,
        mensajeError: mensajeVentaSinProductos,
      );
      return false;
    }

    state = state.copyWith(
      estado: EstadoRegistroVenta.guardando,
      limpiarError: true,
      limpiarConfirmada: true,
    );

    final ahora = DateTime.now();
    final venta = Venta(
      id: ahora.microsecondsSinceEpoch.toString(),
      fechaHora: ahora,
      detalles: List.unmodifiable(state.detalles),
    );

    try {
      await _ventaService.registrarVenta(venta);
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
          estado: EstadoRegistroVenta.error,
          mensajeError: mensajeErrorGuardado,
        );
      }
      return false;
    }

    if (mounted) {
      state = VentaState(
        estado: EstadoRegistroVenta.exito,
        ventaConfirmada: venta,
      );
    }
    return true;
  }
}
