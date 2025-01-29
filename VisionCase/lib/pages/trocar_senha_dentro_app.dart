import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'senha_sucesso_dentro_app.dart';

class AlterarSenhaPage extends StatefulWidget {
  @override
  _AlterarSenhaPageState createState() => _AlterarSenhaPageState();
}

class _AlterarSenhaPageState extends State<AlterarSenhaPage> {
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _overlayVisivel = false;
  bool _botaoHabilitado = false;
  bool _senhaAtualValida = false;
  bool _senhaAtualErrada = false;

  bool _senhaAtualVisivel = false;
  bool _novaSenhaVisivel = false;
  bool _confirmarSenhaVisivel = false;

  @override
  void initState() {
    super.initState();
    // Adiciona listeners para todos os campos
    _senhaAtualController.addListener(_verificarCampos);
    _novaSenhaController.addListener(_verificarCampos);
    _confirmarSenhaController.addListener(_verificarCampos);
  }

  @override
  void dispose() {
    // Remove os listeners antes de dispor os controllers
    _senhaAtualController.removeListener(_verificarCampos);
    _novaSenhaController.removeListener(_verificarCampos);
    _confirmarSenhaController.removeListener(_verificarCampos);

    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  void _mostrarOverlay() {
    setState(() {
      _overlayVisivel = true;
    });
  }

  void _fecharOverlay() {
    setState(() {
      _overlayVisivel = false;
    });
  }

  void _verificarSenhaAtual() {
    setState(() {
      // Aqui você pode adicionar sua própria lógica de validação
      _senhaAtualValida = _senhaAtualController.text.length >= 8;

      // Se a senha atual for limpa, limpa também os outros campos
      if (_senhaAtualController.text.isEmpty) {
        _novaSenhaController.clear();
        _confirmarSenhaController.clear();
        _senhaAtualValida = false;
      }
    });
    _verificarCampos();
  }

  void _verificarCampos() {
    setState(() {
      // Verifica se a senha atual é válida
      _senhaAtualValida = _senhaAtualController.text.length >= 8;

      // Se a senha atual for limpa, limpa os outros campos
      if (_senhaAtualController.text.isEmpty) {
        _novaSenhaController.clear();
        _confirmarSenhaController.clear();
        _senhaAtualValida = false;
      }

      // Verifica se todos os critérios são atendidos para habilitar o botão
      _botaoHabilitado = _senhaAtualValida &&
          _novaSenhaController.text.isNotEmpty &&
          _confirmarSenhaController.text.isNotEmpty &&
          _novaSenhaController.text == _confirmarSenhaController.text;

      // Mostra o overlay se estiver digitando a nova senha
      if (_senhaAtualValida &&
          (_novaSenhaController.text.isNotEmpty ||
              _confirmarSenhaController.text.isNotEmpty)) {
        _overlayVisivel = true;
      }
    });
  }

  Future<void> _alterarSenha() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: Token JWT não encontrado.')),
      );
      return;
    }

    final url = Uri.parse(
        'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/change-password');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'senha': _senhaAtualController.text,
        'novaSenha': _novaSenhaController.text,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => SenhaSucessoAppPage()));
    } else {
      setState(() {
        _senhaAtualErrada = true; // Marca a senha como errada
      });
      final error = jsonDecode(response.body)['message'] ?? 'Erro ao alterar senha';
    }
  }

  Widget _buildSenhaAtual() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _senhaAtualController,
          decoration: InputDecoration(
            labelText: 'Senha atual',
            labelStyle: TextStyle(
              fontSize: 12,
              fontFamily: 'Frutiger',
              fontWeight: FontWeight.w400,
              color: _senhaAtualErrada ? Colors.red : null,
            ),
            filled: true,
            fillColor: _senhaAtualErrada
                ? Colors.red.withOpacity(0.1)
                : Colors.transparent,
            border: UnderlineInputBorder(
              borderSide: BorderSide(
                color: _senhaAtualErrada ? Colors.red : Colors.grey,
              ),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: _senhaAtualErrada ? Colors.red : Colors.grey,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: _senhaAtualErrada ? Colors.red : Color.fromRGBO(0, 114, 239, 1),
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _senhaAtualVisivel ? Icons.visibility : Icons.visibility_off,
                size: 16,
                color: _senhaAtualErrada ? Colors.red : Color.fromRGBO(194, 205, 214, 1),
              ),
              hoverColor: Colors.transparent,
              onPressed: () {
                setState(() {
                  _senhaAtualVisivel = !_senhaAtualVisivel;
                });
              },
            ),
          ),
          style: TextStyle(
            color: _senhaAtualErrada ? Colors.red : null,
          ),
          obscureText: !_senhaAtualVisivel,
          onChanged: (value) {
            if (_senhaAtualErrada) {
              setState(() {
                _senhaAtualErrada = false;
              });
            }
            _verificarCampos();
          },
        ),
        if (_senhaAtualErrada) ...[
          SizedBox(height: 8), // Espaço entre o campo e a mensagem
          Text(
            'Senha incorreta',
            style: TextStyle(
              color: Colors.red,
              fontFamily: 'Frutiger',
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNovaSenha() {
    return TextField(
      controller: _novaSenhaController,
      enabled: _senhaAtualValida,
      decoration: InputDecoration(
        labelText: 'Nova senha',
        labelStyle: TextStyle(
          fontSize: 12,
          fontFamily: 'Frutiger',
          fontWeight: FontWeight.w400,
          color: _senhaAtualValida ? null : Color.fromRGBO(194, 205, 214, 1),
        ),
        border: UnderlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _novaSenhaVisivel ? Icons.visibility : Icons.visibility_off,
            size: 16,
            color: Color.fromRGBO(194, 205, 214, 1),
          ),
          hoverColor: Colors.transparent,
          onPressed: _senhaAtualValida
              ? () {
                  setState(() {
                    _novaSenhaVisivel = !_novaSenhaVisivel;
                  });
                }
              : null,
        ),
      ),
      obscureText: !_novaSenhaVisivel,
    );
  }

  Widget _buildConfirmarSenha() {
    return TextField(
      controller: _confirmarSenhaController,
      enabled: _senhaAtualValida,
      decoration: InputDecoration(
        labelText: 'Confirmar senha',
        labelStyle: TextStyle(
          fontSize: 12,
          fontFamily: 'Frutiger',
          fontWeight: FontWeight.w400,
          color: _senhaAtualValida ? null : Color.fromRGBO(194, 205, 214, 1),
        ),
        border: UnderlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _confirmarSenhaVisivel ? Icons.visibility : Icons.visibility_off,
            size: 16,
            color: Color.fromRGBO(194, 205, 214, 1),
          ),
          hoverColor: Colors.transparent,
          onPressed: _senhaAtualValida
              ? () {
                  setState(() {
                    _confirmarSenhaVisivel = !_confirmarSenhaVisivel;
                  });
                }
              : null,
        ),
      ),
      obscureText: !_confirmarSenhaVisivel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Padding(
          padding: const EdgeInsets.only(top: 32.0), // Espaçamento inferior
          child: Text(
            'Alteração de senha',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Frutiger',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(top: 30.0), // Espaçamento inferior
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              size: 16,
              color: Color.fromRGBO(0, 114, 239, 1),
            ),
            hoverColor:
                Colors.transparent, // Remove o fundo cinza ao passar o mouse
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 35),
              _buildSenhaAtual(),
              SizedBox(height: 68),
              _buildNovaSenha(),
              SizedBox(height: 68),
              _buildConfirmarSenha(),
              SizedBox(height: 22),
              if (_overlayVisivel)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(236, 240, 244, 1),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sua senha deve incluir:'),
                            SizedBox(height: 8),
                            _buildValidationItem('No mínimo 8 caracteres;',
                                _novaSenhaController.text.length >= 8),
                            _buildValidationItem(
                                'Letras maiúsculas e minúsculas;',
                                _novaSenhaController.text.contains(RegExp(r'[A-Z]')) &&
                                    _novaSenhaController.text.contains(RegExp(r'[a-z]'))),
                            _buildValidationItem(
                                'Pelo menos um caractere especial;',
                                _novaSenhaController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))),
                            _buildValidationItem(
                                'As senhas precisam ser iguais;',
                                _novaSenhaController.text == _confirmarSenhaController.text),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _fecharOverlay,
                          child: Icon(
                            Icons.close,
                            color: Colors.black,
                            size: 16,
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _botaoHabilitado ? _alterarSenha : null,
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (states) {
                if (states.contains(MaterialState.disabled)) {
                  return const Color.fromRGBO(0, 114, 239, 0.4); // Cor desativada
                }
                return const Color.fromRGBO(0, 114, 239, 1); // Cor ativa
              },
            ),
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            padding: MaterialStateProperty.all<EdgeInsets>(
              const EdgeInsets.symmetric(vertical: 12), // Espaçamento interno
            ),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
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
                  ),
                ),
                SizedBox(width: 8), // Espaçamento entre texto e seta
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
    );
  }

  Widget _buildValidationItem(String text, bool valid) {
    return Row(
      children: [
        Icon(
          valid ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: valid ? Colors.green : Colors.red,
          size: 20,
        ),
        SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
