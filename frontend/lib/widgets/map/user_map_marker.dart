import 'package:flutter/material.dart';

class UserMapMarker extends StatelessWidget {
  final String username;

  const UserMapMarker({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            username,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        const Icon(Icons.location_on, color: Colors.blue, size: 30),
      ],
    );
  }
}
