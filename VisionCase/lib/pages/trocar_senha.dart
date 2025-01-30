import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'senha_sucesso.dart';

class RedefinirSenhaPage extends StatefulWidget {
  final String email;
  final String pin;

  RedefinirSenhaPage({required this.email, required this.pin});

  @override
  _RedefinirSenhaPageState createState() => _RedefinirSenhaPageState();
}

class _RedefinirSenhaPageState extends State<RedefinirSenhaPage> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _novaSenhaVisivel = false;
  bool _confirmarSenhaVisivel = false;
  bool _isSenhaErro = false;
  bool _isConfirmarSenhaPreenchida = false;
  bool _mostrarModalSenha = false;
  bool _senhasNaoCorrespondem = false;

  //Validação de senha
  bool _temMinimoOitoCaracteres = false;
  bool _temLetraMaiusculaEMinuscula = false;
  bool _temCaractereEspecial = false;
  bool _senhasSaoIguais = false;
  bool _temMinimoDezCaracteres = false;
  bool _temNumero = false;

  @override
  void initState() {
    super.initState();
    _confirmarSenhaController.addListener(_atualizarEstadoBotao);
  }

  @override
  void dispose() {
    _removeOverlay();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _atualizarEstadoBotao() {
    setState(() {
      _isConfirmarSenhaPreenchida = _confirmarSenhaController.text.isNotEmpty;
    });
  }

  void _trocarVisibilidadeNovaSenha() {
    setState(() {
      _novaSenhaVisivel = !_novaSenhaVisivel;
    });
  }

  void _trocarVisibilidadeConfirmarSenha() {
    setState(() {
      _confirmarSenhaVisivel = !_confirmarSenhaVisivel;
    });
  }

  void _redefinirSenha() async {
    if (_novaSenhaController.text.isEmpty ||
        _confirmarSenhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos!")),
      );
      return;
    }

    if (_novaSenhaController.text != _confirmarSenhaController.text) {
      setState(() {
        _isSenhaErro = true; // Mostra o erro visualmente
      });
      return;
    }

    // Pegue o e-mail e o PIN da página
    final email = widget.email.toLowerCase();
    final pin = widget.pin;

    try {
      final response = await http.post(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/reset-password/confirm'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'novaSenha': _novaSenhaController.text,
          'pin': pin,
        }),
      );

      if (response.statusCode == 200) {
        // Se a requisição for bem-sucedida
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => SenhaSucessoPage()));
      } else {
        // Se ocorrer algum erro
      }
    } catch (e) {
      // Caso haja erro de conexão ou outro erro
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro na comunicação com o servidor!")),
      );
    }
  }

  void _validarSenha(String senha, String confirmarSenha) {
    setState(() {
      _temMinimoOitoCaracteres = senha.length >= 8;
      _temMinimoDezCaracteres = senha.length >= 10;
      _temLetraMaiusculaEMinuscula =
          senha.contains(RegExp(r'[A-Z]')) && senha.contains(RegExp(r'[a-z]'));
      _temNumero = senha.contains(RegExp(r'[0-9]'));
      _temCaractereEspecial = senha.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _senhasSaoIguais = senha == confirmarSenha;
      _senhasNaoCorrespondem = senha.isNotEmpty &&
          confirmarSenha.isNotEmpty &&
          senha != confirmarSenha;

      if (senha.isNotEmpty || confirmarSenha.isNotEmpty) {
        _mostrarModalSenha = true;
        _showValidationOverlay();
      } else {
        _mostrarModalSenha = false;
        _removeOverlay();
      }

      if (_senhasSaoIguais &&
          _temMinimoDezCaracteres &&
          _temLetraMaiusculaEMinuscula &&
          _temNumero &&
          _temCaractereEspecial) {
        _removeOverlay();
      }
    });
  }

  void _showValidationOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width *
            0.65, // Reduzido para 65% da largura da tela
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(0, 400),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color.fromRGBO(236, 240, 244, 1),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          // Adicionado Expanded para evitar overflow do texto
                          child: const Text(
                            "Sua senha deve incluir:",
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color.fromRGBO(53, 61, 69, 1),
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.black,
                            size: 12,
                          ),
                          onPressed: _removeOverlay,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Alinhamento à esquerda
                      children: [
                        _itemValidacao(
                            "No mínimo 10 caracteres", _temMinimoDezCaracteres),
                        _itemValidacao(
                            "Contém pelo menos um número", _temNumero),
                        _itemValidacao(
                            "No mínimo 8 caracteres", _temMinimoOitoCaracteres),
                        _itemValidacao("Letras maiúsculas e minúsculas",
                            _temLetraMaiusculaEMinuscula),
                        _itemValidacao("Pelo menos um caractere especial",
                            _temCaractereEspecial),
                        _itemValidacao(
                            "As senhas precisam ser iguais", _senhasSaoIguais),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _itemValidacao(String texto, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1), // Reduzido ainda mais
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Alinhamento vertical
        children: [
          Icon(
            isValid ? Icons.check_circle_outline : Icons.cancel_outlined, //
            color: isValid ? Colors.green : Colors.red,
            size: 14, // Reduzido o tamanho do ícone
          ),
          const SizedBox(width: 4), // Espaçamento reduzido
          Flexible(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                color: Color.fromRGBO(53, 61, 69, 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool eTablet = MediaQuery.of(context).size.width >= 768;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: eTablet ? const EdgeInsets.all(160) : const EdgeInsets.fromLTRB(32, 40, 32, 16),
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: Color.fromRGBO(0, 114, 239, 1),
                                size: eTablet ? 20 :16,
                              ),
                              hoverColor: Colors.transparent,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            Text(
                              "Definir nova senha",
                              style: TextStyle(
                                fontSize: eTablet ? 24 : 20,
                                fontFamily: 'Frutiger',
                                color: Color.fromRGBO(50, 55, 62, 1),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 24),
                            Text(
                              "Digite a nova senha que você deseja usar para sua conta.",
                              style: TextStyle(
                                fontSize: eTablet ? 20 : 14,
                                fontFamily: 'Frutiger',
                                fontWeight: FontWeight.w400,
                                color: Color.fromRGBO(50, 55, 62, 1),
                              ),
                            ),
                            const SizedBox(height: 59),
                            TextField(
                              controller: _novaSenhaController,
                              obscureText: !_novaSenhaVisivel,
                              style: const TextStyle(
                                color: Color.fromRGBO(96, 106, 118, 1),
                                fontSize: 16,
                                fontFamily: 'Frutiger',
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.5
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _mostrarModalSenha = value.isNotEmpty;
                                });
                                _validarSenha(
                                    value, _confirmarSenhaController.text);
                              },
                              decoration: InputDecoration(
                                labelText: "Senha",
                                filled: true,
                                hoverColor: Colors.transparent,
                                fillColor: _senhasNaoCorrespondem
                                    ? Color.fromRGBO(255, 0, 0, 0.1)
                                    : Colors
                                        .transparent, // Fundo vermelho claro quando há erro
                                labelStyle: TextStyle(
                                  color: _senhasNaoCorrespondem
                                      ? Colors.red
                                      : null,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _novaSenhaVisivel
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    size: 18,
                                  ),
                                  color: const Color.fromRGBO(194, 205, 214, 1),
                                  onPressed: _trocarVisibilidadeNovaSenha,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _senhasNaoCorrespondem
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _senhasNaoCorrespondem
                                        ? Colors.red
                                        : Color.fromRGBO(0, 114, 239, 1),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 84),
                            TextField(
                              controller: _confirmarSenhaController,
                              obscureText: !_confirmarSenhaVisivel,
                              style: const TextStyle(
                                color: Color.fromRGBO(96, 106, 118, 1),
                                fontSize: 16,
                                fontFamily: 'Frutiger',
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.5
                              ),
                              onChanged: (value) {
                                _validarSenha(_novaSenhaController.text, value);
                              },
                              decoration: InputDecoration(
                                labelText: "Confirmar senha",
                                filled: true,
                                fillColor: _senhasNaoCorrespondem
                                    ? Color.fromRGBO(255, 0, 0, 0.1)
                                    : Colors
                                        .transparent, // Fundo vermelho claro quando há err
                                hoverColor: Colors.transparent,
                                labelStyle: TextStyle(
                                  color: _senhasNaoCorrespondem
                                      ? Colors.red
                                      : null,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _confirmarSenhaVisivel
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    size: 18,
                                  ),
                                  color: const Color.fromRGBO(194, 205, 214, 1),
                                  onPressed: _trocarVisibilidadeConfirmarSenha,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _senhasNaoCorrespondem
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _senhasNaoCorrespondem
                                        ? Colors.red
                                        : Color.fromRGBO(0, 114, 239, 1),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 280),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _senhasSaoIguais
                                    ? () {
                                        _redefinirSenha();
                                      }
                                    : null,
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.resolveWith<Color>(
                                    (states) {
                                      if (states
                                          .contains(MaterialState.disabled)) {
                                        return const Color.fromRGBO(
                                            0, 114, 239, 0.4); // Cor desativada
                                      }
                                      return const Color.fromRGBO(
                                          0, 114, 239, 1); // Cor ativa
                                    },
                                  ),
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.white),
                                  padding:
                                      MaterialStateProperty.all<EdgeInsets>(
                                    const EdgeInsets.symmetric(
                                        vertical: 12), // Espaçamento interno
                                  ),
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        "Redefinir a senha",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Frutiger',
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      SizedBox(
                                          width:
                                              8), // Espaçamento entre texto e seta
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 18, // Tamanho da seta
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
