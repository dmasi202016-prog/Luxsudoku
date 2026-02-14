// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'premium_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PremiumStatusAdapter extends TypeAdapter<PremiumStatus> {
  @override
  final int typeId = 4;

  @override
  PremiumStatus read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PremiumStatus(
      isPremium: fields[0] as bool,
      purchasedAt: fields[1] as DateTime?,
      transactionId: fields[2] as String?,
      lastVerified: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PremiumStatus obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.isPremium)
      ..writeByte(1)
      ..write(obj.purchasedAt)
      ..writeByte(2)
      ..write(obj.transactionId)
      ..writeByte(3)
      ..write(obj.lastVerified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PremiumStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
