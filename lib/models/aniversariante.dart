class Aniversariante {
  final int? id;
  final String nome;
  final int dia;
  final int mes;
  final String? caminhoFoto;
  final String? mensagemCustomizada;

  Aniversariante({
    this.id,
    required this.nome,
    required this.dia,
    required this.mes,
    this.caminhoFoto,
    this.mensagemCustomizada,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'dia': dia,
      'mes': mes,
      'caminho_foto': caminhoFoto,
      'mensagem_customizada': mensagemCustomizada,
    };
  }

  factory Aniversariante.fromMap(Map<String, dynamic> map) {
    return Aniversariante(
      id: map['id'],
      nome: map['nome'],
      dia: map['dia'],
      mes: map['mes'],
      caminhoFoto: map['caminho_foto'],
      mensagemCustomizada: map['mensagem_customizada'],
    );
  }
}