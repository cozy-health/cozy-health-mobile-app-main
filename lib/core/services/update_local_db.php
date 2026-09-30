<?php

$db_service_path = 'c:\projects\cozyhealth\cozy-health-mobile-app-main-main\lib\core\services\local_db_service.dart';

$content = file_get_contents($db_service_path);

// Add imports
$imports_to_add = "import 'dart:async';\nimport 'package:connectivity_plus/connectivity_plus.dart';\nimport '../api/api_client.dart';\nimport '../api/api_exceptions.dart';\nimport '../models/sync_item.dart';\nimport 'package:uuid/uuid.dart';\n";
$content = str_replace("import 'package:hive_flutter/hive_flutter.dart';", "import 'package:hive_flutter/hive_flutter.dart';\n" . $imports_to_add, $content);

// In init():
$init_addition = <<<EOD
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        processSyncQueue();
      }
    });
    Timer.periodic(const Duration(minutes: 5), (_) {
      processSyncQueue();
    });
    Future.microtask(() => processSyncQueue());
  }
EOD;
$content = preg_replace('/await Hive.openBox<String>\(syncQueueBoxName\);\s*}/', "await Hive.openBox<String>(syncQueueBoxName);\n" . $init_addition, $content);

// Replace processSyncQueue and queueSync
$old_queueSync = <<<EOD
  Future<void> queueSync(String type, String id) async {
    final box = Hive.box<String>(syncQueueBoxName);
    await box.add("\$type:\$id");
    processSyncQueue();
  }

  bool _isSyncing = false;
  Future<void> processSyncQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;
    
    try {
      final box = Hive.box<String>(syncQueueBoxName);
      if (box.isEmpty) return;

      final keys = box.keys.toList();
      for (final key in keys) {
        final item = box.get(key);
        if (item != null) {
          // In real implementation, this hits the API.
          // For now, just dequeue.
          await box.delete(key);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
EOD;

$new_queueSync = <<<EOD
  Future<void> enqueueSync({
    required String type,
    required String action,
    required String recordId,
    Map<String, dynamic>? payload,
  }) async {
    final item = SyncItem(
      id: const Uuid().v4(),
      type: type,
      action: action,
      recordId: recordId,
      payload: payload,
      retryCount: 0,
      createdAt: DateTime.now().toUtc(),
    );
    await Hive.box<String>(syncQueueBoxName).put(item.id, item.toJson());
    processSyncQueue();
  }

  bool _isSyncing = false;
  Future<void> processSyncQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;
    
    try {
      final box = Hive.box<String>(syncQueueBoxName);
      final queue = box.values.map((e) => SyncItem.fromJson(e)).toList();
      if (queue.isEmpty) return;
      
      final eligible = queue.where((item) => 
        item.retryCount < 10 && 
        DateTime.now().isAfter(item.nextRetryAt ?? DateTime.now().subtract(const Duration(seconds: 1)))
      ).toList();
      
      if (eligible.isEmpty) return;
      
      for (var i = 0; i < eligible.length; i += 50) {
        final batch = eligible.skip(i).take(50).toList();
        
        final operations = batch.map((item) => {
          'type': item.type,
          'action': item.action,
          'data': item.action == 'delete' ? null : item.payload,
          'id': item.action == 'delete' ? item.recordId : null,
        }).toList();
        
        try {
          final response = await ApiClient.instance.post(
            '/sync/batch',
            data: {'operations': operations},
          );
          
          final results = response.data['data'] as List;
          
          for (var j = 0; j < batch.length; j++) {
            final item = batch[j];
            final result = results[j];
            
            if (result['success'] == true) {
              await box.delete(item.id);
            } else {
              await _incrementRetry(item);
            }
          }
        } on ApiAuthException {
          return;
        } catch (e) {
          for (final item in batch) {
            await _incrementRetry(item);
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _incrementRetry(SyncItem item) async {
    final newCount = item.retryCount + 1;
    final delay = _backoffDelay(newCount);
    final updatedItem = item.copyWith(
      retryCount: newCount,
      nextRetryAt: DateTime.now().add(delay),
    );
    await Hive.box<String>(syncQueueBoxName).put(updatedItem.id, updatedItem.toJson());
  }

  Duration _backoffDelay(int count) {
    if (count <= 1) return Duration.zero;
    if (count <= 3) return const Duration(seconds: 30);
    if (count <= 10) return const Duration(minutes: 5);
    return const Duration(hours: 1);
  }
EOD;

$content = str_replace($old_queueSync, $new_queueSync, $content);
file_put_contents($db_service_path, $content);
echo "LocalDbService updated\n";
