// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerProfileAdapter extends TypeAdapter<PlayerProfile> {
  @override
  final int typeId = 0;

  @override
  PlayerProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerProfile(
      username: fields[0] as String,
      level: fields[1] as int,
      xp: fields[2] as int,
      tier: fields[3] as String,
      totalWins: fields[4] as int,
      totalLosses: fields[5] as int,
      selectedCommanderName: fields[6] as String?,
      selectedCommanderImageUrl: fields[7] as String?,
      selectedPartnerCommanderName: fields[8] as String?,
      selectedPartnerCommanderImageUrl: fields[9] as String?,
      unlockedThemes: (fields[10] as List).cast<String>(),
      unlockedBadges: (fields[11] as List).cast<String>(),
      lifetimePoisonDealt: fields[12] as int,
      lifetimeCommanderKills: fields[13] as int,
      currentWinStreak: fields[14] as int,
      totalGamesPlayed: fields[15] as int,
      profileAvatarImageUrl: fields[16] as String?,
      likesReceived: fields[17] as int,
      dislikesReceived: fields[18] as int,
      honorsMvpReceived: fields[19] as int,
      honorsTeamPlayerReceived: fields[20] as int,
      honorsUnderdogReceived: fields[21] as int,
      profileBannerImageUrl: fields[22] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerProfile obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.username)
      ..writeByte(1)
      ..write(obj.level)
      ..writeByte(2)
      ..write(obj.xp)
      ..writeByte(3)
      ..write(obj.tier)
      ..writeByte(4)
      ..write(obj.totalWins)
      ..writeByte(5)
      ..write(obj.totalLosses)
      ..writeByte(6)
      ..write(obj.selectedCommanderName)
      ..writeByte(7)
      ..write(obj.selectedCommanderImageUrl)
      ..writeByte(8)
      ..write(obj.selectedPartnerCommanderName)
      ..writeByte(9)
      ..write(obj.selectedPartnerCommanderImageUrl)
      ..writeByte(10)
      ..write(obj.unlockedThemes)
      ..writeByte(11)
      ..write(obj.unlockedBadges)
      ..writeByte(12)
      ..write(obj.lifetimePoisonDealt)
      ..writeByte(13)
      ..write(obj.lifetimeCommanderKills)
      ..writeByte(14)
      ..write(obj.currentWinStreak)
      ..writeByte(15)
      ..write(obj.totalGamesPlayed)
      ..writeByte(16)
      ..write(obj.profileAvatarImageUrl)
      ..writeByte(17)
      ..write(obj.likesReceived)
      ..writeByte(18)
      ..write(obj.dislikesReceived)
      ..writeByte(19)
      ..write(obj.honorsMvpReceived)
      ..writeByte(20)
      ..write(obj.honorsTeamPlayerReceived)
      ..writeByte(21)
      ..write(obj.honorsUnderdogReceived)
      ..writeByte(22)
      ..write(obj.profileBannerImageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
