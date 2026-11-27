
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> mostrarNotificacion({
    required String titulo,
    required String mensaje,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'moneyflow_channel',
      'Notificaciones MoneyFlow',
      channelDescription: 'Avisos sobre tus gastos y presupuestos',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      id: 0,
      title: titulo,
      body: mensaje,
      notificationDetails: details,
    );
  }

  static Future<void> notificarPresupuesto({
    required double gastado,
    required double limite,
  }) async {
    if (limite <= 0) return;

    final porcentaje = gastado / limite;

    if (porcentaje >= 1) {
      await mostrarNotificacion(
        titulo: '¡Presupuesto excedido!',
        mensaje: 'Has superado tu límite de gastos.',
      );
    } else if (porcentaje >= 0.8) {
      await mostrarNotificacion(
        titulo: '¡Cuidado con tus gastos!',
        mensaje: 'Has utilizado el 80% de tu presupuesto.',
      );
    }
  }
}

