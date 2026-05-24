class UsuarioPerfil {
  final String id;
  final String nome;
  final String email;
  final String perfil;

  const UsuarioPerfil({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
  });

  factory UsuarioPerfil.fromJson(Map<String, dynamic> json) =>
      UsuarioPerfil(
        id:     json['id']     as String,
        nome:   json['nome']   as String,
        email:  json['email']  as String,
        perfil: json['perfil'] as String,
      );
}