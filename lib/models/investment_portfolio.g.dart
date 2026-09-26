// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_portfolio.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvestmentPortfolioAdapter extends TypeAdapter<InvestmentPortfolio> {
  @override
  final int typeId = 14;

  @override
  InvestmentPortfolio read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvestmentPortfolio(
      id: fields[0] as String,
      userId: fields[1] as String,
      groupId: fields[2] as String?,
      name: fields[3] as String,
      brokerName: fields[4] as String?,
      colorHex: fields[5] as String,
      icon: fields[6] as String,
      description: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, InvestmentPortfolio obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.groupId)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.brokerName)
      ..writeByte(5)
      ..write(obj.colorHex)
      ..writeByte(6)
      ..write(obj.icon)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestmentPortfolioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
