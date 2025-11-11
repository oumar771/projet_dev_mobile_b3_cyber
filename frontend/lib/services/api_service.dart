// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'auth_service.dart';
export 'auth_service.dart';

class ApiService {
  // 1. CORRECTION CRITIQUE DE L'IP
  // 'localhost:8080' ne fonctionne que sur le web.
  // '172.20.10.3:8080' est l'adresse pour Android sur le même réseau local.
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://172.20.10.3:8080', // <-- CORRIGÉ (était 127.20.10.3)
      connectTimeout: const Duration(seconds: 40),
      receiveTimeout: const Duration(seconds: 80),
    ),
  );

  // 2. CORRECTION: Stocker l'instance du service d'authentification
  final AuthService _authService;

  // 3. CORRECTION: Le constructeur assigne les services injectés
  // (Nous ignorons le 'dio' injecté par Riverpod pour garder notre _dio
  // avec le BaseUrl, mais nous GARDONS le authService.)
  ApiService(Dio dio, AuthService authService) : _authService = authService;

  // Getter pour accéder au dio depuis les repositories
  Dio get dio => _dio;

  // Connexion (public, donc inchangé)
  Future<Response> login(String username, String password) {
    return _dio.post(
      '/api/auth/signin',
      data: {'username': username, 'password': password},
    );
  }

  // 4. CORRECTION: Utilise l'instance _authService et la méthode getToken()
  Future<Response<T>> getAuth<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    // Utilise l'instance stockée et la bonne méthode
    final token = await _authService.getToken(); 
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: Options(headers: {'x-access-token': token}),
    );
  }

  // 5. CORRECTION: Utilise l'instance _authService et la méthode getToken()
  Future<Response<T>> postAuth<T>(String path, {Map<String, dynamic>? data}) async {
    final token = await _authService.getToken(); // <-- CORRIGÉ
    return _dio.post<T>(
      path,
      data: data,
      options: Options(headers: {'x-access-token': token}),
    );
  }

  // 6. CORRECTION: Utilise l'instance _authService et la méthode getToken()
  Future<Response<T>> putAuth<T>(String path, {Map<String, dynamic>? data}) async {
    final token = await _authService.getToken(); // <-- CORRIGÉ
    return _dio.put<T>(
      path,
      data: data,
      options: Options(headers: {'x-access-token': token}),
    );
  }

  // 7. CORRECTION: Utilise l'instance _authService et la méthode getToken()
  Future<Response<T>> deleteAuth<T>(String path) async {
    final token = await _authService.getToken(); // <-- CORRIGÉ
    return _dio.delete<T>(
      path,
      options: Options(headers: {'x-access-token': token}),
    );
  }
}