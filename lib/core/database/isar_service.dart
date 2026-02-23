import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../features/cart/data/models/cart_item_model.dart';
import '../../features/cart/data/models/cart_model.dart';

class IsarService {
  static Isar? _isar;

  static Future<Isar> get instance async {
    if (_isar != null) {
      return _isar!;
    }

    try {
      // Thử dùng path_provider trước
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open([
        CartModelSchema,
        CartItemModelSchema,
      ], directory: dir.path);
      print('✅ Isar initialized with path_provider: ${dir.path}');
    } catch (e) {
      print('⚠️ path_provider failed, using fallback: $e');
      // Fallback: dùng temporary directory hoặc current directory
      try {
        final tempDir = Directory.systemTemp;
        final isarDir = path.join(tempDir.path, 'pet_shop_isar');
        await Directory(isarDir).create(recursive: true);
        _isar = await Isar.open([
          CartModelSchema,
          CartItemModelSchema,
        ], directory: isarDir);
        print('✅ Isar initialized with fallback: $isarDir');
      } catch (e2) {
        print('❌ Isar initialization failed: $e2');
        rethrow;
      }
    }

    return _isar!;
  }

  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
