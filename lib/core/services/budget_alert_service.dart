
import '../../data/models/gasto.dart';
import '../../data/repositories/presupuesto_repository.dart';
import 'notification_service.dart';

class BudgetAlertService {
  final PresupuestoRepository _presupuestoRepository;

  BudgetAlertService({
    PresupuestoRepository? presupuestoRepository,
  }) : _presupuestoRepository =
      presupuestoRepository ?? PresupuestoRepository();

  Future<void> comprobarPresupuesto(Gasto gasto) async {
    final presupuestos =
    await _presupuestoRepository.obtenerPresupuestos();

    for (final presupuesto in presupuestos) {
      if (presupuesto.categoriaId != gasto.categoriaId) {
        continue;
      }

      final fechaGasto = DateTime(
        gasto.fecha.year,
        gasto.fecha.month,
        gasto.fecha.day,
      );

      final inicio = DateTime(
        presupuesto.fechaInicio.year,
        presupuesto.fechaInicio.month,
        presupuesto.fechaInicio.day,
      );

      final fin = DateTime(
        presupuesto.fechaFin.year,
        presupuesto.fechaFin.month,
        presupuesto.fechaFin.day,
      );

      if (fechaGasto.isBefore(inicio) || fechaGasto.isAfter(fin)) {
        continue;
      }

      final gastado = await _presupuestoRepository.calcularGastado(
        categoriaId: presupuesto.categoriaId,
        fechaInicio: inicio,
        fechaFin: fin.add(const Duration(days: 1))
            .subtract(const Duration(microseconds: 1)),
      );

      await NotificationService.notificarPresupuesto(
        gastado: gastado,
        limite: presupuesto.limite,
      );
    }
  }
}
