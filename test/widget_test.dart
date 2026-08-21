import 'package:flutter_test/flutter_test.dart';
import 'package:lembretesaniversarios/models/aniversariante.dart';

void main() {
  group('Aniversariante Model Tests', () {
    test('Calcula eHoje corretamente', () {
      final hoje = DateTime.now();
      final aniversariante = Aniversariante(
        id: 1,
        nome: 'João',
        dia: hoje.day,
        mes: hoje.month,
      );

      expect(aniversariante.eHoje, isTrue);
    });

    test('Formata data corretamente', () {
      final aniversariante = Aniversariante(
        nome: 'Maria',
        dia: 5,
        mes: 9,
      );

      expect(aniversariante.dataFormatada, equals('05/09'));
    });

    test('Formata mensagem de parabéns padrão', () {
      final aniversariante = Aniversariante(
        nome: 'Carlos',
        dia: 10,
        mes: 12,
      );

      expect(
        aniversariante.mensagemParabensFormatada,
        contains('Parabéns, Carlos!'),
      );
    });

    test('Calcula proximaData corretamente', () {
      final hoje = DateTime.now();
      final mesPassado = hoje.month == 1 ? 12 : hoje.month - 1;
      final anoEsperado = hoje.month == 1 ? hoje.year : hoje.year + 1;

      final aniversariante = Aniversariante(
        nome: 'Lucas',
        dia: 1,
        mes: mesPassado,
      );

      expect(aniversariante.proximaData.year, equals(anoEsperado));
    });
  });
}
