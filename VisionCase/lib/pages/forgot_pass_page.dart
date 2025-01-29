import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'codigo_senha.dart';
import 'login_page.dart';
import '../services/tela_loading.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailValido = true;
  bool _isButtonEnabled = false;
  String? _mensagemErro;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_checkEmailValidity);
  }

  void _checkEmailValidity() {
    String email = _emailController.text;
    setState(() {
      _isButtonEnabled = email.isNotEmpty;
    });
  }

  String? _validarEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      // Caso o campo esteja vazio
      setState(() {
        _emailValido = false;
        _mensagemErro = "Por favor, insira seu e-mail.";
      });
      return "";
    }

    // Verificar se o e-mail termina com @zeiss.com
    if (!email.toLowerCase().endsWith('@zeiss.com')) {
      setState(() {
        _emailValido = false;
        _mensagemErro = "";
      });
      return "Por favor, insira um e-mail ZEISS válido.";
    }

    // Caso o e-mail seja válido
    setState(() {
      _emailValido = true;
      _mensagemErro = null; // Sem mensagens de erro
    });
    return null;
  }

  Future<void> _enviarCodigoDeRecuperacao() async {
    // Mostra a tela de loading
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingScreen(),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/request-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.toLowerCase()}),
      );

      // Importante: Verifica se o widget ainda está montado
      if (!mounted) return;

      // Remove a tela de loading
      Navigator.pop(context);

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationPage(
              email: _emailController.text,
            ),
          ),
        );
      } else if (response.statusCode == 404) {
        setState(() {
          _emailValido = false;
          _mensagemErro = 'E-mail Inválido.';
        });
      } else {
        setState(() {
          _emailValido = false;
          _mensagemErro = 'Ocorreu um erro. Tente novamente.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      // Remove a tela de loading em caso de erro
      Navigator.pop(context);

      setState(() {
        _emailValido = false;
        _mensagemErro =
            'Erro de conexão. Verifique sua internet e tente novamente.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color.fromRGBO(0, 114, 239, 1),
                          size: 16,
                        ),
                        hoverColor: Colors.transparent,
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                          );
                        },
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      const Text(
                        "Esqueci a senha",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Frutiger',
                            color: Color.fromRGBO(50, 55, 62, 1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Informe seu e-mail:",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Frutiger',
                                height: 1.5,
                                color: Color.fromRGBO(50, 55, 62, 1)),
                          ),
                          const SizedBox(height: 59),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Frutiger',
                                height: 1.5,
                                color: Color.fromRGBO(50, 55, 62, 1)),
                            decoration: InputDecoration(
                              hoverColor: Colors.transparent,
                              label: const Text("E-mail"),
                              filled: true,
                              fillColor: _emailValido
                                  ? const Color.fromRGBO(255, 255, 255, 1)
                                  : const Color(0xFFFFE5E5),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color:
                                      _emailValido ? Colors.blue : Colors.red,
                                  width: 2.0,
                                ),
                              ),
                              errorBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: 2.0,
                                ),
                              ),
                            ),
                            validator: _validarEmail,
                          ),
                          if (_mensagemErro !=
                              null) // Condicional para exibir apenas uma mensagem de erro
                            Padding(
                              padding: const EdgeInsets.only(top: 0),
                              child: Text(
                                _mensagemErro!,
                                style: const TextStyle(
                                    color: Color.fromRGBO(231, 30, 30, 1),
                                    fontSize: 12,
                                    fontFamily: 'Frutiger'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 380),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isButtonEnabled
                          ? () {
                              if (_formKey.currentState?.validate() ?? false) {
                                _enviarCodigoDeRecuperacao();
                              }
                            }
                          : null,
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(MaterialState.disabled)) {
                              return const Color.fromRGBO(0, 114, 239, 0.4);
                            }
                            return const Color.fromRGBO(0, 114, 239, 1);
                          },
                        ),
                        foregroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                        padding: MaterialStateProperty.all<EdgeInsets>(
                          const EdgeInsets.fromLTRB(34, 14, 34, 14),
                        ),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24, height: 24, child: LoadingScreen())
                          : FittedBox(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Flexible(
                                    child: Text(
                                      "Enviar código de recuperação",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Frutiger'),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_sharp,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )),
    );
  }
}
