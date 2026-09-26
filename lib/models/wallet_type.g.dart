// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WalletTypeAdapter extends TypeAdapter<WalletType> {
  @override
  final int typeId = 10;

  @override
  WalletType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WalletType.bank;
      case 1:
        return WalletType.cash;
      case 2:
        return WalletType.savings;
      case 3:
        return WalletType.creditCard;
      default:
        return WalletType.bank;
    }
  }

  @override
  void write(BinaryWriter writer, WalletType obj) {
    switch (obj) {
      case WalletType.bank:
        writer.writeByte(0);
        break;
      case WalletType.cash:
        writer.writeByte(1);
        break;
      case WalletType.savings:
        writer.writeByte(2);
        break;
      case WalletType.creditCard:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
