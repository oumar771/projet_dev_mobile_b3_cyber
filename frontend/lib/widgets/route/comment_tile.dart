import 'package:flutter/material.dart';
import '../../models/comment.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;

  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(comment.username?.substring(0, 1).toUpperCase() ?? 'U'),
      ),
      title: Text(comment.username ?? 'Utilisateur'),
      subtitle: Text(comment.text),
      trailing: comment.createdAt != null
          ? Text(
              _formatDate(comment.createdAt!),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) return '${diff.inDays}j';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min';
    return 'maintenant';
  }
}
