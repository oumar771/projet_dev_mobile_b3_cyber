import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment.dart';
import 'service_providers.dart';

// Provider pour r�cup�rer les commentaires d'une route
final routeCommentsProvider = FutureProvider.family<List<Comment>, int>((ref, routeId) async {
  final commentRepo = ref.watch(commentRepositoryProvider);
  return await commentRepo.getCommentsByRoute(routeId);
});
