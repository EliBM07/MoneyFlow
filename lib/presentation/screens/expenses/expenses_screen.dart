import '../budgets/budgets_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/gasto.dart';
import '../../../data/repositories/gasto_repository.dart';
import 'expense_form_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final GastoRepository _gastoRepository = GastoRepository();

  List<Gasto> _gastos = [];
  bool _cargando = true;
  String? _error;

  final NumberFormat _formatoMoneda = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
  );

  double get _totalGastos {
    return _gastos.fold(0, (total, gasto) => total + gasto.monto);
  }

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final gastos = await _gastoRepository.obtenerGastos();

      if (!mounted) return;

      setState(() {
        _gastos = gastos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudieron cargar los gastos: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _abrirFormulario({Gasto? gasto}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(gasto: gasto),
      ),
    );

    if (resultado == true && mounted) {
      await _cargarGastos();
    }
  }

  Future<void> _eliminarGasto(Gasto gasto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Deseas eliminar "${gasto.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || gasto.id == null) return;

    try {
      await _gastoRepository.eliminarGasto(gasto.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gasto eliminado correctamente'),
        ),
      );

      await _cargarGastos();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _cargarGastos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_gastos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarGastos,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 110),
            Icon(Icons.receipt_long, size: 70, color: Colors.grey),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Todavía no tienes gastos registrados',
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 8),
            Center(child: Text('Pulsa + para registrar tu primer gasto')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarGastos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _gastos.length,
        itemBuilder: (context, index) {
          final gasto = _gastos[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () => _abrirFormulario(gasto: gasto),
              leading: const CircleAvatar(
                child: Icon(Icons.receipt_long),
              ),
              title: Text(
                gasto.titulo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${DateFormat('dd/MM/yyyy').format(gasto.fecha)}'
                    '\nCategoría: ${gasto.categoriaId}'
                    '${gasto.descripcion.isNotEmpty ? '\n${gasto.descripcion}' : ''}',
              ),
              isThreeLine: true,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatoMoneda.format(gasto.monto),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => _eliminarGasto(gasto),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis gastos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Presupuestos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BudgetsScreen(),
                ),
              );
            },
          ),
          IconButton(
            onPressed: _cargarGastos,
            icon: const Icon(Icons.refresh),
          ),
        ],

      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Total de gastos registrados'),
                  const SizedBox(height: 8),
                  Text(
                    _formatoMoneda.format(_totalGastos),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _construirContenido()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        tooltip: 'Agregar gasto',
        child: const Icon(Icons.add),
      ),
    );
  }
}
