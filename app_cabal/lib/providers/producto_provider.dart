import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/producto_service.dart';

final productoServiceProvider = Provider<ProductoService>((ref) {
  return ProductoService();
});
