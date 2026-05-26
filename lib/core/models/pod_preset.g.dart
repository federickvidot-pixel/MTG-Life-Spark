// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pod_preset.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PodPresetAdapter extends TypeAdapter<PodPreset> {
  @override
  final int typeId = 5;

  @override
  PodPreset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PodPreset(
      id: fields[0] as String,
      name: fields[1] as String,
      defaultLocationLabel: fields[2] as String?,
      note: fields[3] as String?,
      memberPlayerIds: (fields[4] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PodPreset obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.defaultLocationLabel)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.memberPlayerIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PodPresetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
