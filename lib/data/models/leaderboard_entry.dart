import 'package:hive/hive.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.playerName,
    required this.seconds,
    required this.timestamp,
  });

  final String playerName;
  final int seconds;
  final DateTime timestamp;
}

class LeaderboardEntryAdapter extends TypeAdapter<LeaderboardEntry> {
  @override
  final int typeId = 2;

  @override
  LeaderboardEntry read(BinaryReader reader) {
    final name = reader.readString();
    final seconds = reader.readInt();
    final timestamp = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    return LeaderboardEntry(
      playerName: name,
      seconds: seconds,
      timestamp: timestamp,
    );
  }

  @override
  void write(BinaryWriter writer, LeaderboardEntry obj) {
    writer
      ..writeString(obj.playerName)
      ..writeInt(obj.seconds)
      ..writeInt(obj.timestamp.millisecondsSinceEpoch);
  }
}
