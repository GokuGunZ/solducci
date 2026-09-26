// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'income_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IncomeCategoryAdapter extends TypeAdapter<IncomeCategory> {
  @override
  final int typeId = 12;

  @override
  IncomeCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return IncomeCategory.stipendio;
      case 1:
        return IncomeCategory.regalo;
      case 2:
        return IncomeCategory.rimborso;
      case 3:
        return IncomeCategory.rendita;
      case 4:
        return IncomeCategory.vendite;
      case 5:
        return IncomeCategory.altro;
      default:
        return IncomeCategory.stipendio;
    }
  }

  @override
  void write(BinaryWriter writer, IncomeCategory obj) {
    switch (obj) {
      case IncomeCategory.stipendio:
        writer.writeByte(0);
        break;
      case IncomeCategory.regalo:
        writer.writeByte(1);
        break;
      case IncomeCategory.rimborso:
        writer.writeByte(2);
        break;
      case IncomeCategory.rendita:
        writer.writeByte(3);
        break;
      case IncomeCategory.vendite:
        writer.writeByte(4);
        break;
      case IncomeCategory.altro:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
