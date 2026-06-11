// lib/app/service/excel_export_service.dart
//
// Dependencies:
//   excel: ^4.0.6
//   path_provider: ^2.1.4
//   share_plus: ^10.1.4

import 'dart:io';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timbangan_spd/app/models/weight_record_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL: ringkasan per tanggal + shift
// ─────────────────────────────────────────────────────────────────────────────
class _DailyShiftSummary {
  final DateTime date;
  final String shift;
  final WeightRecord? lastRecord;
  final double recTotalLast;
  final double realASum;
  final double realBSum;
  final double realTotalSum;

  const _DailyShiftSummary({
    required this.date,
    required this.shift,
    required this.lastRecord,
    required this.recTotalLast,
    required this.realASum,
    required this.realBSum,
    required this.realTotalSum,
  });
}

class ExcelExportService {
  // ── Formatters ─────────────────────────────────────────────────────────────
  static final _numFmt   = NumberFormat('#,##0.##', 'id_ID');
  static final _dateFmt  = DateFormat('dd-MM-yyyy');
  static final _timeFmt  = DateFormat('HH:mm:ss');
  static final _dfmt     = DateFormat('dd MMM yyyy', 'id_ID');
  static final _fullDfmt = DateFormat('yyyy-MM-dd HH:mm:ss');

  // ── Warna utama ────────────────────────────────────────────────────────────
  static const _cHeaderBg  = '1E3A5F';
  static const _cHeaderFg  = 'FFFFFF';
  static const _cColHdrBg  = 'E8ECFF';
  static const _cColHdrFg  = '1E3A5F';
  static const _cRealBg    = 'E0F7FA';
  static const _cRealFg    = '0E7490';
  static const _cRowEven   = 'F0F4FF';
  static const _cRowOdd    = 'FFFFFF';
  static const _cText      = '111827';
  static const _cNoFg      = '3730A3';
  static const _cSrcAuto   = '0369A1';
  static const _cSrcManual = '6D28D9';
  static const _cLineFg    = '1E3A5F';
  static const _cBorder    = 'B0B7C3';
  static const _cFooterBg  = 'F8FAFF';

  // ── Warna per shift ────────────────────────────────────────────────────────
  static const _cShift1Bg  = 'FFFBEB';
  static const _cShift1Acc = 'F59E0B';
  static const _cShift1Fg  = '92400E';
  static const _cShift2Bg  = 'EFF6FF';
  static const _cShift2Acc = '3B82F6';
  static const _cShift2Fg  = '1E40AF';
  static const _cShift3Bg  = 'F0FDF4';
  static const _cShift3Acc = '22C55E';
  static const _cShift3Fg  = '14532D';

  // ── Warna summary section ──────────────────────────────────────────────────
  static const _cDateHdrBg = '1E3A5F';
  static const _cDateHdrFg = 'FFFFFF';
  static const _cSubTotBg  = 'FEF9C3';
  static const _cSubTotFg  = '78350F';
  static const _cGrandBg   = 'DBEAFE';
  static const _cGrandFg   = '1E3A5F';

  static const _allLines  = ['L1', 'L2', 'L4', 'L5', 'L6', 'L7'];
  static const _allShifts = ['1', '2', '3'];

  // ── Style cache ────────────────────────────────────────────────────────────
  static _RowStyleCache? _evenCache;
  static _RowStyleCache? _oddCache;

  static _RowStyleCache _getRowStyle(bool isEven) {
    if (isEven) return _evenCache ??= _RowStyleCache(_cRowEven);
    return _oddCache ??= _RowStyleCache(_cRowOdd);
  }

  static void _resetCache() {
    _evenCache = null;
    _oddCache  = null;
  }

  // ── Helper numerik ─────────────────────────────────────────────────────────
  static double _round(double v) => double.parse(v.toStringAsFixed(2));
  static String _fmtNum(double v) => _numFmt.format(_round(v));

  static String _fmtShift(dynamic shift) {
    if (shift == null) return '-';
    if (shift is double && shift == shift.truncateToDouble()) {
      return shift.toInt().toString();
    }
    return shift.toString();
  }

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER TANGGAL (biasa)
  // ═══════════════════════════════════════════════════════════════════════════
  static bool _isDateInRange(
      DateTime recordDate, DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) return true;
    final start = startDate != null
        ? DateTime(startDate.year, startDate.month, startDate.day)
        : null;
    final end = endDate != null
        ? DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999)
        : null;
    if (start != null && recordDate.isBefore(start)) return false;
    if (end != null && recordDate.isAfter(end)) return false;
    return true;
  }

  static List<WeightRecord> _filterByDateRange(
    List<WeightRecord> records,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null && endDate == null) return records;
    print(
        '📅 Filtering from ${_fullDfmt.format(startDate ?? DateTime(2000))} '
        'to ${_fullDfmt.format(endDate ?? DateTime(3000))}');
    final filtered = records
        .where((r) => _isDateInRange(r.dbTime, startDate, endDate))
        .toList();
    print('📊 Total: ${records.length} → Filtered: ${filtered.length}');
    return filtered;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER KHUSUS SHIFT 3 (22:00 startDate s/d 06:00 endDate)
  //
  // Shift 3 = 22:00 – 06:00 (lintas tengah malam)
  // Range yang valid:
  //   >= startDate 22:00:00  AND  <= endDate 06:00:00
  // ═══════════════════════════════════════════════════════════════════════════
  static List<WeightRecord> _filterShift3Range(
    List<WeightRecord> records,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Batas bawah: startDate jam 22:00:00
    final lowerBound = DateTime(
      startDate.year, startDate.month, startDate.day, 22, 0, 0,
    );
    // Batas atas: endDate jam 06:00:00
    final upperBound = DateTime(
      endDate.year, endDate.month, endDate.day, 7, 0, 0,
    );

    print('🌙 Shift 3 filter: '
        '${_fullDfmt.format(lowerBound)} s/d ${_fullDfmt.format(upperBound)}');

    final filtered = records.where((r) {
      final shiftStr = _fmtShift(r.shift);
      if (shiftStr != '3') return false;
      return !r.dbTime.isBefore(lowerBound) &&
             !r.dbTime.isAfter(upperBound);
    }).toList();

    print('🌙 Shift 3 records: ${filtered.length}');
    return filtered;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGIKA INTI: hitung ringkasan per TANGGAL + SHIFT
  // ═══════════════════════════════════════════════════════════════════════════
  static List<_DailyShiftSummary> _computeDailyShiftSummaries(
      List<WeightRecord> records) {
    final uniqueDates = records
        .map((r) => _dateOnly(r.dbTime))
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    final result = <_DailyShiftSummary>[];

    for (final date in uniqueDates) {
      final dayRecs = records
          .where((r) => _dateOnly(r.dbTime) == date)
          .toList();

      for (final shift in _allShifts) {
        final shiftRecs = dayRecs
            .where((r) => _fmtShift(r.shift) == shift)
            .toList();

        if (shiftRecs.isEmpty) {
          result.add(_DailyShiftSummary(
            date:         date,
            shift:        shift,
            lastRecord:   null,
            recTotalLast: 0,
            realASum:     0,
            realBSum:     0,
            realTotalSum: 0,
          ));
          continue;
        }

        shiftRecs.sort((a, b) => b.dbTime.compareTo(a.dbTime));
        final last = shiftRecs.first;

        final recTotal = _round(last.recordHistoryAll);
        final realASum = _round(shiftRecs.fold(0.0, (s, r) => s + r.realWeightA));
        final realBSum = _round(shiftRecs.fold(0.0, (s, r) => s + r.realWeightB));

        print('📊 ${_dateFmt.format(date)} Shift $shift: '
            '${shiftRecs.length} records, '
            'LastRec Total: ${_fmtNum(recTotal)}, '
            'Real Total: ${_fmtNum(realASum + realBSum)}');

        result.add(_DailyShiftSummary(
          date:         date,
          shift:        shift,
          lastRecord:   last,
          recTotalLast: recTotal,
          realASum:     realASum,
          realBSum:     realBSum,
          realTotalSum: _round(realASum + realBSum),
        ));
      }
    }

    return result;
  }

  static String _recordId(WeightRecord r) =>
      '${r.dbTime.millisecondsSinceEpoch}_${r.line}_${r.shift}';

  static Set<String> _lastDailyShiftRecordIds(List<WeightRecord> records) {
    final ids = <String>{};
    final uniqueDates = records
        .map((r) => _dateOnly(r.dbTime))
        .toSet()
        .toList();

    for (final date in uniqueDates) {
      final dayRecs = records
          .where((r) => _dateOnly(r.dbTime) == date)
          .toList();
      for (final shift in _allShifts) {
        final shiftRecs = dayRecs
            .where((r) => _fmtShift(r.shift) == shift)
            .toList();
        if (shiftRecs.isEmpty) continue;
        shiftRecs.sort((a, b) => b.dbTime.compareTo(a.dbTime));
        ids.add(_recordId(shiftRecs.first));
      }
    }
    return ids;
  }

  // ── Warna shift ────────────────────────────────────────────────────────────
  static String _shiftBg(String shift) {
    switch (shift) {
      case '1': return _cShift1Bg;
      case '2': return _cShift2Bg;
      case '3': return _cShift3Bg;
      default:  return _cRowEven;
    }
  }

  static String _shiftFg(String shift) {
    switch (shift) {
      case '1': return _cShift1Fg;
      case '2': return _cShift2Fg;
      case '3': return _cShift3Fg;
      default:  return _cText;
    }
  }

  static String _shiftAcc(String shift) {
    switch (shift) {
      case '1': return _cShift1Acc;
      case '2': return _cShift2Acc;
      case '3': return _cShift3Acc;
      default:  return _cBorder;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  static Border get _bThin => Border(
        borderStyle:    BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString(_cBorder),
      );

  static Border get _bMedium => Border(
        borderStyle:    BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('6B7280'),
      );

  static Border get _bData => Border(
        borderStyle:    BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('9CA3AF'),
      );

  static Border _bColor(String hexColor, {bool medium = false}) => Border(
        borderStyle:    medium ? BorderStyle.Medium : BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString(hexColor),
      );

  static Border _bThick(String hexColor) => Border(
        borderStyle:    BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString(hexColor),
      );

  // ── CellStyle factory ──────────────────────────────────────────────────────
  static CellStyle _make({
    required String bg,
    required String fg,
    bool bold               = false,
    bool italic             = false,
    HorizontalAlign halign  = HorizontalAlign.Center,
    VerticalAlign   valign  = VerticalAlign.Center,
    TextWrapping?   wrap,
    int  fontSize           = 9,
    bool useMedium          = false,
    bool useData            = false,
    String? borderColor,
    String? bottomAccentColor,
  }) {
    final Border sideB;
    if (borderColor != null) {
      sideB = _bColor(borderColor, medium: useMedium);
    } else if (useMedium) {
      sideB = _bMedium;
    } else if (useData) {
      sideB = _bData;
    } else {
      sideB = _bThin;
    }

    final Border botB = bottomAccentColor != null
        ? _bThick(bottomAccentColor)
        : sideB;

    return CellStyle(
      backgroundColorHex: ExcelColor.fromHexString(bg),
      fontColorHex:       ExcelColor.fromHexString('#000000'),
      bold:               bold,
      italic:             italic,
      horizontalAlign:    halign,
      verticalAlign:      valign,
      textWrapping:       wrap,
      fontSize:           fontSize,
      fontFamily:         getFontFamily(FontFamily.Arial),
      leftBorder:         sideB,
      rightBorder:        sideB,
      topBorder:          sideB,
      bottomBorder:       botB,
    );
  }

  static void _fillMergedBorder(
      Sheet sheet, int row, int colStart, int colEnd, String bg,
      {bool useMedium = false}) {
    final dummy = _make(bg: bg, fg: _cText, useMedium: useMedium);
    for (var c = colStart + 1; c <= colEnd; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row))
          .cellStyle = dummy;
    }
  }

  static int _writeBlankRow(Sheet sheet, int row,
      {int cols = 9, String bg = _cRowOdd}) {
    sheet.setRowHeight(row, 8);
    for (var c = 0; c < cols; c++) {
      _set(sheet, row, c, '', _make(bg: bg, fg: _cText));
    }
    return row + 1;
  }

  static void _set(Sheet sheet, int row, int col, dynamic value, CellStyle style) {
    final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (value is int) {
      cell.value = IntCellValue(value);
    } else {
      cell.value = TextCellValue(value.toString());
    }
    cell.cellStyle = style;
  }

  static void _setNum(Sheet sheet, int row, int col, double value, CellStyle style) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
      ..value = TextCellValue(_fmtNum(value))
      ..cellStyle = style;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COLUMN WIDTHS
  // ═══════════════════════════════════════════════════════════════════════════
  static void _applyColWidths(Sheet sheet) {
    const widths = [
      10.0,  // 0  NO
      16.0,  // 1  TANGGAL
      11.0,  // 2  WAKTU
      13.0,  // 3  LINE
      13.0,  // 4  SHIFT
      13.0,  // 5  SUMBER
      18.0,  // 6  REAL A
      18.0,  // 7  REAL B
      20.0,  // 8  REAL TOTAL
    ];
    for (var i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }

  // ── Title ──────────────────────────────────────────────────────────────────
  static int _writeTitle(Sheet sheet, int r,
      {required String title, required String filterStr}) {
    sheet.setRowHeight(r, 30);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: r),
    );
    _set(sheet, r, 0, title,
        _make(
          bg: _cHeaderBg, fg: _cHeaderFg,
          bold: true, fontSize: 14,
          halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
          wrap: TextWrapping.WrapText, useMedium: true,
        ));
    _fillMergedBorder(sheet, r, 0, 8, _cHeaderBg, useMedium: true);

    sheet.setRowHeight(r + 1, 20);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r + 1),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: r + 1),
    );
    _set(sheet, r + 1, 0, filterStr,
        _make(
          bg: '2D4E77', fg: _cHeaderFg,
          fontSize: 9,
          halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
          wrap: TextWrapping.WrapText,
        ));
    _fillMergedBorder(sheet, r + 1, 0, 8, '2D4E77');

    return r + 2;
  }

  // ── Column Headers ─────────────────────────────────────────────────────────
  static int _writeColHeaders(Sheet sheet, int row) {
    sheet.setRowHeight(row, 30);
    sheet.setRowHeight(row + 1, 30);

    final hBase = _make(bg: _cColHdrBg, fg: _cColHdrFg, bold: true, fontSize: 9,
        halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
        wrap: TextWrapping.WrapText, useMedium: true);
    final hReal = _make(bg: _cRealBg, fg: _cRealFg, bold: true, fontSize: 9,
        halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
        wrap: TextWrapping.WrapText, useMedium: true);

    for (final col in [0, 1, 2, 3, 4, 5]) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1),
      );
    }
    _set(sheet, row, 0, 'NO',      hBase);
    _set(sheet, row, 1, 'TANGGAL', hBase);
    _set(sheet, row, 2, 'WAKTU',   hBase);
    _set(sheet, row, 3, 'LINE',    hBase);
    _set(sheet, row, 4, 'SHIFT',   hBase);
    _set(sheet, row, 5, 'SUMBER',  hBase);

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row),
    );
    _set(sheet, row, 6, 'REAL WEIGHT', hReal);
    _fillMergedBorder(sheet, row, 6, 8, _cRealBg, useMedium: true);

    _set(sheet, row + 1, 6, 'REAL A\n(kg)',     hReal);
    _set(sheet, row + 1, 7, 'REAL B\n(kg)',     hReal);
    _set(sheet, row + 1, 8, 'REAL TOTAL\n(kg)', hReal);

    return row + 2;
  }

  // ── Data Rows ASYNC ────────────────────────────────────────────────────────
  static Future<int> _writeDataRowsAsync(
      Sheet sheet, List<WeightRecord> records, int startRow,
      Set<String> lastShiftIds,
      {int noOffset = 0}) async {
    for (var i = 0; i < records.length; i++) {
      if (i % 30 == 0) await Future.delayed(Duration.zero);
      _writeDataRow(sheet, records[i], startRow + i, i, lastShiftIds,
          noOffset: noOffset);
    }
    return startRow + records.length;
  }

  // ── Data Rows SYNC ─────────────────────────────────────────────────────────
  static int _writeDataRowsSync(
      Sheet sheet, List<WeightRecord> records, int startRow,
      Set<String> lastShiftIds,
      {int noOffset = 0}) {
    for (var i = 0; i < records.length; i++) {
      _writeDataRow(sheet, records[i], startRow + i, i, lastShiftIds,
          noOffset: noOffset);
    }
    return startRow + records.length;
  }

  // ── Shared single-row writer ───────────────────────────────────────────────
  static void _writeDataRow(
      Sheet sheet, WeightRecord r, int rowIdx, int i,
      Set<String> lastShiftIds,
      {int noOffset = 0}) {
    final isLast   = lastShiftIds.contains(_recordId(r));
    final shiftStr = _fmtShift(r.shift);

    String useBg;
    String useFg;
    String? useBottomAcc;
    bool   useBold = false;
    final  srcFg   = r.source == 'Auto' ? _cSrcAuto : _cSrcManual;

    if (isLast) {
      useBg        = _shiftBg(shiftStr);
      useFg        = _shiftFg(shiftStr);
      useBottomAcc = _shiftAcc(shiftStr);
      useBold      = true;
    } else {
      useBg = i.isEven ? _cRowEven : _cRowOdd;
      useFg = _cText;
    }

    sheet.setRowHeight(rowIdx, isLast ? 22 : 18);

    final sCenter = _make(bg: useBg, fg: useFg, useData: true, bold: useBold,  bottomAccentColor: useBottomAcc);
    final sBold   = _make(bg: useBg, fg: useFg, useData: true, bold: true,     bottomAccentColor: useBottomAcc);
    final sNo     = _make(bg: useBg, fg: isLast ? useFg : _cNoFg,   useData: true, bold: true, bottomAccentColor: useBottomAcc);
    final sLine   = _make(bg: useBg, fg: isLast ? useFg : _cLineFg, useData: true, bold: true, bottomAccentColor: useBottomAcc);
    final sSrc    = _make(bg: useBg, fg: isLast ? useFg : srcFg,    useData: true, bold: true, bottomAccentColor: useBottomAcc);

    _set   (sheet, rowIdx, 0, noOffset + i + 1,          sNo);
    _set   (sheet, rowIdx, 1, _dateFmt.format(r.dbTime), sCenter);
    _set   (sheet, rowIdx, 2, _timeFmt.format(r.dbTime), sCenter);
    _set   (sheet, rowIdx, 3, r.line,                    sLine);
    _set   (sheet, rowIdx, 4, shiftStr,                  sCenter);
    _set   (sheet, rowIdx, 5, r.source,                  sSrc);
    _setNum(sheet, rowIdx, 6, r.realWeightA,             sBold);
    _setNum(sheet, rowIdx, 7, r.realWeightB,             sBold);
    _setNum(sheet, rowIdx, 8, r.totalRealWeight,         sBold);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUMMARY SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  static int _writeShiftSummarySection(
      Sheet sheet, List<_DailyShiftSummary> summaries, int row) {

    sheet.setRowHeight(row, 22);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row),
    );
    _set(sheet, row, 0,
        '★ RINGKASAN PER TANGGAL & SHIFT',
        _make(
          bg: _cDateHdrBg, fg: _cDateHdrFg,
          bold: true, fontSize: 11,
          halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
          useMedium: true,
        ));
    _fillMergedBorder(sheet, row, 0, 8, _cDateHdrBg, useMedium: true);
    row++;

    sheet.setRowHeight(row, 22);
    final hStyle = _make(bg: _cColHdrBg, fg: _cColHdrFg, bold: true, fontSize: 9,
        halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
        wrap: TextWrapping.WrapText, useMedium: true);

    _set(sheet, row, 0, 'TANGGAL', hStyle);
    _set(sheet, row, 1, 'SHIFT / KET.', hStyle);

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
    );
    _set(sheet, row, 2, 'SUM REAL A\n(kg)',
        _make(bg: _cRealBg, fg: _cRealFg, bold: true, fontSize: 9,
            halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
            wrap: TextWrapping.WrapText, useMedium: true));
    _fillMergedBorder(sheet, row, 2, 3, _cRealBg, useMedium: true);

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
    );
    _set(sheet, row, 4, 'SUM REAL B\n(kg)',
        _make(bg: _cRealBg, fg: _cRealFg, bold: true, fontSize: 9,
            halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
            wrap: TextWrapping.WrapText, useMedium: true));
    _fillMergedBorder(sheet, row, 4, 5, _cRealBg, useMedium: true);

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row),
    );
    _set(sheet, row, 6, 'TOTAL REAL\n(Real A + Real B) (kg)',
        _make(bg: _cRealBg, fg: _cRealFg, bold: true, fontSize: 9,
            halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
            wrap: TextWrapping.WrapText, useMedium: true));
    _fillMergedBorder(sheet, row, 6, 8, _cRealBg, useMedium: true);
    row++;

    final uniqueDates = summaries
        .map((s) => s.date)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    double grandRealA = 0;
    double grandRealB = 0;

    for (final date in uniqueDates) {
      final daySummaries = summaries.where((s) => s.date == date).toList();

      sheet.setRowHeight(row, 20);
      final dateLabel = _dfmt.format(date);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row),
      );
      _set(sheet, row, 0, '📅  $dateLabel',
          _make(
            bg: '2D4E77', fg: 'FFFFFF',
            bold: true, fontSize: 10,
            halign: HorizontalAlign.Left, valign: VerticalAlign.Center,
            useMedium: true,
          ));
      _fillMergedBorder(sheet, row, 0, 8, '2D4E77', useMedium: true);
      row++;

      double dayRealA = 0;
      double dayRealB = 0;

      for (final sd in daySummaries) {
        sheet.setRowHeight(row, 22);
        final bg  = _shiftBg(sd.shift);
        final fg  = _shiftFg(sd.shift);
        final acc = _shiftAcc(sd.shift);

        final sShift = _make(bg: bg, fg: fg, bold: true, fontSize: 10,
            halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
            borderColor: acc, useMedium: true);
        final sKet   = _make(bg: bg, fg: fg, fontSize: 9,
            halign: HorizontalAlign.Left, valign: VerticalAlign.Center,
            borderColor: acc, useMedium: true);
        final sVal   = _make(bg: bg, fg: fg, bold: true, fontSize: 10,
            halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
            borderColor: acc, useMedium: true);
        final sNA    = _make(bg: bg, fg: fg, fontSize: 9,
            halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
            borderColor: acc, useMedium: true);

        _set(sheet, row, 0, 'Shift ${sd.shift}', sShift);

        if (sd.lastRecord != null) {
          final ketStr = 'Terakhir: ${_timeFmt.format(sd.lastRecord!.dbTime)}';
          _set(sheet, row, 1, ketStr, sKet);

          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
            CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
          );
          _setNum(sheet, row, 2, sd.realASum, sVal);
          _fillMergedBorder(sheet, row, 2, 3, bg, useMedium: true);

          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
            CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
          );
          _setNum(sheet, row, 4, sd.realBSum, sVal);
          _fillMergedBorder(sheet, row, 4, 5, bg, useMedium: true);

          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
            CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row),
          );
          _setNum(sheet, row, 6, sd.realTotalSum,
              _make(bg: bg, fg: fg, bold: true, fontSize: 11,
                  halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
                  borderColor: acc, useMedium: true));
          _fillMergedBorder(sheet, row, 6, 8, bg, useMedium: true);

          dayRealA += sd.realASum;
          dayRealB += sd.realBSum;
        } else {
          _set(sheet, row, 1, 'Tidak ada data', sKet);

          for (final cols in [[2, 3], [4, 5]]) {
            sheet.merge(
              CellIndex.indexByColumnRow(columnIndex: cols[0], rowIndex: row),
              CellIndex.indexByColumnRow(columnIndex: cols[1], rowIndex: row),
            );
            _set(sheet, row, cols[0], '-', sNA);
            _fillMergedBorder(sheet, row, cols[0], cols[1], bg, useMedium: true);
          }
          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
            CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row),
          );
          _set(sheet, row, 6, '-', sNA);
          _fillMergedBorder(sheet, row, 6, 8, bg, useMedium: true);
        }
        row++;
      }

      sheet.setRowHeight(row, 24);
      final sSubHdr = _make(
          bg: _cSubTotBg, fg: _cSubTotFg,
          bold: true, fontSize: 9,
          halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
          useMedium: true);
      final sSubVal = _make(
          bg: _cSubTotBg, fg: _cSubTotFg,
          bold: true, fontSize: 11,
          halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
          useMedium: true);

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
      );
      _set(sheet, row, 0, 'Sub-Total  ${_dfmt.format(date)}', sSubHdr);
      _fillMergedBorder(sheet, row, 0, 1, _cSubTotBg, useMedium: true);

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
      );
      _setNum(sheet, row, 2, _round(dayRealA), sSubVal);
      _fillMergedBorder(sheet, row, 2, 3, _cSubTotBg, useMedium: true);

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
      );
      _setNum(sheet, row, 4, _round(dayRealB), sSubVal);
      _fillMergedBorder(sheet, row, 4, 5, _cSubTotBg, useMedium: true);

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row),
      );
      _setNum(sheet, row, 6, _round(dayRealA + dayRealB),
          _make(bg: _cSubTotBg, fg: _cSubTotFg, bold: true, fontSize: 12,
              halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
              useMedium: true));
      _fillMergedBorder(sheet, row, 6, 8, _cSubTotBg, useMedium: true);
      row++;

      grandRealA += dayRealA;
      grandRealB += dayRealB;

      row = _writeBlankRow(sheet, row, cols: 9, bg: 'F1F5F9');
    }

    // ── Grand Total ─────────────────────────────────────────────────────────
    sheet.setRowHeight(row, 28);

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
    );
    _set(sheet, row, 0,
        '★ GRAND TOTAL',
        _make(
          bg: _cGrandBg, fg: _cGrandFg,
          bold: true, fontSize: 11,
          halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
          useMedium: true,
        ));
    _fillMergedBorder(sheet, row, 0, 1, _cGrandBg, useMedium: true);

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
    );
    _setNum(sheet, row, 2, _round(grandRealA),
        _make(bg: _cGrandBg, fg: _cGrandFg, bold: true, fontSize: 12,
            halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
            useMedium: true));
    _fillMergedBorder(sheet, row, 2, 3, _cGrandBg, useMedium: true);

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
    );
    _setNum(sheet, row, 4, _round(grandRealB),
        _make(bg: _cGrandBg, fg: _cGrandFg, bold: true, fontSize: 12,
            halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
            useMedium: true));
    _fillMergedBorder(sheet, row, 4, 5, _cGrandBg, useMedium: true);

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row),
    );
    _setNum(sheet, row, 6, _round(grandRealA + grandRealB),
        _make(
          bg: _cGrandBg, fg: _cGrandFg,
          bold: true, fontSize: 14,
          halign: HorizontalAlign.Center, valign: VerticalAlign.Center,
          useMedium: true,
        ));
    _fillMergedBorder(sheet, row, 6, 8, _cGrandBg, useMedium: true);

    return row + 1;
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  static void _writeFooter(Sheet sheet, int fr) {
    sheet.setRowHeight(fr, 18);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: fr),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: fr),
    );
    _set(sheet, fr, 0,
        'Dicetak: ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.now())}'
        '  |  Data dari sistem Timbangan SPD'
        '  |  ★ = Baris terakhir shift (kuning=S1, biru=S2, hijau=S3)',
        _make(
          bg: _cFooterBg, fg: '6B7280',
          italic: true, fontSize: 8,
          halign: HorizontalAlign.Right, valign: VerticalAlign.Center,
        ));
    _fillMergedBorder(sheet, fr, 0, 8, _cFooterBg);
  }

  // ── Footer khusus Shift 3 ──────────────────────────────────────────────────
  static void _writeFooterShift3(
      Sheet sheet, int fr, DateTime startDate, DateTime endDate) {
    sheet.setRowHeight(fr, 18);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: fr),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: fr),
    );
    _set(sheet, fr, 0,
        'Dicetak: ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.now())}'
        '  |  Filter: Shift 3 saja (22:00 ${_dfmt.format(startDate)}'
        ' s/d akhir shift 3 ${_dfmt.format(endDate)})'
        '  |  Data dari sistem Timbangan SPD',
        _make(
          bg: _cFooterBg, fg: '6B7280',
          italic: true, fontSize: 8,
          halign: HorizontalAlign.Right, valign: VerticalAlign.Center,
        ));
    _fillMergedBorder(sheet, fr, 0, 8, _cFooterBg);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD LINE SHEET — ASYNC (biasa)
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> _buildLineSheetAsync(
    Excel excel, String lineName, List<WeightRecord> allRecords, {
    required DateTime? startDate, required DateTime? endDate,
  }) async {
    final filteredRecords = _filterByDateRange(allRecords, startDate, endDate);
    final lineRecs = filteredRecords.where((r) => r.line == lineName).toList();

    print('📄 Building sheet $lineName: ${lineRecs.length} records');

    final summaries = _computeDailyShiftSummaries(lineRecs);
    final lastIds   = _lastDailyShiftRecordIds(lineRecs);

    final sheet = excel[lineName];
    _applyColWidths(sheet);

    final sStr = startDate != null ? _dfmt.format(startDate) : '-';
    final eStr = endDate != null ? _dfmt.format(endDate) : '-';
    final fStr = 'Line: $lineName  |  Periode: $sStr s/d $eStr  |  '
        'Total: ${lineRecs.length} sesi  |  '
        '★ Baris warna = data terakhir tiap shift per hari';

    var row = _writeTitle(sheet, 0,
        title: 'DATA TIMBANGAN — $lineName', filterStr: fStr);
    row = _writeColHeaders(sheet, row);

    await Future.delayed(Duration.zero);
    if (lineRecs.isNotEmpty) {
      row = await _writeDataRowsAsync(sheet, lineRecs, row, lastIds);
    }

    row = _writeBlankRow(sheet, row, cols: 9);
    await Future.delayed(Duration.zero);
    row = _writeShiftSummarySection(sheet, summaries, row);
    row = _writeBlankRow(sheet, row, cols: 9);
    _writeFooter(sheet, row);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD LINE SHEET — ASYNC (khusus Shift 3)
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> _buildLineSheetShift3Async(
    Excel excel, String lineName, List<WeightRecord> allRecords, {
    required DateTime startDate, required DateTime endDate,
  }) async {
    // Filter hanya Shift 3 dalam range 22:00 startDate – 06:00 endDate
    final lineRecs = allRecords
        .where((r) => r.line == lineName)
        .toList();
    final shift3Recs = _filterShift3Range(lineRecs, startDate, endDate);

    print('📄 Building Shift3 sheet $lineName: ${shift3Recs.length} records');

    final summaries = _computeDailyShiftSummaries(shift3Recs);
    final lastIds   = _lastDailyShiftRecordIds(shift3Recs);

    final sheet = excel[lineName];
    _applyColWidths(sheet);

    final sStr = '${_dfmt.format(startDate)} 22:00';
    final eStr = '${_dfmt.format(endDate)} 07:00';
    final fStr = 'Line: $lineName  |  Shift 3: $sStr s/d $eStr  |  '
        'Total: ${shift3Recs.length} sesi  |  '
        '🌙 Hanya data Shift 3 (22:00–07:00)';

    var row = _writeTitle(sheet, 0,
        title: 'DATA TIMBANGAN SHIFT 3 — $lineName',
        filterStr: fStr);
    row = _writeColHeaders(sheet, row);

    await Future.delayed(Duration.zero);
    if (shift3Recs.isNotEmpty) {
      row = await _writeDataRowsAsync(sheet, shift3Recs, row, lastIds);
    }

    row = _writeBlankRow(sheet, row, cols: 9);
    await Future.delayed(Duration.zero);
    row = _writeShiftSummarySection(sheet, summaries, row);
    row = _writeBlankRow(sheet, row, cols: 9);
    _writeFooterShift3(sheet, row, startDate, endDate);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD LINE SHEET — SYNC (biasa)
  // ═══════════════════════════════════════════════════════════════════════════
  static void _buildLineSheetSync(
    Excel excel, String lineName, List<WeightRecord> allRecords, {
    required DateTime? startDate, required DateTime? endDate,
  }) {
    final filteredRecords = _filterByDateRange(allRecords, startDate, endDate);
    final lineRecs = filteredRecords.where((r) => r.line == lineName).toList();

    print('📄 Building sheet $lineName: ${lineRecs.length} records');

    final summaries = _computeDailyShiftSummaries(lineRecs);
    final lastIds   = _lastDailyShiftRecordIds(lineRecs);

    final sheet = excel[lineName];
    _applyColWidths(sheet);

    final sStr = startDate != null ? _dfmt.format(startDate) : '-';
    final eStr = endDate != null ? _dfmt.format(endDate) : '-';
    final fStr = 'Line: $lineName  |  Periode: $sStr s/d $eStr  |  '
        'Total: ${lineRecs.length} sesi  |  '
        '★ Baris warna = data terakhir tiap shift per hari';

    var row = _writeTitle(sheet, 0,
        title: 'DATA TIMBANGAN — $lineName', filterStr: fStr);
    row = _writeColHeaders(sheet, row);

    if (lineRecs.isNotEmpty) {
      row = _writeDataRowsSync(sheet, lineRecs, row, lastIds);
    }

    row = _writeBlankRow(sheet, row, cols: 9);
    row = _writeShiftSummarySection(sheet, summaries, row);
    row = _writeBlankRow(sheet, row, cols: 9);
    _writeFooter(sheet, row);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD LINE SHEET — SYNC (khusus Shift 3)
  // ═══════════════════════════════════════════════════════════════════════════
  static void _buildLineSheetShift3Sync(
    Excel excel, String lineName, List<WeightRecord> allRecords, {
    required DateTime startDate, required DateTime endDate,
  }) {
    final lineRecs = allRecords
        .where((r) => r.line == lineName)
        .toList();
    final shift3Recs = _filterShift3Range(lineRecs, startDate, endDate);

    print('📄 Building Shift3 sheet $lineName: ${shift3Recs.length} records');

    final summaries = _computeDailyShiftSummaries(shift3Recs);
    final lastIds   = _lastDailyShiftRecordIds(shift3Recs);

    final sheet = excel[lineName];
    _applyColWidths(sheet);

    final sStr = '${_dfmt.format(startDate)} 22:00';
    final eStr = '${_dfmt.format(endDate)} 06:00';
    final fStr = 'Line: $lineName  |  Shift 3: $sStr s/d $eStr  |  '
        'Total: ${shift3Recs.length} sesi  |  '
        '🌙 Hanya data Shift 3 (22:00–07:00)';

    var row = _writeTitle(sheet, 0,
        title: 'DATA TIMBANGAN SHIFT 3 — $lineName',
        filterStr: fStr);
    row = _writeColHeaders(sheet, row);

    if (shift3Recs.isNotEmpty) {
      row = _writeDataRowsSync(sheet, shift3Recs, row, lastIds);
    }

    row = _writeBlankRow(sheet, row, cols: 9);
    row = _writeShiftSummarySection(sheet, summaries, row);
    row = _writeBlankRow(sheet, row, cols: 9);
    _writeFooterShift3(sheet, row, startDate, endDate);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ISOLATE PAYLOAD
  // ═══════════════════════════════════════════════════════════════════════════
  static Map<String, dynamic> _buildIsolatePayload({
    required List<WeightRecord> records,
    required DateTime? startDate,
    required DateTime? endDate,
    required List<String> linesToBuild,
    bool shift3Only = false,
  }) {
    return {
      'records'      : records,
      'startDate'    : startDate?.millisecondsSinceEpoch,
      'endDate'      : endDate?.millisecondsSinceEpoch,
      'linesToBuild' : linesToBuild,
      'shift3Only'   : shift3Only,
      'now'          : DateTime.now().millisecondsSinceEpoch,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD EXCEL — NATIVE ISOLATE
  // ═══════════════════════════════════════════════════════════════════════════
  static List<int> _buildExcelInIsolate(Map<String, dynamic> payload) {
    final records      = payload['records']      as List<WeightRecord>;
    final startDateMs  = payload['startDate']    as int?;
    final endDateMs    = payload['endDate']      as int?;
    final linesToBuild = payload['linesToBuild'] as List<String>;
    final shift3Only   = payload['shift3Only']   as bool? ?? false;

    final startDate = startDateMs != null
        ? DateTime.fromMillisecondsSinceEpoch(startDateMs) : null;
    final endDate = endDateMs != null
        ? DateTime.fromMillisecondsSinceEpoch(endDateMs) : null;

    print('🚀 Starting Excel generation in isolate... shift3Only=$shift3Only');
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    if (shift3Only && startDate != null && endDate != null) {
      for (final l in linesToBuild) {
        _buildLineSheetShift3Sync(excel, l, records,
            startDate: startDate, endDate: endDate);
      }
    } else {
      for (final l in linesToBuild) {
        _buildLineSheetSync(excel, l, records,
            startDate: startDate, endDate: endDate);
      }
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Gagal encode Excel');
    print('✅ Excel generated, size: ${bytes.length} bytes');
    return bytes;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD EXCEL — WEB ASYNC
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<List<int>> _buildExcelAsync(
      Map<String, dynamic> payload) async {
    final records      = payload['records']      as List<WeightRecord>;
    final startDateMs  = payload['startDate']    as int?;
    final endDateMs    = payload['endDate']      as int?;
    final linesToBuild = payload['linesToBuild'] as List<String>;
    final shift3Only   = payload['shift3Only']   as bool? ?? false;

    final startDate = startDateMs != null
        ? DateTime.fromMillisecondsSinceEpoch(startDateMs) : null;
    final endDate = endDateMs != null
        ? DateTime.fromMillisecondsSinceEpoch(endDateMs) : null;

    print('🌐 Starting Excel generation on Web... shift3Only=$shift3Only');
    _resetCache();

    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    for (final l in linesToBuild) {
      await Future.delayed(Duration.zero);
      if (shift3Only && startDate != null && endDate != null) {
        await _buildLineSheetShift3Async(excel, l, records,
            startDate: startDate, endDate: endDate);
      } else {
        await _buildLineSheetAsync(excel, l, records,
            startDate: startDate, endDate: endDate);
      }
    }

    await Future.delayed(Duration.zero);
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Gagal encode Excel');
    print('✅ Excel generated, size: ${bytes.length} bytes');
    return bytes;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN EXPORT — BIASA
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> exportHistory({
    required List<WeightRecord> records,
    required DateTime? startDate,
    required DateTime? endDate,
    required String? line,
    required String? shift,
    required String source,
  }) async {
    await _doExport(
      records:    records,
      startDate:  startDate,
      endDate:    endDate,
      line:       line,
      shift:      shift,
      source:     source,
      shift3Only: false,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN EXPORT — SHIFT 3 SAJA (22:00 startDate – 06:00 endDate)
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> exportHistoryShift3Only({
    required List<WeightRecord> records,
    required DateTime startDate,
    required DateTime endDate,
    required String? line,
    required String source,
  }) async {
    await _doExport(
      records:    records,
      startDate:  startDate,
      endDate:    endDate,
      line:       line,
      shift:      '3',
      source:     source,
      shift3Only: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED EXPORT LOGIC
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> _doExport({
    required List<WeightRecord> records,
    required DateTime? startDate,
    required DateTime? endDate,
    required String? line,
    required String? shift,
    required String source,
    required bool shift3Only,
  }) async {
    print('📤 EXPORTING HISTORY (shift3Only=$shift3Only)');
    print('📅 Start: ${startDate?.toIso8601String()}');
    print('📅 End  : ${endDate?.toIso8601String()}');
    print('📊 Total records before filter: ${records.length}');

    List<WeightRecord> finalRecords;

    if (shift3Only && startDate != null && endDate != null) {
      // Tidak pre-filter by date — dilakukan di dalam builder per line
      finalRecords = records;
    } else {
      final filteredByDate = _filterByDateRange(records, startDate, endDate);
      print('📊 After date filter: ${filteredByDate.length}');
      finalRecords = filteredByDate;
    }

    if (line != null && line.isNotEmpty) {
      finalRecords = finalRecords.where((r) => r.line == line).toList();
      print('📊 After line filter ($line): ${finalRecords.length}');
    }

    if (!shift3Only &&
        shift != null &&
        shift.isNotEmpty &&
        shift != 'Semua') {
      finalRecords =
          finalRecords.where((r) => _fmtShift(r.shift) == shift).toList();
      print('📊 After shift filter ($shift): ${finalRecords.length}');
    }

    if (source != 'Semua') {
      finalRecords =
          finalRecords.where((r) => r.source == source).toList();
      print('📊 After source filter ($source): ${finalRecords.length}');
    }

    final linesToBuild =
        (line != null && line.isNotEmpty) ? [line] : _allLines;

    final payload = _buildIsolatePayload(
      records:      finalRecords,
      startDate:    startDate,
      endDate:      endDate,
      linesToBuild: linesToBuild,
      shift3Only:   shift3Only,
    );

    final List<int> fileBytes;
    if (kIsWeb) {
      fileBytes = await _buildExcelAsync(payload);
    } else {
      fileBytes = await compute(_buildExcelInIsolate, payload);
    }

    // Nama file: tambahkan suffix _Shift3 bila mode shift 3 only
    final suffix = shift3Only ? '_Shift3' : '';
    final fileName =
        'TimbanganSPD_${_dateFmt.format(startDate ?? DateTime.now())}'
        '_to_${_dateFmt.format(endDate ?? DateTime.now())}$suffix.xlsx';

    if (kIsWeb) {
      final blob = html.Blob(
        [Uint8List.fromList(fileBytes)],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(fileBytes);

      final sStr = startDate != null ? _dfmt.format(startDate) : '-';
      final eStr = endDate != null ? _dfmt.format(endDate) : '-';
      final subjectSuffix = shift3Only ? ' (Shift 3: 22:00–07:00)' : '';

      await Share.shareXFiles(
        [XFile(file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: 'Riwayat Timbangan $sStr – $eStr$subjectSuffix',
        text: 'Data timbangan SPD diekspor pada '
            '${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.now())}',
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ROW STYLE CACHE
// ═══════════════════════════════════════════════════════════════════════════════
class _RowStyleCache {
  late final CellStyle center;
  late final CellStyle centerBold;
  late final CellStyle no;
  late final CellStyle line;
  late final CellStyle srcAuto;
  late final CellStyle srcManual;

  _RowStyleCache(String bg) {
    center     = ExcelExportService._make(bg: bg, fg: ExcelExportService._cText,      useData: true);
    centerBold = ExcelExportService._make(bg: bg, fg: ExcelExportService._cText,      useData: true, bold: true);
    no         = ExcelExportService._make(bg: bg, fg: ExcelExportService._cNoFg,      useData: true, bold: true);
    line       = ExcelExportService._make(bg: bg, fg: ExcelExportService._cLineFg,    useData: true, bold: true);
    srcAuto    = ExcelExportService._make(bg: bg, fg: ExcelExportService._cSrcAuto,   useData: true, bold: true);
    srcManual  = ExcelExportService._make(bg: bg, fg: ExcelExportService._cSrcManual, useData: true, bold: true);
  }
}