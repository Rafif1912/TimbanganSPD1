
// ─────────────────────────────────────────────
// WeightRecord — model tampilan 
// ─────────────────────────────────────────────
class WeightRecord {
  final int id;
  final DateTime dbTime;
  final String? line;
  final String? shift;
  final String source; // 'Manual' atau 'Auto'
  final double recordHistoryAll;
  final double realWeightA;
  final double realWeightB;
  final double resetHistory;
  final double recordWeightA;
  final double recordWeightB;
  final int triggerA;
  final int triggerB;

  const WeightRecord({
    required this.id,
    required this.dbTime,
    this.line,
    this.shift,
    this.source = 'Manual',
    required this.recordHistoryAll,
    required this.realWeightA,
    required this.realWeightB,
    this.resetHistory = 0,
    this.recordWeightA = 0,
    this.recordWeightB = 0,
    this.triggerA = 0,
    this.triggerB = 0,
  });

  double get totalRealWeight => realWeightA + realWeightB;
  bool get isActive => triggerA == 1 || triggerB == 1;

  String get shiftLabel {
    if (shift == null || shift == '0' || shift!.isEmpty) return '-';
    return shift!;
  }

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    // ── Helpers ──────────────────────────────────────────────────────────
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is bool) return v ? 1 : 0;
      final s = v.toString().trim().toLowerCase();
      if (s == '0' || s.isEmpty || s == 'false' || s == 'null') return 0;
      return 1;
    }

    // ── Auto-detect Source ────────────────────────────────────────────────
    String _detectSource(Map<String, dynamic> json) {
      final rawSource = json['source'] as String? ?? json['Source'] as String?;
      if (rawSource != null && rawSource.isNotEmpty) {
        return rawSource;
      }
      final keys = json.keys.map((k) => k.toLowerCase()).toList();
      final hasAutoKey = keys.any((k) => k.endsWith('_auto'));
      if (hasAutoKey) return 'Auto';
      final hasManualKey = keys.any(
        (k) => k.contains('triger_manual') || k.contains('triger'),
      );
      if (hasManualKey) return 'Manual';
      return 'Manual';
    }

    final source = _detectSource(json);

    // ── Trigger ───────────────────────────────────────────────────────────
    final rawTriggerA = json['trigger_A'] ??
        json['Trigger_A'] ??
        json['triggerA'] ??
        json['TriggerA'] ??
        json['Triger_Manual_1B'] ??
        json['Triger_Manual_2B'] ??
        json['Triger_Manual_4B'] ??
        json['Triger_Manual_L5'] ??
        json['Triger_Manual_L6'] ??
        json['Triger_Manual_7B'] ??
        json['Trigger_A1_Auto'] ??
        json['Trigger_A2_Auto'] ??
        json['Trigger_A4_Auto'] ??
        json['Trigger_A5_Auto'] ??
        json['Trigger_A6_Auto'] ??
        json['Trigger_A7_Auto'] ??
        0;

    final rawTriggerB = json['trigger_B'] ??
        json['Trigger_B'] ??
        json['triggerB'] ??
        json['TriggerB'] ??
        json['Trigger_B1_Auto'] ??
        json['Trigger_B2_Auto'] ??
        json['Trigger_B4_Auto'] ??
        json['Trigger_B5_Auto'] ??
        json['Trigger_B6_Auto'] ??
        json['Trigger_B7_Auto'] ??
        0;

    // ── Record History ALL ─────────────────────────────────────────────────
    final recAll = toDouble(
      json['record_History_ALL'] ??
          json['Record_History_ALL'] ??
          json['recordHistoryAll'] ??
          json['Record_History_ALL_1B'] ??
          json['Record_History_ALL_2B'] ??
          json['Record_History_ALL_4B'] ??
          json['Record_History_ALL_5A'] ??
          json['Record_History_ALL_L6'] ??
          json['Record_History_ALL_7B'] ??
          json['Record_History_ALL_L1_Auto'] ??
          json['Record_History_ALL_L2_Auto'] ??
          json['Record_History_ALL_L4_Auto'] ??
          json['Record_History_ALL5_Auto'] ??
          json['Record_History_ALL_L6_Auto'] ??
          json['Record_History_ALL_L7_Auto'] ??
          0,
    );

    // ── Record Weight A ──────────────────────────────────────────────────
    final recA = toDouble(
      json['record_Weight_A'] ??
          json['Record_Weight_A'] ??
          json['recordWeightA'] ??
          json['Record_History_1A'] ??
          json['Record_History_2A'] ??
          json['Record_History_4A'] ??
          json['Record_History_5A'] ??
          json['Record_History_6A'] ??
          json['Record_History_7A'] ??
          json['Record_Weight_1A_Auto'] ??
          json['Record_Weight_2A_Auto'] ??
          json['Record_Weight_4A_Auto'] ??
          json['Record_History_5A_Auto'] ??
          json['Record_Weight_6A_Auto'] ??
          json['Record_Weight_7A_Auto'] ??
          0,
    );

    // ── Record Weight B ──────────────────────────────────────────────────
    final recB = toDouble(
      json['record_Weight_B'] ??
          json['Record_Weight_B'] ??
          json['recordWeightB'] ??
          json['Record_History_1B'] ??
          json['Record_History_2B'] ??
          json['Record_History_4B'] ??
          json['Record_History_5B'] ??
          json['Record_History_6B'] ??
          json['Record_History_7B'] ??
          json['Record_Weight_1B_Auto'] ??
          json['Record_Weight_2B_Auto'] ??
          json['Record_Weight_4B_Auto'] ??
          json['Record_History_5B_Auto'] ??
          json['Record_Weight_6B_Auto'] ??
          json['Record_Weight_7B_Auto'] ??
          0,
    );

    // ── Real Weight A ──────────────────────────────────────────────────────
    final realA = toDouble(
      json['real_Weight_A'] ??
          json['Real_Weight_A'] ??
          json['realWeightA'] ??
          json['Real_Weight_1A'] ??
          json['Real_Weight_2A'] ??
          json['Real_Weight_4A'] ??
          json['Real_Weight_5A'] ??
          json['Real_Weight_6A'] ??
          json['Real_Weight_7A'] ??
          json['Real_Weight_1A_Auto'] ??
          json['Real_Weight_2A_Auto'] ??
          json['Real_Weight_4A_Auto'] ??
          json['Real_Weight_5A_Auto'] ??
          json['Real_Weight_6A_Auto'] ??
          json['Real_Weight_7A_Auto'] ??
          0,
    );

    // ── Real Weight B ──────────────────────────────────────────────────────
    final realB = toDouble(
      json['real_Weight_B'] ??
          json['Real_Weight_B'] ??
          json['realWeightB'] ??
          json['Real_Weight_1B'] ??
          json['Real_Weight_2B'] ??
          json['Real_Weight_4B'] ??
          json['Real_Weight_5B'] ??
          json['Real_Weight_6B'] ??
          json['Real_Weight_7B'] ??
          json['Real_Weight_1B_Auto'] ??
          json['Real_Weight_2B_Auto'] ??
          json['Real_Weight_4B_Auto'] ??
          json['Real_Weight_5B_Auto'] ??
          json['Real_Weight_6B_Auto'] ??
          json['Real_Weight_7B_Auto'] ??
          0,
    );

    // ── Reset History ──────────────────────────────────────────────────────
    final reset = toDouble(
      json['reset_History'] ??
          json['Reset_History'] ??
          json['resetHistory'] ??
          json['Reset_History_L1_Auto'] ??
          json['Reset_History_L2_Auto'] ??
          json['Reset_History_L4_Auto'] ??
          json['Reset_History5_Auto'] ??
          json['Reset_History_L6_Auto'] ??
          json['Reset_History_L7_Auto'] ??
          0,
    );

    // ── Shift ──────────────────────────────────────────────────────────────
    final shift = (json['shift'] ??
            json['Shift'] ??
            json['Shift_1B'] ??
            json['Shift_2B'] ??
            json['Shift_4B'] ??
            json['Shift_L5'] ??
            json['Shift_L6'] ??
            json['Shift_7B'] ??
            json['Shift_L1_Auto'] ??
            json['Shift_L2_Auto'] ??
            json['Shift_L4_Auto'] ??
            json['Shift5_Auto'] ??
            json['Shift_L6_Auto'] ??
            json['Shift_L7_Auto'])
        ?.toString();

    return WeightRecord(
      id: (json['_id'] ?? 0) as int,
      dbTime:
          DateTime.tryParse(json['_dbTime'] as String? ?? '') ?? DateTime.now(),
      line: (json['line'] ?? json['Line']) as String?,
      shift: shift,
      source: source,
      recordHistoryAll: recAll / 10,
      realWeightA: realA / 10,
      realWeightB: realB / 10,
      resetHistory: reset / 10,
      recordWeightA: recA / 10,
      recordWeightB: recB / 10,
      triggerA: toInt(rawTriggerA),
      triggerB: toInt(rawTriggerB),
    );
  }
}

// ─────────────────────────────────────────────
// HistoryFilter — parameter query ke backend
// ─────────────────────────────────────────────
class HistoryFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? line;
  final String? shift;
  final String? source; // ← BARU: 'Manual', 'Auto', atau null (Semua)

  const HistoryFilter({
    this.startDate,
    this.endDate,
    this.line,
    this.shift,
    this.source, // ← BARU
  });

  HistoryFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? line,
    String? shift,
    String? source,
    bool clearLine = false,
    bool clearShift = false,
    bool clearSource = false, // ← BARU
  }) =>
      HistoryFilter(
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        line: clearLine ? null : (line ?? this.line),
        shift: clearShift ? null : (shift ?? this.shift),
        source: clearSource ? null : (source ?? this.source), // ← BARU
      );
}