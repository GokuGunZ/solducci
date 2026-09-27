// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_price_snapshot.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssetPriceSnapshotAdapter extends TypeAdapter<AssetPriceSnapshot> {
  @override
  final int typeId = 17;

  @override
  AssetPriceSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssetPriceSnapshot(
      id: fields[0] as String,
      assetId: fields[1] as String,
      price: fields[2] as double,
      timestamp: fields[3] as DateTime,
      source: fields[4] as String,
      note: fields[5] as String?,
      transactionType: fields[6] as String?,
      quantityDelta: fields[7] as double?,
      totalAmount: fields[8] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, AssetPriceSnapshot obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.assetId)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.source)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.transactionType)
      ..writeByte(7)
      ..write(obj.quantityDelta)
      ..writeByte(8)
      ..write(obj.totalAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetPriceSnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
