import 'dart:async';
import 'dart:convert';
import 'package:signalr_netcore/signalr_client.dart';
import '../storage/token_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SignalRService {
  HubConnection? _connection;
  String? _currentOrderId;
  bool _isConnected = false;

  // Callbacks
  Function(Map<String, dynamic>)? onShipperAssigned;
  Function(Map<String, dynamic>)? onShipperLocationUpdated;
  Function(Map<String, dynamic>)? onOrderStatusChanged;

  Future<void> connect(int orderId) async {
    if (_isConnected && _currentOrderId == orderId.toString()) {
      print('✅ SignalR already connected to order $orderId');
      return;
    }

    try {
      // Disconnect existing connection if any
      await disconnect();

      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No token available for SignalR connection');
      }

      // Build hub URL - adjust for platform
      String hubUrl;
      if (kIsWeb) {
        hubUrl = 'http://127.0.0.1:5000/hubs/location';
      } else {
        hubUrl = 'http://10.0.2.2:5000/hubs/location';
      }

      print('🔌 Connecting to SignalR: $hubUrl');

      final options = HttpConnectionOptions(
        accessTokenFactory: () => Future.value(token),
      );

      _connection = HubConnectionBuilder()
          .withUrl(hubUrl, options: options)
          .withAutomaticReconnect()
          .build();

      // Setup event handlers
      _setupEventHandlers();

      // Start connection
      await _connection!.start();
      _isConnected = true;
      _currentOrderId = orderId.toString();

      print('✅ SignalR connected successfully');

      // Join order tracking group
      await _connection!.invoke('JoinOrderTracking', args: [orderId]);
      print('✅ Joined order tracking group: $orderId');
    } catch (e) {
      print('❌ Error connecting SignalR: $e');
      _isConnected = false;
      rethrow;
    }
  }

  void _setupEventHandlers() {
    if (_connection == null) return;

    // ShipperAssigned event
    _connection!.on('ShipperAssigned', (arguments) {
      print('📨 Received ShipperAssigned event');
      try {
        final data = _parseEventData(arguments);
        onShipperAssigned?.call(data);
      } catch (e) {
        print('❌ Error parsing ShipperAssigned: $e');
      }
    });

    // ShipperLocationUpdated event
    _connection!.on('ShipperLocationUpdated', (arguments) {
      print('📨 Received ShipperLocationUpdated event');
      try {
        final data = _parseEventData(arguments);
        onShipperLocationUpdated?.call(data);
      } catch (e) {
        print('❌ Error parsing ShipperLocationUpdated: $e');
      }
    });

    // OrderStatusChanged event
    _connection!.on('OrderStatusChanged', (arguments) {
      print('📨 Received OrderStatusChanged event');
      try {
        final data = _parseEventData(arguments);
        onOrderStatusChanged?.call(data);
      } catch (e) {
        print('❌ Error parsing OrderStatusChanged: $e');
      }
    });

    // Connection closed - handle connection state changes
    // Note: onclose may not be available in all versions, handle via connection state
  }

  Map<String, dynamic> _parseEventData(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return {};
    }

    try {
      // SignalR sends data as JSON string or Map
      final firstArg = arguments[0];
      if (firstArg is String) {
        return jsonDecode(firstArg) as Map<String, dynamic>;
      } else if (firstArg is Map) {
        return Map<String, dynamic>.from(firstArg);
      } else {
        return {'data': firstArg};
      }
    } catch (e) {
      print('❌ Error parsing event data: $e');
      return {};
    }
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      try {
        await _connection!.stop();
        print('✅ SignalR disconnected');
      } catch (e) {
        print('❌ Error disconnecting SignalR: $e');
      }
      _connection = null;
    }
    _isConnected = false;
    _currentOrderId = null;
  }

  bool get isConnected => _isConnected && _connection != null;
}
