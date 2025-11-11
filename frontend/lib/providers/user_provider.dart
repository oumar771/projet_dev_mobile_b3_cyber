import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'service_providers.dart';

// Provider pour récupérer les utilisateurs visibles sur la carte
final visibleUsersProvider = FutureProvider<List<User>>((ref) async {
  final userRepo = ref.watch(userRepositoryProvider);
  return await userRepo.getVisibleUsers();
});

// Provider pour récupérer un utilisateur par son ID
final userByIdProvider = FutureProvider.family<User, int>((ref, userId) async {
  final userRepo = ref.watch(userRepositoryProvider);
  return await userRepo.getUserById(userId);
});