import '../../../core/services/budget_alert_service.dart';
import 'package:flutter/material.dart';

import '../../../data/models/gasto.dart';
import '../../../data/models/categoria.dart';
import '../../../data/repositories/gasto_repository.dart';
import '../../../data/repositories/categoria_repository.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Gasto? gasto;

  const ExpenseFormScreen({super.key, this.gasto});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _budgetAlertService = BudgetAlertService();

  final _tituloController = TextEditingController();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();

  final _gastoRepository = GastoRepository();
  final _categoriaRepository = CategoriaRepository();

  List<Categoria> _categorias = [];
  int? _categoriaSeleccionada;
  DateTime _fecha = DateTime.now();

  bool _cargando = true;
  bool _guardando = false;

  bool get _esEdicion => widget.gasto != null;

  @override
  void initState() {
    super.initState();

    final gasto = widget.gasto;

    if (gasto != null) {
      _tituloController.text = gasto.titulo;
      _montoController.text = gasto.monto.toString();
      _descripcionController.text = gasto.descripcion;
      _categoriaSeleccionada = gasto.categoriaId;
      _fecha = gasto.fecha;
    }

    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final categorias =
      await _categoriaRepository.obtenerCategorias();

      if (!mounted) return;

      setState(() {
        _categorias = categorias;

        if (_categoriaSeleccionada == null &&
            categorias.isNotEmpty) {
          _categoriaSeleccionada = categorias.first.id;
        }

        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _cargando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar categorías: $e')),
      );
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (fecha != null) {
      setState(() => _fecha = fecha);
    }
  }

  Future<void> _guardarGasto() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría'),
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final gasto = Gasto(
        id: widget.gasto?.id,
        titulo: _tituloController.text.trim(),
        monto: double.parse(_montoController.text.trim()),
        descripcion: _descripcionController.text.trim(),
        categoriaId: _categoriaSeleccionada!,
        fecha: _fecha,
      );

      if (_esEdicion) {
        await _gastoRepository.actualizarGasto(gasto);
      } else {
        await _gastoRepository.crearGasto(gasto);
      }

      try {
        await _budgetAlertService.comprobarPresupuesto(gasto);
      } catch (e) {
        debugPrint('Error al comprobar presupuesto: $e');
      }

      if (!mounted) return;


      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar el gasto: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'Editar gasto' : 'Nuevo gasto',
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _categorias.isEmpty
          ? const Center(
        child: Text('No hay categorías disponibles'),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del gasto',
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
                maxLength: 60,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduce el nombre del gasto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _montoController,
                keyboardType:
                const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final monto = double.tryParse(
                    (value ?? '').trim(),
                  );

                  if (monto == null || !monto.isFinite ||
                      monto <= 0) {
                    return 'Introduce un monto válido mayor que cero';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<int>(
                initialValue: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categorias.map((categoria) {
                  return DropdownMenuItem<int>(
                    value: categoria.id,
                    child: Text(categoria.nombre),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSeleccionada = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
                maxLength: 200,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: _seleccionarFecha,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  'Fecha: ${_fecha.day}/${_fecha.month}/${_fecha.year}',
                ),
              ),
              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed:
                _guardando ? null : _guardarGasto,
                icon: _guardando
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(
                  _guardando
                      ? 'Guardando...'
                      : 'Guardar gasto',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
