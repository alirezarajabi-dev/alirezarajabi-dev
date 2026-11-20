/// A medicine the parent takes every day at a fixed time.
class Pill {
  Pill({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    this.voiceFile,
  });

  /// Small positive number; also the base for notification ids.
  final int id;
  String name;
  int hour;
  int minute;

  /// File name (not path) of a voice recorded only for this pill.
  /// When null, the general family voice is used.
  String? voiceFile;

  int get minutesOfDay => hour * 60 + minute;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hour': hour,
        'minute': minute,
        'voiceFile': voiceFile,
      };

  factory Pill.fromJson(Map<String, dynamic> j) => Pill(
        id: j['id'] as int,
        name: j['name'] as String,
        hour: j['hour'] as int,
        minute: j['minute'] as int,
        voiceFile: j['voiceFile'] as String?,
      );
}

/// `yyyy-mm-dd` key for a calendar day, used to remember doses taken.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
