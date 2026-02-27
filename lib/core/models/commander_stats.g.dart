// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commander_stats.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommanderStatsAdapter extends TypeAdapter<CommanderStats> {
  @override
  final int typeId = 2;

  @override
  CommanderStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CommanderStats(
      commanderName: fields[0] as String,
      wins: fields[1] as int,
      losses: fields[2] as int,
      gamesPlayed: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CommanderStats obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.commanderName)
      ..writeByte(1)
      ..write(obj.wins)
      ..writeByte(2)
      ..write(obj.losses)
      ..writeByte(3)
      ..write(obj.gamesPlayed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommanderStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
