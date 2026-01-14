// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'persistent_cache_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PersistentCacheMetadataAdapter
    extends TypeAdapter<PersistentCacheMetadata> {
  @override
  final int typeId = 0;

  @override
  PersistentCacheMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PersistentCacheMetadata(
      cachedAt: fields[0] as DateTime,
      lastSyncedAt: fields[1] as DateTime,
      dirty: fields[2] as bool,
      version: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PersistentCacheMetadata obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.cachedAt)
      ..writeByte(1)
      ..write(obj.lastSyncedAt)
      ..writeByte(2)
      ..write(obj.dirty)
      ..writeByte(3)
      ..write(obj.version);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersistentCacheMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
