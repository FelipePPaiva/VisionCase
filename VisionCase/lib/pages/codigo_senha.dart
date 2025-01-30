import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'trocar_senha.dart';
import 'forgot_pass_page.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  EmailVerificationPage({required this.email});

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<bool> _isError =
      List.generate(6, (_) => false); // Estado de erro para cada campo
  int _remainingTime = 30;
  late final Timer _timer;
  bool _isResending = false;
  bool _isInvalidCode = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _remainingTime = 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isInvalidCode =
              false; // Adiciona esta linha para limpar a mensagem de erro
        });
        _clearCodeFields(); // Limpa os campos quando o tempo termina
      }
    });
  }

// Método para limpar os campos de código
  void _clearCodeFields() {
    setState(() {
      // Limpa o texto de cada controlador
      for (var controller in _controllers) {
        controller.clear();
      }
      // Reseta o estado de erro de todos os campos
      for (int i = 0; i < _isError.length; i++) {
        _isError[i] = false;
      }
    });
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
      _isInvalidCode = false; // Limpa a mensagem de erro ao reenviar o código
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/request-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email.toLowerCase()}),
      );

      if (response.statusCode == 200) {
        // Reseta todos os estados de erro e limpa os campos
        _resetCodeFieldsState(); // Adicione esta linha
        _startTimer(); // Reinicia o tempo de espera após reenvio bem-sucedido
      } else {
        _showSnackBar('Erro ao reenviar o código. Tente novamente.');
      }
    } catch (e) {
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

// Método para redefinir o estado dos campos de código
  void _resetCodeFieldsState() {
    for (int i = 0; i < _isError.length; i++) {
      _isError[i] = false; // Remove os erros dos campos
    }
    for (var controller in _controllers) {
      controller.clear(); // Limpa os campos
    }
  }

  Future<void> _validateCode() async {
    final code = _controllers.map((controller) => controller.text).join();

    try {
      final response = await http.post(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/validate-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email.toLowerCase(), 'pin': code}),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => RedefinirSenhaPage(
                      email: widget.email, // Passa o e-mail para a nova página
                      pin: code,
                    )));
      } else {
        setState(() {
          _isInvalidCode = true; // Marca o código como inválido
          for (int i = 0; i < _isError.length; i++) {
            _isError[i] = true; // Marca os campos como erro
          }
        });
      }
    } catch (e) {}
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildCodeField(int index) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: _controllers[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        // Adiciona os formatters para permitir apenas números
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: "",
          enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: _isError[index] ? Colors.red : Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: _isError[index] ? Colors.red : Colors.blue),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _isError[index] = false; // Remove o erro ao alterar o campo
          });

          if (value.isNotEmpty) {
            if (index < _controllers.length - 1) {
              FocusScope.of(context).nextFocus();
            } else {
              FocusScope.of(context).unfocus(); // Remove o foco do último campo
              _validateCode(); // Valida ao preencher o último campo
            }
          } else if (index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
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
                padding: eTablet
                    ? const EdgeInsets.fromLTRB(
                        190, 272, 160, 284) // Padding para iPad
                    : const EdgeInsets.fromLTRB(24, 40, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment
                          .topLeft, // Alinha o botão totalmente à esquerda
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: Color.fromRGBO(0, 114, 239, 1),
                                size: eTablet ? 20 : 16,
                              ),
                              hoverColor: Colors
                                  .transparent, // Remove o fundo cinza ao passar o mouse
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ForgotPasswordPage()),
                                );
                              },
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              "Verifique seu e-mail",
                              style: TextStyle(
                                  fontSize: eTablet ? 24 : 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Frutiger',
                                  color: Color.fromRGBO(50, 55, 62, 1)),
                            ),
                          ]),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            "Enviamos um código de verificação para ${widget.email.toLowerCase()}.",
                            style: TextStyle(
                              fontSize: eTablet ? 20 : 14,
                              fontFamily: 'Frutiger',
                              fontWeight: FontWeight.w400,
                              color: Color.fromRGBO(50, 55, 62, 1),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Insira o código para continuar",
                            style: TextStyle(
                              fontSize: eTablet ? 20 : 14,
                              fontFamily: 'Frutiger',
                              fontWeight: FontWeight.w400,
                              color: Color.fromRGBO(50, 55, 62, 1),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: List.generate(
                                          6,
                                          (index) => Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: eTablet
                                                    ? 55
                                                    : 45, // Largura fixa para cada campo
                                                child: _buildCodeField(index),
                                              ),
                                              if (index != 5)
                                                SizedBox(
                                                    width: eTablet ? 15 : 8),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_isInvalidCode)
                                      Container(
                                        width: (eTablet ? 50 : 40) * 6 +
                                            (eTablet ? 20 : 13) *
                                                5, // Calcula a largura total
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          'O código está incorreto',
                                          style: TextStyle(
                                            fontSize: eTablet ? 14 : 12,
                                            fontFamily: 'Frutiger',
                                            color:
                                                Color.fromRGBO(231, 30, 30, 1),
                                            fontWeight: FontWeight.w400,
                                          ),
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _remainingTime > 0
                              ? Text(
                                  "Aguarde $_remainingTime segundos para outro reenvio",
                                  style: TextStyle(
                                    fontSize: eTablet ? 16 : 14,
                                    fontFamily: 'Frutiger',
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromRGBO(96, 106, 118, 1),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    TextButton(
                                      onPressed:
                                          _isResending ? null : _resendCode,
                                      style: ButtonStyle(
                                        overlayColor: MaterialStateProperty.all(
                                            Colors.transparent),
                                        shape: MaterialStateProperty.all(
                                          RoundedRectangleBorder(
                                              borderRadius: BorderRadius.zero),
                                        ),
                                        padding: MaterialStateProperty.all(
                                            EdgeInsets.zero),
                                      ),
                                      child: _isResending
                                          ? const CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.blue),
                                            )
                                          : Text(
                                              "Reenviar código",
                                              style: TextStyle(
                                                color: Color.fromRGBO(
                                                    0, 114, 239, 1),
                                                fontFamily: 'Frutiger',
                                                fontSize: eTablet ? 16 : 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                    ),
                                    SizedBox(
                                      height: 8,
                                    ),
                                  ],
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
    );
  }
}
