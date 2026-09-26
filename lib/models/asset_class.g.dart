// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_class.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssetClassAdapter extends TypeAdapter<AssetClass> {
  @override
  final int typeId = 15;

  @override
  AssetClass read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AssetClass.etf;
      case 1:
        return AssetClass.stock;
      case 2:
        return AssetClass.crypto;
      case 3:
        return AssetClass.bond;
      case 4:
        return AssetClass.commodity;
      case 5:
        return AssetClass.realEstate;
      case 6:
        return AssetClass.pension;
      case 7:
        return AssetClass.cashEquivalent;
      case 8:
        return AssetClass.other;
      default:
        return AssetClass.etf;
    }
  }

  @override
  void write(BinaryWriter writer, AssetClass obj) {
    switch (obj) {
      case AssetClass.etf:
        writer.writeByte(0);
        break;
      case AssetClass.stock:
        writer.writeByte(1);
        break;
      case AssetClass.crypto:
        writer.writeByte(2);
        break;
      case AssetClass.bond:
        writer.writeByte(3);
        break;
      case AssetClass.commodity:
        writer.writeByte(4);
        break;
      case AssetClass.realEstate:
        writer.writeByte(5);
        break;
      case AssetClass.pension:
        writer.writeByte(6);
        break;
      case AssetClass.cashEquivalent:
        writer.writeByte(7);
        break;
      case AssetClass.other:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetClassAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
