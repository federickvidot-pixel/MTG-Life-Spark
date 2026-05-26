// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 4;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      hapticEnabled: fields[0] as bool,
      soundEnabled: fields[1] as bool,
      defaultFormat: fields[2] as String,
      defaultStartingLife: fields[3] as int,
      scryfallCacheEnabled: fields[4] as bool,
      shakeToUndoEnabled: fields[5] as bool,
      onboardingCompleted: fields[6] as bool,
      keepDisplayAwake: fields[7] as bool,
      hideSystemBars: fields[8] as bool,
      useDarkTheme: fields[9] == null ? true : fields[9] as bool,
      colorSchemeId: fields[10] == null ? 'violet' : fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.hapticEnabled)
      ..writeByte(1)
      ..write(obj.soundEnabled)
      ..writeByte(2)
      ..write(obj.defaultFormat)
      ..writeByte(3)
      ..write(obj.defaultStartingLife)
      ..writeByte(4)
      ..write(obj.scryfallCacheEnabled)
      ..writeByte(5)
      ..write(obj.shakeToUndoEnabled)
      ..writeByte(6)
      ..write(obj.onboardingCompleted)
      ..writeByte(7)
      ..write(obj.keepDisplayAwake)
      ..writeByte(8)
      ..write(obj.hideSystemBars)
      ..writeByte(9)
      ..write(obj.useDarkTheme)
      ..writeByte(10)
      ..write(obj.colorSchemeId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
