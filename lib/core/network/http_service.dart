import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../constants/mock_data.dart';
import '../../modules/inventory/data/models/inventory_item_model.dart';
import '../../modules/inventory/data/models/inventory_response_model.dart';

/// HTTP Service using the standard http package.
/// Handles remote catalog fetching and broker connectivity healthchecks.
class HttpService {
  final http.Client _client;

  HttpService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches remote warehouse catalog or mock inventory from a cloud endpoint.
  /// Strictly handles status codes, errors, and null deserialization.
  Future<InventoryResponseModel<List<InventoryItemModel>>> fetchRemoteCatalog() async {
    try {
      final uri = Uri.parse(AppConstants.mockCatalogUrl);
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          return http.Response('{"error": "Connection timeout"}', 408);
        },
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          final items = decoded
              .where((element) => element != null && element is Map<String, dynamic>)
              .map((item) => InventoryItemModel.fromJson(item as Map<String, dynamic>))
              .toList();

          return InventoryResponseModel<List<InventoryItemModel>>.success(
            data: items,
            message: 'Catalog fetched successfully from cloud endpoint',
          );
        }
      }

      // If GitHub Raw returns 404 (file not yet pushed to repository branch),
      // gracefully fall back to local seed data so the app remains 100% operational.
      if (response.statusCode == 404) {
        debugPrint('[HttpService] Remote URL returned 404 (file not on branch yet). Using fallback catalog.');
        return InventoryResponseModel<List<InventoryItemModel>>.success(
          data: MockWarehouseData.initialItems,
          message: 'Remote catalog returned 404; safely loaded default warehouse items',
        );
      }

      return InventoryResponseModel<List<InventoryItemModel>>.failure(
        errorMessage: 'Remote server returned status ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('[HttpService] Error fetching remote catalog: $e');
      return InventoryResponseModel<List<InventoryItemModel>>.failure(
        errorMessage: 'HTTP fetch failed: $e',
      );
    }
  }

  /// Checks internet accessibility by pinging a reliable public endpoint.
  Future<bool> checkInternetAccess() async {
    try {
      final uri = Uri.parse('https://dns.google/resolve?name=example.com');
      final response = await _client.get(uri).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
