// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// IMPORTANT: Remove ANY import statements above this line
// The file should ONLY have 'part of' directive at the top

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BirthdayEventAdapter extends TypeAdapter<BirthdayEvent> {
  @override
  final int typeId = 0;

  @override
  BirthdayEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BirthdayEvent(
      name: fields[0] as String,
      birthday: fields[1] as DateTime,
      reminderTimes: (fields[2] as List).cast<DateTime>(),
      profileImagePath: fields[3] as String?,
      contactNumber: fields[4] as String?,
      notes: fields[5] as String?,
      isActive: fields[6] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, BirthdayEvent obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.birthday)
      ..writeByte(2)
      ..write(obj.reminderTimes)
      ..writeByte(3)
      ..write(obj.profileImagePath)
      ..writeByte(4)
      ..write(obj.contactNumber)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BirthdayEventAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}