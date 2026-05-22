import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'hive_entities/sync_queue_hive.dart';

class SyncWorker {
  final Dio dio;
  bool _isSyncing = false;
  StreamSubscription? _connectivitySubscription;

  SyncWorker(this.dio) {
    // Escucha activamente los cambios de red (WiFi/Datos)
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || 
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        processQueue();
      }
    });
    
    // Al iniciar, si hay internet, procesamos la cola pendiente
    processQueue();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> processQueue() async {
    if (_isSyncing) return;
    
    final connectivityResult = await Connectivity().checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.mobile) && 
        !connectivityResult.contains(ConnectivityResult.wifi) &&
        !connectivityResult.contains(ConnectivityResult.ethernet)) {
      return; 
    }

    _isSyncing = true;

    try {
      final box = Hive.box<SyncQueueTaskHive>('sync_queue');
      
      if (box.isEmpty) {
        _isSyncing = false;
        return;
      }

      // Obtener tareas ordenadas por fecha de creación
      final pendingTasks = box.values.toList();
      pendingTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (var task in pendingTasks) {
        try {
          final payloadData = jsonDecode(task.payload);
          
          if (task.method == 'POST') {
            await dio.post(task.endpoint, data: payloadData);
          } else if (task.method == 'PATCH') {
            await dio.patch(task.endpoint, data: payloadData);
          } else if (task.method == 'DELETE') {
            await dio.delete(task.endpoint, data: payloadData);
          }

          // Si llegó hasta aquí, NestJS respondió 200 OK. Borramos la tarea.
          await task.delete(); // HiveObject expone el método delete() directamente
          
        } on DioException catch (e) {
          if (e.type == DioExceptionType.connectionTimeout || 
              e.type == DioExceptionType.receiveTimeout || 
              e.type == DioExceptionType.connectionError) {
            break; // Se cortó el internet a mitad de sincronización
          }
          
          task.retries += 1;
          await task.save();
          
        } catch (e) {
          break; // Error desconocido, abortar sincronización por ahora
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
