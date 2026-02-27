// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MatchRecordAdapter extends TypeAdapter<MatchRecord> {
  @override
  final int typeId = 1;

  @override
  MatchRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MatchRecord(
      matchId: fields[0] as String,
      date: fields[1] as DateTime,
      commanderName: fields[2] as String,
      partnerCommanderName: fields[3] as String?,
      opponentNames: (fields[4] as List).cast<String>(),
      result: fields[5] as String,
      eliminationReason: fields[6] as String,
      format: fields[7] as String,
      durationMinutes: fields[8] as int,
      startingLifeTotal: fields[9] as int,
      playerCount: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MatchRecord obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.matchId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.commanderName)
      ..writeByte(3)
      ..write(obj.partnerCommanderName)
      ..writeByte(4)
      ..write(obj.opponentNames)
      ..writeByte(5)
      ..write(obj.result)
      ..writeByte(6)
      ..write(obj.eliminationReason)
      ..writeByte(7)
      ..write(obj.format)
      ..writeByte(8)
      ..write(obj.durationMinutes)
      ..writeByte(9)
      ..write(obj.startingLifeTotal)
      ..writeByte(10)
      ..write(obj.playerCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
