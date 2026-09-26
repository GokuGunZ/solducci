// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_asset_allocation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAssetAllocationAdapter extends TypeAdapter<ExpenseAssetAllocation> {
  @override
  final int typeId = 18;

  @override
  ExpenseAssetAllocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpenseAssetAllocation(
      id: fields[0] as String,
      expenseId: fields[1] as int,
      assetId: fields[2] as String,
      amount: fields[3] as double,
      quantity: fields[4] as double,
      pricePerUnit: fields[5] as double,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseAssetAllocation obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.expenseId)
      ..writeByte(2)
      ..write(obj.assetId)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.pricePerUnit)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAssetAllocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
