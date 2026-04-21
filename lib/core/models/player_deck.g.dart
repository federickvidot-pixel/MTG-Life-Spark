// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_deck.dart';

class PlayerDeckAdapter extends TypeAdapter<PlayerDeck> {
  @override
  final int typeId = 6;

  @override
  PlayerDeck read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerDeck(
      id: fields[0] as String,
      displayName: fields[1] as String,
      commanderName: fields[2] as String,
      commanderImageUrl: fields[3] as String?,
      partnerCommanderName: fields[4] as String?,
      partnerCommanderImageUrl: fields[5] as String?,
      wins: (fields[6] as num?)?.toInt() ?? 0,
      losses: (fields[7] as num?)?.toInt() ?? 0,
      gamesPlayed: (fields[8] as num?)?.toInt() ?? 0,
      commanderManaCost: fields[9] as String?,
      partnerManaCost: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerDeck obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.commanderName)
      ..writeByte(3)
      ..write(obj.commanderImageUrl)
      ..writeByte(4)
      ..write(obj.partnerCommanderName)
      ..writeByte(5)
      ..write(obj.partnerCommanderImageUrl)
      ..writeByte(6)
      ..write(obj.wins)
      ..writeByte(7)
      ..write(obj.losses)
      ..writeByte(8)
      ..write(obj.gamesPlayed)
      ..writeByte(9)
      ..write(obj.commanderManaCost)
      ..writeByte(10)
      ..write(obj.partnerManaCost);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerDeckAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
