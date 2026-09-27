// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_asset.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvestmentAssetAdapter extends TypeAdapter<InvestmentAsset> {
  @override
  final int typeId = 16;

  @override
  InvestmentAsset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvestmentAsset(
      id: fields[0] as String,
      portfolioId: fields[1] as String,
      name: fields[2] as String,
      ticker: fields[3] as String?,
      assetClass: fields[4] as AssetClass,
      totalQuantity: fields[5] as double,
      investedCapital: fields[6] as double,
      currentPrice: fields[7] as double,
      lastPriceUpdate: fields[8] as DateTime,
      note: fields[9] as String?,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
      editionOrSet: fields[12] as String?,
      conditionOrGrading: fields[13] as String?,
      serialOrCertNumber: fields[14] as String?,
      storageLocation: fields[15] as String?,
      isPhysical: fields[16] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, InvestmentAsset obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.portfolioId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.ticker)
      ..writeByte(4)
      ..write(obj.assetClass)
      ..writeByte(5)
      ..write(obj.totalQuantity)
      ..writeByte(6)
      ..write(obj.investedCapital)
      ..writeByte(7)
      ..write(obj.currentPrice)
      ..writeByte(8)
      ..write(obj.lastPriceUpdate)
      ..writeByte(9)
      ..write(obj.note)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.editionOrSet)
      ..writeByte(13)
      ..write(obj.conditionOrGrading)
      ..writeByte(14)
      ..write(obj.serialOrCertNumber)
      ..writeByte(15)
      ..write(obj.storageLocation)
      ..writeByte(16)
      ..write(obj.isPhysical);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestmentAssetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
