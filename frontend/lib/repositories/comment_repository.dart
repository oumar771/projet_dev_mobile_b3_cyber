import '../models/comment.dart';
import '../services/api_service.dart';

// Repository pour g�rer les commentaires
class CommentRepository {
  final ApiService _apiService;

  CommentRepository(this._apiService);

  // R�cup�rer tous les commentaires d'une route
  Future<List<Comment>> getCommentsByRoute(int routeId) async {
    try {
      final response = await _apiService.getAuth<List<dynamic>>(
        '/api/routes/$routeId/comments', queryParameters: {},
      );
      final List<dynamic> data = response.data ?? [];
      return data.map((json) => Comment.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Ajouter un commentaire � une route
  Future<Comment> addComment(int routeId, String text) async {
    try {
      final response = await _apiService.postAuth<Map<String, dynamic>>(
        '/api/routes/$routeId/comment',
        data: {'text': text},
      );
      return Comment.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer un commentaire
  Future<void> deleteComment(int commentId) async {
    try {
      await _apiService.deleteAuth('/api/comments/$commentId');
    } catch (e) {
      rethrow;
    }
  }

  // Modifier un commentaire
  Future<Comment> updateComment(int commentId, String text) async {
    try {
      final response = await _apiService.putAuth<Map<String, dynamic>>(
        '/api/comments/$commentId',
        data: {'text': text},
      );
      return Comment.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }
}
