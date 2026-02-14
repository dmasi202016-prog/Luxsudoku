// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hint_balance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HintBalanceAdapter extends TypeAdapter<HintBalance> {
  @override
  final int typeId = 3;

  @override
  HintBalance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HintBalance(
      currentHints: fields[0] as int,
      totalUsed: fields[1] as int,
      totalFromAds: fields[2] as int,
      totalPurchased: fields[3] as int,
      lastUpdated: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HintBalance obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.currentHints)
      ..writeByte(1)
      ..write(obj.totalUsed)
      ..writeByte(2)
      ..write(obj.totalFromAds)
      ..writeByte(3)
      ..write(obj.totalPurchased)
      ..writeByte(4)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HintBalanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
