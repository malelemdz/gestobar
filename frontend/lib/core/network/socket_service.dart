import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

class SocketService {
  final SecureStorageService _storage;
  IO.Socket? _socket;

  SocketService(this._storage);

  IO.Socket? get socket => _socket;

  Future<IO.Socket> connect() async {
    if (_socket != null) return _socket!;

    final token = await _storage.read(ApiConstants.keyJwtToken);
    
    _socket = IO.io(
      ApiConstants.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // Forzar WebSockets puros por velocidad
          .disableAutoConnect()
          .enableReconnection() // Activar reconexión automática
          .setReconnectionDelay(3000) // Empezar esperando 3 segundos
          .setReconnectionDelayMax(15000) // Máximo 15 segundos entre intentos
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('⚡ [WebSockets] Conectado al servidor Central');
    });

    _socket!.onDisconnect((_) {
      debugPrint('⚠️ [WebSockets] Desconectado del servidor');
    });

    // Interceptamos el error para no ensuciar la consola con "Connection refused"
    _socket!.onConnectError((error) {
      final errorStr = error.toString();
      if (errorStr.contains('Connection refused') || errorStr.contains('OS Error: 111')) {
        debugPrint('⏳ [WebSockets] Buscando servidor... reconectando pacíficamente.');
      } else {
        debugPrint('❌ [WebSockets] Error de Conexión: $error');
      }
    });

    _socket!.connect();
    return _socket!;
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final service = SocketService(storage);
  
  // Al montar el provider intentamos conectar inmediatamente (Opcional, pero recomendado)
  service.connect();
  
  ref.onDispose(() {
    service.disconnect();
  });
  
  return service;
});
