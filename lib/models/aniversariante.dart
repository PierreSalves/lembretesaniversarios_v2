import 'dart:io';

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

  /// Verifica se a pessoa faz aniversário na data atual
  bool get eHoje {
    final agora = DateTime.now();
    return dia == agora.day && mes == agora.month;
  }

  /// Retorna a próxima data de aniversário (ano atual ou próximo ano se já passou)
  DateTime get proximaData {
    final agora = DateTime.now();
    final hojeInicio = DateTime(agora.year, agora.month, agora.day);
    var dataNesteAno = DateTime(agora.year, mes, dia);

    if (dataNesteAno.isBefore(hojeInicio)) {
      return DateTime(agora.year + 1, mes, dia);
    }
    return dataNesteAno;
  }

  /// Quantidade de dias restantes até o próximo aniversário
  int get diasAteProximoAniversario {
    final agora = DateTime.now();
    final hojeInicio = DateTime(agora.year, agora.month, agora.day);
    return proximaData.difference(hojeInicio).inDays;
  }

  /// Data formatada como DD/MM
  String get dataFormatada {
    final diaStr = dia.toString().padLeft(2, '0');
    final mesStr = mes.toString().padLeft(2, '0');
    return '$diaStr/$mesStr';
  }

  /// Verifica se o arquivo de foto local existe no dispositivo
  bool get temFotoLocalValida {
    return caminhoFoto != null &&
        caminhoFoto!.isNotEmpty &&
        File(caminhoFoto!).existsSync();
  }

  /// Retorna a mensagem completa e formatada de parabéns
  String get mensagemParabensFormatada {
    final baseMensagem = mensagemCustomizada != null && mensagemCustomizada!.trim().isNotEmpty
        ? mensagemCustomizada!.trim()
        : 'Parabéns!';
    return '$baseMensagem\n\n- Parabéns, $nome! 🎂🎉';
  }

  Aniversariante copyWith({
    int? id,
    String? nome,
    int? dia,
    int? mes,
    String? caminhoFoto,
    String? driveFileIdFoto,
    String? mensagemCustomizada,
    int? excluido,
    int? dataAtualizacao,
  }) {
    return Aniversariante(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      dia: dia ?? this.dia,
      mes: mes ?? this.mes,
      caminhoFoto: caminhoFoto ?? this.caminhoFoto,
      driveFileIdFoto: driveFileIdFoto ?? this.driveFileIdFoto,
      mensagemCustomizada: mensagemCustomizada ?? this.mensagemCustomizada,
      excluido: excluido ?? this.excluido,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }

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