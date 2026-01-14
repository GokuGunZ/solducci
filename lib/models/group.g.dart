// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseGroupAdapter extends TypeAdapter<ExpenseGroup> {
  @override
  final int typeId = 6;

  @override
  ExpenseGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpenseGroup(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      createdBy: fields[3] as String,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      members: (fields[6] as List?)?.cast<GroupMember>(),
      memberCount: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseGroup obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.createdBy)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.members)
      ..writeByte(7)
      ..write(obj.memberCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GroupMemberAdapter extends TypeAdapter<GroupMember> {
  @override
  final int typeId = 7;

  @override
  GroupMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupMember(
      id: fields[0] as String,
      groupId: fields[1] as String,
      userId: fields[2] as String,
      role: fields[3] as GroupRole,
      joinedAt: fields[4] as DateTime,
      nickname: fields[5] as String?,
      email: fields[6] as String?,
      avatarUrl: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GroupMember obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.joinedAt)
      ..writeByte(5)
      ..write(obj.nickname)
      ..writeByte(6)
      ..write(obj.email)
      ..writeByte(7)
      ..write(obj.avatarUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GroupRoleAdapter extends TypeAdapter<GroupRole> {
  @override
  final int typeId = 8;

  @override
  GroupRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GroupRole.admin;
      case 1:
        return GroupRole.member;
      default:
        return GroupRole.admin;
    }
  }

  @override
  void write(BinaryWriter writer, GroupRole obj) {
    switch (obj) {
      case GroupRole.admin:
        writer.writeByte(0);
        break;
      case GroupRole.member:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
