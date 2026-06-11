// ─────────────────────────────────────────────
// Scale Model
// ─────────────────────────────────────────────

enum ScaleStatus { online, offline, loading, warning }

class ScaleDevice {
  final int id;
  final String name;
  final String location;
  final String ip;
  final String unit;
  final ScaleStatus status;
  final double? lastWeight;
  final DateTime? lastUpdate;
  final String? description;

  const ScaleDevice({
    required this.id,
    required this.name,
    required this.location,
    required this.ip,
    this.unit = 'kg',
    this.status = ScaleStatus.loading,
    this.lastWeight,
    this.lastUpdate,
    this.description,
  });

  ScaleDevice copyWith({
    int? id,
    String? name,
    String? location,
    String? ip,
    String? unit,
    ScaleStatus? status,
    double? lastWeight,
    DateTime? lastUpdate,
    String? description,
  }) {
    return ScaleDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      ip: ip ?? this.ip,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      lastWeight: lastWeight ?? this.lastWeight,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'ip': ip,
        'unit': unit,
        'lastWeight': lastWeight,
        'lastUpdate': lastUpdate?.toIso8601String(),
      };

  factory ScaleDevice.fromJson(Map<String, dynamic> json) => ScaleDevice(
        id: json['id'] as int,
        name: json['name'] as String,
        location: json['location'] as String? ?? '',
        ip: json['ip'] as String,
        unit: json['unit'] as String? ?? 'kg',
        lastWeight: (json['lastWeight'] as num?)?.toDouble(),
        lastUpdate: json['lastUpdate'] != null
            ? DateTime.tryParse(json['lastUpdate'] as String)
            : null,
      );
}
