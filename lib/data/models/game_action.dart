import 'package:hive/hive.dart';

class GameAction {
  const GameAction({
    required this.row,
    required this.col,
    required this.previousValue,
    required this.newValue,
  });

  final int row;

  final int col;

  final int previousValue;

  final int newValue;
}

class GameActionAdapter extends TypeAdapter<GameAction> {
  @override
  final int typeId = 1;

  @override
  GameAction read(BinaryReader reader) {
    final row = reader.readInt();
    final col = reader.readInt();
    final prev = reader.readInt();
    final next = reader.readInt();
    return GameAction(
      row: row,
      col: col,
      previousValue: prev,
      newValue: next,
    );
  }

  @override
  void write(BinaryWriter writer, GameAction obj) {
    writer
      ..writeInt(obj.row)
      ..writeInt(obj.col)
      ..writeInt(obj.previousValue)
      ..writeInt(obj.newValue);
  }
}
