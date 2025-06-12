import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class StorageImpl {
  StorageImpl(this.fileName, [this.path]);

  final String? path;
  final String fileName;

  String subject = '';

  RandomAccessFile? _randomAccessfile;

  void clear() async {
    subject = '';
  }

  Future<void> deleteBox() async {
    final box = await _fileDb();
    await Future.wait([box.delete()]);
  }

  Future<void> flush() async {
    final buffer = utf8.encode(subject);
    final length = buffer.length;
    RandomAccessFile file = await _getRandomFile();

    _randomAccessfile = await file.lock();
    _randomAccessfile = await _randomAccessfile!.setPosition(0);
    _randomAccessfile = await _randomAccessfile!.writeFrom(buffer);
    _randomAccessfile = await _randomAccessfile!.truncate(length);
    _randomAccessfile = await file.unlock();
  }

  Future<void> init([String? initialData]) async {
    subject = initialData ?? '';

    RandomAccessFile file = await _getRandomFile();
    return file.lengthSync() == 0 ? flush() : _readFile();
  }

  String read() {
    return subject;
  }

  void write(String value) {
    subject = value;
  }

  Future<void> _readFile() async {
    try {
      RandomAccessFile file = await _getRandomFile();
      file = await file.setPosition(0);
      final buffer = Uint8List(await file.length());
      await file.readInto(buffer);
      subject = utf8.decode(buffer);
    } catch (e) {
      // noop
    }
  }

  Future<RandomAccessFile> _getRandomFile() async {
    if (_randomAccessfile != null) return _randomAccessfile!;
    final fileDb = await _getFile();
    _randomAccessfile = await fileDb.open(mode: FileMode.append);

    return _randomAccessfile!;
  }

  Future<File> _getFile() async {
    final fileDb = await _fileDb();
    if (!fileDb.existsSync()) {
      fileDb.createSync(recursive: true);
    }
    return fileDb;
  }

  Future<File> _fileDb() async {
    final dir = await _getImplicitDir();
    final fullPath = await _getPath(path ?? dir.path);
    return File(fullPath);
  }

  Future<Directory> _getImplicitDir() async {
    try {
      return getApplicationDocumentsDirectory();
    } catch (err) {
      rethrow;
    }
  }

  Future<String> _getPath(String? path) async {
    final separator = '/';
    return '$path$separator$fileName.dd';
  }
}
