class Aniversariante {
  final int? id;
  final String nome;
  final int dia;
  final int mes;
  final String? caminhoFoto;
  final String? driveFileIdFoto;
  final String? mensagemCustomizada;
  final int excluido;
  final int dataAtualizacao;

  Aniversariante({
    this.id,
    required this.nome,
    required this.dia,
    required this.mes,
    this.caminhoFoto,
    this.driveFileIdFoto,
    this.mensagemCustomizada,
    this.excluido = 0,
    this.dataAtualizacao = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'dia': dia,
      'mes': mes,
      'caminho_foto': caminhoFoto,
      'drive_file_id_foto': driveFileIdFoto,
      'mensagem_customizada': mensagemCustomizada,
      'excluido': excluido,
      'data_atualizacao': dataAtualizacao,
    };
  }

  factory Aniversariante.fromMap(Map<String, dynamic> map) {
    return Aniversariante(
      id: map['id'],
      nome: map['nome'],
      dia: map['dia'],
      mes: map['mes'],
      caminhoFoto: map['caminho_foto'],
      driveFileIdFoto: map['drive_file_id_foto'],
      mensagemCustomizada: map['mensagem_customizada'],
      excluido: map['excluido'] ?? 0,
      dataAtualizacao: map['data_atualizacao'] ?? 0,
    );
  }
}