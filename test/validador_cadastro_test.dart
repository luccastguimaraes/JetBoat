import 'package:flutter_test/flutter_test.dart';
import 'package:jetboat/domain/conta/validador_cadastro.dart';

void main() {
  // Data fixa para os testes não dependerem do dia em que rodam
  final hoje = DateTime(2026, 11, 10);

  const camposValidos = CamposCadastro(
    nome: 'Maria da Silva',
    cpf: '52998224725',
    dataNascimento: '15031990',
    telefone: '11987654321',
    email: 'maria@email.com',
    senha: 'Barco2026',
    confirmacaoSenha: 'Barco2026',
    aceitouTermos: true,
  );

  test('formulário completo é válido', () {
    expect(ValidadorCadastro.validar(camposValidos, hoje: hoje).valido, isTrue);
  });

  test('formulário vazio tem erro em todos os campos', () {
    final e = ValidadorCadastro.validar(const CamposCadastro(), hoje: hoje);
    expect(e.valido, isFalse);
    for (final erro in [e.nome, e.cpf, e.dataNascimento, e.telefone, e.email, e.senha, e.confirmacaoSenha, e.termos]) {
      expect(erro, isNotNull);
    }
  });

  test('CPF', () {
    expect(ValidadorCadastro.cpf('52998224725'), isNull);
    expect(ValidadorCadastro.cpf('52998224724'), 'CPF inválido'); // dígito verificador errado
    expect(ValidadorCadastro.cpf('11111111111'), 'CPF inválido'); // todos iguais
    expect(ValidadorCadastro.cpf('5299822'), 'CPF incompleto');
  });

  test('data de nascimento', () {
    expect(ValidadorCadastro.dataNascimento('10112008', hoje: hoje), isNull); // faz 18 hoje
    expect(ValidadorCadastro.dataNascimento('11112008', hoje: hoje), 'É preciso ter 18 anos ou mais');
    expect(ValidadorCadastro.dataNascimento('31022000', hoje: hoje), 'Data inválida');
    expect(ValidadorCadastro.dataNascimento('29022000', hoje: hoje), isNull); // ano bissexto
    expect(ValidadorCadastro.dataNascimento('29022001', hoje: hoje), 'Data inválida');
    expect(ValidadorCadastro.dataNascimento('01012030', hoje: hoje), 'Data no futuro');
    expect(ValidadorCadastro.dataNascimento('0101', hoje: hoje), 'Data incompleta');
  });

  test('telefone', () {
    expect(ValidadorCadastro.telefone('11987654321'), isNull);
    expect(ValidadorCadastro.telefone('1133334444'), isNull); // fixo
    expect(ValidadorCadastro.telefone('11887654321'), 'Celular deve começar com 9');
    expect(ValidadorCadastro.telefone('01987654321'), 'DDD inválido');
    expect(ValidadorCadastro.telefone('1198765'), 'Telefone incompleto');
  });

  test('e-mail e senha', () {
    expect(ValidadorCadastro.email('joao.silva@empresa.com.br'), isNull);
    expect(ValidadorCadastro.email('joao@'), 'E-mail inválido');
    expect(ValidadorCadastro.senha('abc123'), 'Mínimo de 8 caracteres');
    expect(ValidadorCadastro.senha('somenteletras'), 'Use letras e números');
    expect(ValidadorCadastro.confirmacaoSenha('Barco2026', 'Barco2025'), 'As senhas não conferem');
  });

  test('nome', () {
    expect(ValidadorCadastro.nome("João D'Ávila"), isNull);
    expect(ValidadorCadastro.nome('João'), 'Informe nome e sobrenome');
    expect(ValidadorCadastro.nome('João 123'), 'Use apenas letras');
  });

  test('força da senha', () {
    expect(ValidadorCadastro.forcaSenha(''), 0);
    expect(ValidadorCadastro.forcaSenha('Barco#2026'), 4);
  });
}
