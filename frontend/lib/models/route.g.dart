// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BikeRouteAdapter extends TypeAdapter<BikeRoute> {
  @override
  final int typeId = 0;

  @override
  BikeRoute read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BikeRoute(
      id: fields[0] as int,
      name: fields[1] as String,
      description: fields[2] as String,
      isPublic: fields[3] as bool,
      waypoints: (fields[4] as List).cast<LatLng>(),
      userId: fields[5] as int,
      username: fields[6] as String?,
      createdAt: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BikeRoute obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.isPublic)
      ..writeByte(4)
      ..write(obj.waypoints)
      ..writeByte(5)
      ..write(obj.userId)
      ..writeByte(6)
      ..write(obj.username)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BikeRouteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
