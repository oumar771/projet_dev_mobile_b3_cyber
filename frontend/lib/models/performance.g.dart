// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PerformanceAdapter extends TypeAdapter<Performance> {
  @override
  final int typeId = 3;

  @override
  Performance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Performance(
      id: fields[0] as int,
      userId: fields[1] as int,
      routeId: fields[2] as int,
      distance: fields[3] as double,
      duration: fields[4] as int,
      avgSpeed: fields[5] as double,
      maxSpeed: fields[6] as double?,
      calories: fields[7] as int?,
      completedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Performance obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.routeId)
      ..writeByte(3)
      ..write(obj.distance)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.avgSpeed)
      ..writeByte(6)
      ..write(obj.maxSpeed)
      ..writeByte(7)
      ..write(obj.calories)
      ..writeByte(8)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
