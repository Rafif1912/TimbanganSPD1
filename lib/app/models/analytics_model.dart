// ─────────────────────────────────────────────
// Analytics Models
// ─────────────────────────────────────────────

class DailyProduction {
  final DateTime date;
  final double totalWeight;
  final int transactions;
  final Map<String, double> perLine; // line → totalWeight

  const DailyProduction({
    required this.date,
    required this.totalWeight,
    required this.transactions,
    required this.perLine,
  });
}

class LinePerformance {
  final String line;
  final double totalWeight;
  final int totalTransactions;
  final double avgWeight;
  final double positiveWeight;
  final double negativeWeight;

  const LinePerformance({
    required this.line,
    required this.totalWeight,
    required this.totalTransactions,
    required this.avgWeight,
    required this.positiveWeight,
    required this.negativeWeight,
  });

  /// Persentase data positif dari total (proxy "uptime")
  double get positivePct => totalTransactions == 0
      ? 0
      : (positiveWeight / (positiveWeight + negativeWeight.abs() + 0.001)) *
          100;
}
