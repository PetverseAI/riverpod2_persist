import 'dart:async';

import 'utils/exec_queue.dart';
import 'storage_impl.dart';

class Riverpod2PersistStorage {
  factory Riverpod2PersistStorage(
      [String container = 'Storage', String? path, String? initialData]) {
    if (_sync.containsKey(container)) {
      return _sync[container]!;
    } else {
      final instance =
          Riverpod2PersistStorage._internal(container, path, initialData);
      _sync[container] = instance;
      return instance;
    }
  }

  Riverpod2PersistStorage._internal(String key,
      [String? path, String? initialData]) {
    _concrete = StorageImpl(key, path);
    _initialData = initialData;
    final that = this;

    initStorage = Future<Riverpod2PersistStorage>(() async {
      await _init();
      return that;
    });
  }

  static final Map<String, Riverpod2PersistStorage> _sync = {};

  final microtask = Microtask();

  /// Start the storage drive. It's important to use await before calling this API, or side effects will occur.
  static Future<Riverpod2PersistStorage> init([String container = 'Storage']) {
    return Riverpod2PersistStorage(container).initStorage;
  }

  Future<void> _init() async {
    try {
      await _concrete.init(_initialData);
    } catch (err) {
      rethrow;
    }
  }

  /// Reads value in your container
  String read<T>() {
    return _concrete.read();
  }

  /// Write data on your container
  Future<void> write(String value) async {
    writeInMemory(value);

    return _tryFlush();
  }

  void writeInMemory(String value) {
    _concrete.write(value);
  }

  /// clear data on your container
  Future<void> erase() async {
    _concrete.clear();
    return _tryFlush();
  }

  Future<void> save() async {
    return _tryFlush();
  }

  Future<void> _tryFlush() async {
    return microtask.exec(_addToQueue);
  }

  Future _addToQueue() {
    return queue.add(_flush);
  }

  Future<void> _flush() async {
    try {
      await _concrete.flush();
    } catch (e) {
      rethrow;
    }
    return;
  }

  late StorageImpl _concrete;

  ExecQueue queue = ExecQueue();

  /// Start the storage drive. Important: use await before calling this api, or side effects will happen.
  late Future<Riverpod2PersistStorage> initStorage;

  String? _initialData;
}

class Microtask {
  int _version = 0;
  int _microtask = 0;

  void exec(Function callback) {
    if (_microtask == _version) {
      _microtask++;
      scheduleMicrotask(() {
        _version++;
        _microtask = _version;
        callback();
      });
    }
  }
}
