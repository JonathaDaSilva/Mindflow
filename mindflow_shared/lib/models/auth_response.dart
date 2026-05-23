class AuthResponse {
  final String token;
  final String userId;
  final String nome;
  final String email;
  final String perfil;

  const AuthResponse({
    required this.token,
    required this.userId,
    required this.nome,
    required this.email,
    required this.perfil,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token:  json['token']  as String,
        userId: json['userId'] as String,
        nome:   json['nome']   as String,
        email:  json['email']  as String,
        perfil: json['perfil'] as String,
      );
}