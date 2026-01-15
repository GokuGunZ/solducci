// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_form.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MoneyFlowAdapter extends TypeAdapter<MoneyFlow> {
  @override
  final int typeId = 2;

  @override
  MoneyFlow read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MoneyFlow.carlToPit;
      case 1:
        return MoneyFlow.pitToCarl;
      case 2:
        return MoneyFlow.carlDiv2;
      case 3:
        return MoneyFlow.pitDiv2;
      case 4:
        return MoneyFlow.carlucci;
      case 5:
        return MoneyFlow.pit;
      default:
        return MoneyFlow.carlToPit;
    }
  }

  @override
  void write(BinaryWriter writer, MoneyFlow obj) {
    switch (obj) {
      case MoneyFlow.carlToPit:
        writer.writeByte(0);
        break;
      case MoneyFlow.pitToCarl:
        writer.writeByte(1);
        break;
      case MoneyFlow.carlDiv2:
        writer.writeByte(2);
        break;
      case MoneyFlow.pitDiv2:
        writer.writeByte(3);
        break;
      case MoneyFlow.carlucci:
        writer.writeByte(4);
        break;
      case MoneyFlow.pit:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoneyFlowAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TipologiaAdapter extends TypeAdapter<Tipologia> {
  @override
  final int typeId = 3;

  @override
  Tipologia read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Tipologia.affitto;
      case 1:
        return Tipologia.cibo;
      case 2:
        return Tipologia.utenze;
      case 3:
        return Tipologia.prodottiCasa;
      case 4:
        return Tipologia.ristorante;
      case 5:
        return Tipologia.tempoLibero;
      case 6:
        return Tipologia.altro;
      default:
        return Tipologia.affitto;
    }
  }

  @override
  void write(BinaryWriter writer, Tipologia obj) {
    switch (obj) {
      case Tipologia.affitto:
        writer.writeByte(0);
        break;
      case Tipologia.cibo:
        writer.writeByte(1);
        break;
      case Tipologia.utenze:
        writer.writeByte(2);
        break;
      case Tipologia.prodottiCasa:
        writer.writeByte(3);
        break;
      case Tipologia.ristorante:
        writer.writeByte(4);
        break;
      case Tipologia.tempoLibero:
        writer.writeByte(5);
        break;
      case Tipologia.altro:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TipologiaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
