// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SplitTypeAdapter extends TypeAdapter<SplitType> {
  @override
  final int typeId = 4;

  @override
  SplitType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SplitType.equal;
      case 1:
        return SplitType.lend;
      case 2:
        return SplitType.offer;
      case 3:
        return SplitType.custom;
      default:
        return SplitType.equal;
    }
  }

  @override
  void write(BinaryWriter writer, SplitType obj) {
    switch (obj) {
      case SplitType.equal:
        writer.writeByte(0);
        break;
      case SplitType.lend:
        writer.writeByte(1);
        break;
      case SplitType.offer:
        writer.writeByte(2);
        break;
      case SplitType.custom:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
