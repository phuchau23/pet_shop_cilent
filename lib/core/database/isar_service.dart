import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../features/cart/data/models/cart_item_model.dart';
import '../../features/cart/data/models/cart_model.dart';

class IsarService {
  static Isar? _isar;
  static Completer<Isar>? _initCompleter; // Để tránh mở nhiều lần cùng lúc

  static Future<Isar> get instance async {
    // Isar không hỗ trợ web, throw error với message rõ ràng
    if (kIsWeb) {
      throw UnsupportedError(
        'Isar không hỗ trợ web. Cart chỉ hoạt động trên mobile (Android/iOS).',
      );
    }

    // Nếu đã có instance, return ngay
    if (_isar != null) {
      return _isar!;
    }

    // Nếu đang trong quá trình khởi tạo, đợi completer
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    // Tạo completer mới và bắt đầu khởi tạo
    _initCompleter = Completer<Isar>();

    try {
      // Thử dùng path_provider trước
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open([
        CartModelSchema,
        CartItemModelSchema,
      ], directory: dir.path);
      print('✅ Isar initialized with path_provider: ${dir.path}');
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      
      // Kiểm tra nếu lỗi là "Collection id is invalid" - do schema đã thay đổi
      if (errorMsg.contains('collection id is invalid') || 
          errorMsg.contains('illegalarg')) {
        print('⚠️ Collection ID invalid - schema changed. Deleting old database...');
        try {
          // Xóa database cũ và tạo lại
          final dir = await getApplicationDocumentsDirectory();
          final isarPath = path.join(dir.path, 'default.isar');
          final isarLockPath = path.join(dir.path, 'default.isar.lock');
          if (await File(isarPath).exists()) {
            await File(isarPath).delete();
            print('✅ Deleted old database file');
          }
          if (await File(isarLockPath).exists()) {
            await File(isarLockPath).delete();
            print('✅ Deleted old lock file');
          }
          // Tạo lại database
          _isar = await Isar.open([
            CartModelSchema,
            CartItemModelSchema,
          ], directory: dir.path);
          print('✅ Isar initialized with fresh database: ${dir.path}');
        } catch (e6) {
          print('⚠️ Failed to recreate database, using fallback: $e6');
          // Fallback to temp directory
          final tempDir = Directory.systemTemp;
          final isarDir = path.join(tempDir.path, 'pet_shop_isar');
          if (await Directory(isarDir).exists()) {
            await Directory(isarDir).delete(recursive: true);
          }
          await Directory(isarDir).create(recursive: true);
          _isar = await Isar.open([
            CartModelSchema,
            CartItemModelSchema,
          ], directory: isarDir);
          print('✅ Isar initialized with fallback: $isarDir');
        }
      } 
      // Kiểm tra nếu lỗi là "already opened" - có thể do hot reload
      else if (errorMsg.contains('already been opened') || 
          errorMsg.contains('already opened') ||
          errorMsg.contains('instance has already been opened')) {
        print('⚠️ Isar already opened (possibly from hot reload)');
        print('⚠️ This usually happens after hot reload. Instance exists but _isar is null.');
        print('⚠️ Solution: Please restart the app (not hot reload) to fix this issue.');
        
        // Khi gặp lỗi "already opened", không thể mở lại
        // Cách tốt nhất là dùng fallback directory với name khác
        try {
          final tempDir = Directory.systemTemp;
          final isarDir = path.join(tempDir.path, 'pet_shop_isar_fallback');
          await Directory(isarDir).create(recursive: true);
          _isar = await Isar.open([
            CartModelSchema,
            CartItemModelSchema,
          ], directory: isarDir, name: 'pet_shop_fallback_${DateTime.now().millisecondsSinceEpoch}');
          print('✅ Isar initialized with fallback directory (due to already opened error): $isarDir');
        } catch (e4) {
          // Kiểm tra nếu lỗi là "Collection id is invalid" - do schema đã thay đổi
          final e4Msg = e4.toString().toLowerCase();
          if (e4Msg.contains('collection id is invalid') || 
              e4Msg.contains('illegalarg')) {
            print('⚠️ Collection ID invalid - schema changed. Deleting old database...');
            try {
              // Xóa database cũ và tạo lại
              final tempDir = Directory.systemTemp;
              final isarDir = path.join(tempDir.path, 'pet_shop_isar_fallback');
              if (await Directory(isarDir).exists()) {
                await Directory(isarDir).delete(recursive: true);
                print('✅ Deleted old database');
              }
              await Directory(isarDir).create(recursive: true);
              _isar = await Isar.open([
                CartModelSchema,
                CartItemModelSchema,
              ], directory: isarDir, name: 'pet_shop_fallback_${DateTime.now().millisecondsSinceEpoch}');
              print('✅ Isar initialized with fresh database: $isarDir');
            } catch (e5) {
              print('❌ Failed to recreate database: $e5');
              _initCompleter!.completeError(e5);
              _initCompleter = null;
              rethrow;
            }
          } else {
            print('❌ Isar initialization failed even with fallback: $e4');
            _initCompleter!.completeError(e4);
            _initCompleter = null;
            rethrow;
          }
        }
      } else {
        print('⚠️ path_provider failed, using fallback: $e');
        // Fallback: dùng temporary directory hoặc current directory
        try {
          final tempDir = Directory.systemTemp;
          final isarDir = path.join(tempDir.path, 'pet_shop_isar');
          await Directory(isarDir).create(recursive: true);
          _isar = await Isar.open([
            CartModelSchema,
            CartItemModelSchema,
          ], directory: isarDir, name: 'pet_shop_fallback');
          print('✅ Isar initialized with fallback: $isarDir');
        } catch (e2) {
          print('❌ Isar initialization failed: $e2');
          _initCompleter!.completeError(e2);
          _initCompleter = null;
          rethrow;
        }
      }
    }

    // Complete completer và return
    if (_isar != null) {
      _initCompleter!.complete(_isar!);
      _initCompleter = null;
      return _isar!;
    } else {
      final error = Exception('Failed to initialize Isar');
      _initCompleter!.completeError(error);
      _initCompleter = null;
      throw error;
    }
  }

  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
    _initCompleter = null;
  }

  // Reset database - xóa tất cả data và tạo lại
  static Future<void> resetDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Isar không hỗ trợ web');
    }

    try {
      // Đóng instance hiện tại nếu có
      await close();

      // Xóa database files
      final dir = await getApplicationDocumentsDirectory();
      final isarPath = path.join(dir.path, 'default.isar');
      final isarLockPath = path.join(dir.path, 'default.isar.lock');
      
      if (await File(isarPath).exists()) {
        await File(isarPath).delete();
        print('✅ Deleted database file');
      }
      if (await File(isarLockPath).exists()) {
        await File(isarLockPath).delete();
        print('✅ Deleted lock file');
      }

      // Xóa fallback directories
      final tempDir = Directory.systemTemp;
      final isarDir = path.join(tempDir.path, 'pet_shop_isar');
      final isarFallbackDir = path.join(tempDir.path, 'pet_shop_isar_fallback');
      
      if (await Directory(isarDir).exists()) {
        await Directory(isarDir).delete(recursive: true);
        print('✅ Deleted fallback directory');
      }
      if (await Directory(isarFallbackDir).exists()) {
        await Directory(isarFallbackDir).delete(recursive: true);
        print('✅ Deleted fallback directory 2');
      }

      print('✅ Database reset completed');
    } catch (e) {
      print('❌ Error resetting database: $e');
      rethrow;
    }
  }
}
