
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/categoria.dart';
import '../../../data/models/presupuesto.dart';
import '../../../data/repositories/categoria_repository.dart';
import '../../../data/repositories/presupuesto_repository.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _presupuestoRepository = PresupuestoRepository();
  final _categoriaRepository = CategoriaRepository();

  final _moneda = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
  );

  List<Presupuesto> _presupuestos = [];
  List<Categoria> _categorias = [];

  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultados = await Future.wait([
        _presupuestoRepository.obtenerPresupuestos(),
        _categoriaRepository.obtenerCategorias(),
      ]);

      if (!mounted) return;

      setState(() {
        _presupuestos = resultados[0] as List<Presupuesto>;
        _categorias = resultados[1] as List<Categoria>;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudieron cargar los datos: $e';
        _cargando = false;
      });
    }
  }

  String _nombreCategoria(int id) {
    final categoria = _categorias.where((c) => c.id == id);

    return categoria.isEmpty
        ? 'Categoría desconocida'
        : categoria.first.nombre;
  }

  Future<void> _abrirFormulario({Presupuesto? presupuesto}) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => _BudgetDialog(
        categorias: _categorias,
        presupuesto: presupuesto,
      ),
    );

    if (resultado == true && mounted) {
      await _cargarDatos();
    }
  }

  Future<void> _eliminarPresupuesto(Presupuesto presupuesto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar presupuesto'),
        content: const Text(
          '¿Deseas eliminar este presupuesto?',
        ),
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

    if (confirmar != true || presupuesto.id == null) return;

    try {
      await _presupuestoRepository.eliminarPresupuesto(
        presupuesto.id!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presupuesto eliminado'),
        ),
      );

      await _cargarDatos();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _construirLista() {
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
            ElevatedButton(
              onPressed: _cargarDatos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_presupuestos.isEmpty) {
      return const Center(
        child: Text('Todavía no tienes presupuestos registrados'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _presupuestos.length,
      itemBuilder: (context, index) {
        final presupuesto = _presupuestos[index];

        return FutureBuilder<double>(
          future: _presupuestoRepository.calcularGastado(
            categoriaId: presupuesto.categoriaId,
            fechaInicio: presupuesto.fechaInicio,
            fechaFin: presupuesto.fechaFin,
          ),
          builder: (context, snapshot) {
            final gastado = snapshot.data ?? 0;
            final porcentaje = presupuesto.limite > 0
                ? (gastado / presupuesto.limite).clamp(0.0, 1.0)
                : 0.0;

            final restante = presupuesto.limite - gastado;

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _nombreCategoria(presupuesto.categoriaId),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _abrirFormulario(
                            presupuesto: presupuesto,
                          ),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () =>
                              _eliminarPresupuesto(presupuesto),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Límite: ${_moneda.format(presupuesto.limite)}',
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: snapshot.connectionState ==
                          ConnectionState.done
                          ? porcentaje
                          : null,
                      minHeight: 9,
                      color: porcentaje >= 1
                          ? Colors.red
                          : Colors.green,
                    ),
                    const SizedBox(height: 10),
                    Text('Gastado: ${_moneda.format(gastado)}'),
                    Text(
                      restante >= 0
                          ? 'Disponible: ${_moneda.format(restante)}'
                          : 'Excedido: ${_moneda.format(-restante)}',
                      style: TextStyle(
                        color: restante < 0
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Periodo: ${DateFormat('dd/MM/yyyy').format(presupuesto.fechaInicio)}'
                          ' - ${DateFormat('dd/MM/yyyy').format(presupuesto.fechaFin)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis presupuestos'),
        actions: [
          IconButton(
            onPressed: _cargarDatos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _construirLista(),
      floatingActionButton: FloatingActionButton(
        onPressed: _categorias.isEmpty
            ? null
            : () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BudgetDialog extends StatefulWidget {
  final List<Categoria> categorias;
  final Presupuesto? presupuesto;

  const _BudgetDialog({
    required this.categorias,
    this.presupuesto,
  });

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _limiteController = TextEditingController();

  int? _categoriaId;
  DateTime _inicio = DateTime.now();
  DateTime _fin = DateTime.now().add(const Duration(days: 30));
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    final presupuesto = widget.presupuesto;

    if (presupuesto != null) {
      _limiteController.text = presupuesto.limite.toString();
      _categoriaId = presupuesto.categoriaId;
      _inicio = presupuesto.fechaInicio;
      _fin = presupuesto.fechaFin;
    } else if (widget.categorias.isNotEmpty) {
      _categoriaId = widget.categorias.first.id;
    }
  }

  Future<void> _elegirFecha(bool esInicio) async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: esInicio ? _inicio : _fin,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (seleccionada == null) return;

    setState(() {
      if (esInicio) {
        _inicio = seleccionada;
        if (_fin.isBefore(_inicio)) {
          _fin = _inicio;
        }
      } else {
        _fin = seleccionada;
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoriaId == null || _fin.isBefore(_inicio)) return;

    setState(() => _guardando = true);

    try {
      final presupuesto = Presupuesto(
        id: widget.presupuesto?.id,
        categoriaId: _categoriaId!,
        limite: double.parse(_limiteController.text.trim()),
        fechaInicio: _inicio,
        fechaFin: _fin,
      );

      if (widget.presupuesto == null) {
        await PresupuestoRepository().crearPresupuesto(presupuesto);
      } else {
        await PresupuestoRepository().actualizarPresupuesto(presupuesto);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  void dispose() {
    _limiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.presupuesto == null
            ? 'Nuevo presupuesto'
            : 'Editar presupuesto',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _categoriaId,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                ),
                items: widget.categorias.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria.id,
                    child: Text(categoria.nombre),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _categoriaId = value);
                },
              ),
              TextFormField(
                controller: _limiteController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Límite de presupuesto',
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  final limite = double.tryParse(
                    (value ?? '').trim(),
                  );

                  if (limite == null ||
                      !limite.isFinite ||
                      limite <= 0) {
                    return 'Introduce un límite válido';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de inicio'),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(_inicio),
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () => _elegirFecha(true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de finalización'),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(_fin),
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () => _elegirFecha(false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando
              ? null
              : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: Text(_guardando ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}
