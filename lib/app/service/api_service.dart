import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:timbangan_spd/app/core/config/env.dart';
import 'package:timbangan_spd/app/models/weight_record_model.dart';

Dio _dio() => Dio(BaseOptions(
      baseUrl: Env.mainUrl,
      connectTimeout: const Duration(seconds: Env.connectTimeout),
      receiveTimeout: const Duration(seconds: Env.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

class ApiService {
  ApiService._();

  // ── AUTH ──────────────────────────────────────────────────────────────────
  static Future<String?> login(String username, String password) async {
    try {
      final response = await _dio().post(
        '/api/Auth/Login',
        data: {'username': username, 'password': password},
      );
      if (response.statusCode == 200) {
        return response.data['username'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('[API] login error: $e');
      return null;
    }
  }

  // ── HISTORY / WEIGHT RECORDS ──────────────────────────────────────────────
  /// GET /api/SPDScale/GetAllWeightHistory
  /// Backend sudah auto filter: hanya data yang Trigger_A=1 OR Trigger_B=1
  static Future<List<WeightRecord>> getWeightHistory(
      HistoryFilter filter) async {
    try {
      final Map<String, dynamic> params = {};

      if (filter.startDate != null) {
        params['startDate'] =
            DateFormat('yyyy-MM-dd').format(filter.startDate!);
      }
      if (filter.endDate != null) {
        params['endDate'] = DateFormat('yyyy-MM-dd').format(filter.endDate!);
      }
      if (filter.line != null) params['line'] = filter.line;
      if (filter.shift != null) params['shift'] = filter.shift;
      if (filter.source != null) params['source'] = filter.source; // ← PERBAIKAN: kirim source filter ke backend

      debugPrint('[API] GET /api/SPDScale/GetAllWeightHistory params=$params');

      final response = await _dio().get(
        '/api/SPDScale/GetAllWeightHistory',
        queryParameters: params.isEmpty ? null : params,
      );

      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        final status = body['status'] as Map<String, dynamic>?;

        if (status != null && status['code'] == 200) {
          final List<dynamic> raw = body['data'] as List<dynamic>;
          return raw
              .map((e) => WeightRecord.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[API] getWeightHistory error: $e');
      return [];
    }
  }

  // ── SCALE DEVICES ─────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>?> getScales() async {
    try {
      final response = await _dio().get('/api/SPD/GetScales');
      if (response.statusCode == 200 && response.data != null) {
        return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      debugPrint('[API] getScales error: $e');
      return null;
    }
  }
}