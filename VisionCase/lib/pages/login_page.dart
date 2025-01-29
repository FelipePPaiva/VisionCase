import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'forgot_pass_page.dart';
import '../services/auth_services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //Validar os dados dos campos do Formulario
  final _formKey = GlobalKey<FormState>();

  //Controllers para tratamento dos inputs de email e senha
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  //Instacia do AutenticadorUser
  final AutenticacaoUser _autenticacaoUser = AutenticacaoUser();

  //Esconde a visualização da senha
  bool _verSenha = false;

  //Estado do botão
  bool _isButtonEnabled = false;

//Armazenar o estado do lembra-me
  bool _LembreMe = false;
  bool _emailValido = true;
  bool _senhaValida = true;
  String? _errorMessage;

  //Loading ao logar
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  //Valida os campos e atualiza o estado do botão
  void _validateForm() {
    setState(() {
      _isButtonEnabled = _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Verificamos se existe um refresh token válido
    String? refreshToken = prefs.getString('refreshToken');
    bool hasAutoLogin = prefs.getBool('lembreseDeMim') ?? false;

    if (refreshToken != null && hasAutoLogin) {
      setState(() {
        _emailController.text = prefs.getString('saved_email') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
        _LembreMe = true;
      });
    } else {
      setState(() {
        _emailController.text = '';
        _passwordController.text = '';
        _LembreMe = false;
      });
    }
  }

  Future<void> _saveUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    if (_LembreMe) {
      // Apenas atualiza o estado do lembre-me
      await prefs.setBool('lembreseDeMim', true);
    } else {
      // Limpa todos os dados salvos
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.remove('refreshToken');
      await prefs.setBool('lembreseDeMim', false);
    }
  }

  String? _validarEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      setState(() {
        _emailValido = false;
      });
      return "Por favor, insira seu e-mail";
    }

    final emailRegex = RegExp(r'^[^@]+@zeiss\.com$', caseSensitive: false);
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _emailValido = false;
      });
    }

    setState(() {
      _emailValido = true;
    });
    return null;
  }

  String? validarSenha(String? password) {
    if (password == null || password.isEmpty) {
      return "Por favor, insira sua senha";
    } else if (password.length < 10) {
      return "A senha deve ter pelo menos 10 caracteres";
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //Modal de problema no login
  void _showProblemaLogin() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        final bool eTablet = MediaQuery.of(context).size.width > 600;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(1.0),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: eTablet
                      ? MediaQuery.of(context).size.width * 0.90
                      : MediaQuery.of(context).size.width * 0.85,
                  padding: EdgeInsets.all(eTablet ? 56 : 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Problemas com o login?",
                        style: TextStyle(
                          fontSize: eTablet ? 24 : 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Frutiger',
                          height: 1.4,
                          color: Color.fromRGBO(50, 55, 62, 1),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Caso não consiga acessar sua conta, utilize a opção "Esqueci a senha" ou revise suas informações de login.',
                        style: TextStyle(
                            fontSize: eTablet ? 20 : 16,
                            fontFamily: 'Frutiger',
                            fontWeight: FontWeight.w400,
                            color: Color.fromRGBO(96, 106, 118, 1)),
                      ),
                      SizedBox(height: 16),
                      Wrap(
                        children: <Widget>[
                          Text(
                            "Persistindo o problema, entre em contato com o suporte: ",
                            style: TextStyle(
                                fontSize: eTablet ? 20 : 16,
                                fontFamily: 'Frutiger',
                                fontWeight: FontWeight.w400,
                                color: Color.fromRGBO(96, 106, 118, 1)),
                          ),
                          InkWell(
                            onTap: () async {
                              final Uri emailLaunchUri = Uri(
                                scheme: 'mailto',
                                path: 'comercial@zeiss.com',
                              );
                              if (await canLaunch(emailLaunchUri.toString())) {
                                await launch(emailLaunchUri.toString());
                              }
                            },
                            child: Text(
                              "comercial@zeiss.com",
                              style: TextStyle(
                                fontSize: eTablet ? 20 : 16,
                                fontFamily: 'Frutiger',
                                fontWeight: FontWeight.w500,
                                color: Color.fromRGBO(0, 114, 239, 1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: eTablet ? 32 : 24),
                      Container(
                        width: double.infinity,
                        child: eTablet
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                    SizedBox(
                                        width: 185,
                                        child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color.fromRGBO(
                                                  0, 114, 239, 1),
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                              minimumSize: Size(460, 48),
                                            ),
                                            child: Text(
                                              "Voltar para o login",
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: 'Frutiger',
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white),
                                            ))),
                                    SizedBox(
                                      width: 12,
                                    ),
                                    SizedBox(
                                      width: 185,
                                      child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ForgotPasswordPage(),
                                              ),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12),
                                            minimumSize: Size(0, 48),
                                            side: BorderSide(
                                              color: Color.fromRGBO(
                                                  0, 114, 239, 1),
                                              width: 1,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                          child: Text("Esqueci a senha",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontFamily: 'Frutiger',
                                                fontWeight: FontWeight.w500,
                                                color: Color.fromRGBO(
                                                    0, 114, 239, 1),
                                              ))),
                                    ),
                                  ])
                            : Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Color.fromRGBO(0, 114, 239, 1),
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      minimumSize: Size(double.infinity, 48),
                                    ),
                                    child: Text(
                                      "Voltar para o login",
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Frutiger',
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  ForgotPasswordPage()));
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      minimumSize: Size(double.infinity, 48),
                                      side: BorderSide(
                                        color: Color.fromRGBO(0, 114, 239, 1),
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    child: Text(
                                      "Esqueci a senha",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Frutiger',
                                        fontWeight: FontWeight.w500,
                                        color: Color.fromRGBO(0, 114, 239, 1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: -8,
                  top: -8,
                  child: IconButton(
                    icon: Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      elevation: 2,
                      padding: EdgeInsets.all(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //Mostra a tela inicial do Aplicativo
  @override
  Widget build(BuildContext context) {
    final Size tamanhoTela = MediaQuery.of(context).size;
    final bool eTablet = tamanhoTela.width > 600;
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: SingleChildScrollView(
                child: Container(
                    height:
                        tamanhoTela.height - MediaQuery.of(context).padding.top,
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 16),
                            //Row de Topo com Logo e nome
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Image.asset(
                                  'assets/images/logo-principal.png',
                                  width: eTablet ? 54 : 40,
                                  height: eTablet ? 54 : 40,
                                ),
                                SizedBox(width: 24),
                                Text('VisionCase',
                                    style: TextStyle(
                                      fontSize: eTablet ? 22 : 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Frutiger',
                                      color: Color.fromRGBO(50, 55, 62, 1),
                                      height: 1.2,
                                    ))
                              ],
                            ),
                            SizedBox(height: 24),
                            //Linha de separação do header para o conteudo
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: Offset(0, 2.0),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                          height: eTablet ? 180 : 32),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                            alignment:
                                eTablet ? Alignment.center : Alignment.topLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: eTablet ? 450 : double.infinity,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: eTablet
                                    ? MainAxisSize.min
                                    : MainAxisSize.max,
                                children: [
                                  Text(
                                    'Olá',
                                    style: TextStyle(
                                        fontSize: eTablet ? 24 : 20,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Frutiger',
                                        height: 1.4,
                                        color: Color.fromRGBO(50, 55, 62, 1)),
                                  ),
                                  SizedBox(height: eTablet ? 32 : 24),
                                  Text(
                                    'Acesse sua conta no VisionCase:',
                                    style: TextStyle(
                                        fontSize: eTablet ? 24 : 14,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'Frutiger',
                                        color: Color.fromRGBO(50, 55, 62, 1)),
                                  ),
                                  SizedBox(height: eTablet ? 67 : 51),

                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start, // Alinha à esquerda
                                          children: [
                                            TextFormField(
                                              controller: _emailController,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              style: TextStyle(
                                                fontSize: eTablet ? 20 : 16,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Frutiger',
                                                height: 1.5,
                                                color: Color.fromRGBO(
                                                    50, 55, 62, 1),
                                              ),
                                              decoration: InputDecoration(
                                                label: Text("E-mail"),
                                                filled: true,
                                                fillColor: _emailValido
                                                    ? Color.fromRGBO(
                                                        255, 255, 255, 1)
                                                    : const Color(0xFFFFE5E5),
                                                hoverColor: Colors
                                                    .transparent, // Fundo vermelho em erro
                                                focusedBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: _emailValido
                                                        ? Colors.blue
                                                        : Colors.red,
                                                    width: 2.0,
                                                  ),
                                                ),
                                                errorBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: Colors.red,
                                                    width: 2.0,
                                                  ),
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return "Por favor, insira seu e-mail";
                                                }
                                                final emailRegex = RegExp(
                                                    r'^[^@]+@zeiss\.com$',
                                                    caseSensitive: false);
                                                if (!emailRegex
                                                    .hasMatch(value)) {
                                                  return "Por favor, insira um e-mail ZEISS válido.";
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 65),
                                        //Validar se o campo senha está preenchido corretamente
                                        TextFormField(
                                          controller: _passwordController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          obscureText:
                                              !_verSenha, //Oculta a senha digitada
                                          style: TextStyle(
                                              fontSize: eTablet ? 20 : 16,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Frutiger',
                                              height: 1.5,
                                              letterSpacing: 1.5,
                                              color: Color.fromRGBO(
                                                  50, 55, 62, 1)),
                                          decoration: InputDecoration(
                                            label: Text("Senha"),
                                            filled: true,
                                            fillColor: _senhaValida
                                                ? Colors.white
                                                : const Color(0xFFFFE5E5),
                                            hoverColor: Colors.transparent,
                                            focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                              color: _senhaValida
                                                  ? Colors.blue
                                                  : Colors.red,
                                              width: 2.0,
                                            )),
                                            errorBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                              color: Colors.red,
                                              width: 2.0,
                                            )),
                                            suffixIcon: IconButton(
                                                icon: Icon(
                                                  _verSenha
                                                      ? Icons
                                                          .visibility_outlined
                                                      : Icons
                                                          .visibility_off_outlined,
                                                  size: 18,
                                                ),
                                                color: Color.fromRGBO(
                                                    194, 205, 214, 1),
                                                hoverColor: Colors.transparent,
                                                onPressed: () {
                                                  setState(() {
                                                    _verSenha = !_verSenha;
                                                  });
                                                }),
                                          ),
                                          validator: validarSenha,
                                        ),

                                        SizedBox(height: 2),
                                        Align(
                                          alignment: Alignment
                                              .centerRight, //Alinha o texto a direita
                                          child: InkWell(
                                            hoverColor: Colors.transparent,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        ForgotPasswordPage()),
                                              );
                                            },
                                            child: Text(
                                              "Esqueceu a senha?",
                                              style: TextStyle(
                                                  color: Color.fromRGBO(
                                                      0, 114, 239, 1),
                                                  fontSize: eTablet ? 16 : 12,
                                                  fontFamily: 'Frutiger',
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: 0.5,
                                                  height: 1.5),
                                            ),
                                          ),
                                        ),
                                        if (_errorMessage != null) ...[
                                          SizedBox(height: 16),
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Color.fromRGBO(
                                                  236, 240, 244, 1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _errorMessage!,
                                              style: TextStyle(
                                                color: Color.fromRGBO(
                                                    96, 106, 118, 1),
                                                fontSize: eTablet ? 16 : 14,
                                                fontFamily: 'Frutiger',
                                                height: 1.5,
                                                fontWeight: FontWeight.w400,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  //Sessão para digitar usuário e senha

                                  SizedBox(height: 40),

                                  Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Checkbox(
                                            value: _LembreMe,
                                            hoverColor: Colors.transparent,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                _LembreMe = value ?? false;
                                              });
                                            },
                                            activeColor:
                                                Color.fromRGBO(0, 114, 239, 1),
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            "Lembre-se de mim",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontSize: eTablet ? 16 : 14,
                                                fontFamily: 'Frutiger',
                                                height: 1.5,
                                                letterSpacing: 0.5),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 28),

                                  Center(
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateProperty
                                                      .resolveWith<Color>(
                                                (states) {
                                                  if (states.contains(
                                                      MaterialState.disabled)) {
                                                    return Color.fromRGBO(
                                                        0,
                                                        114,
                                                        239,
                                                        0.4); // Cor desativada com opacidade
                                                  }
                                                  return Color.fromRGBO(0, 114,
                                                      239, 1); // Cor ativada
                                                },
                                              ),
                                              foregroundColor:
                                                  MaterialStateProperty
                                                      .all<Color>(Colors
                                                          .white), // Cor do texto
                                              padding: MaterialStateProperty
                                                  .all<EdgeInsets>(
                                                const EdgeInsets.fromLTRB(
                                                    74.5, 12, 74.5, 12),
                                              ),
                                              shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                              ),
                                            ),
                                            onPressed: _isButtonEnabled
                                                ? () async {
                                                    setState(() {
                                                      _isLoading = true;
                                                      _errorMessage = null;
                                                    });

                                                    if (_formKey.currentState!
                                                        .validate()) {
                                                      try {
                                                        String? errorMessage =
                                                            await _autenticacaoUser
                                                                .logar(
                                                          _emailController.text
                                                              .toLowerCase(),
                                                          _passwordController
                                                              .text,
                                                          _LembreMe,
                                                          context,
                                                        );

                                                        if (!mounted) return;

                                                        setState(() {
                                                          _isLoading = false;
                                                          if (errorMessage !=
                                                              null) {
                                                            _emailValido =
                                                                false; // Atualiza o estado visual do campo
                                                            _senhaValida =
                                                                false; // Atualiza o estado visual do campo
                                                            _errorMessage =
                                                                errorMessage;
                                                          } else {
                                                            _emailValido = true;
                                                            _senhaValida = true;
                                                            _errorMessage =
                                                                null;
                                                          }
                                                        });

                                                        if (errorMessage ==
                                                                null &&
                                                            _LembreMe) {
                                                          await _saveUserPreferences();
                                                        }
                                                      } catch (e) {
                                                        if (!mounted) return;
                                                        setState(() {
                                                          _isLoading = false;
                                                          _emailValido = false;
                                                          _senhaValida = false;
                                                          _errorMessage =
                                                              "Ocorreu um erro ao tentar fazer login. Tente novamente.";
                                                        });
                                                      }
                                                    } else {
                                                      setState(() {
                                                        _isLoading = false;
                                                        _emailValido = false;
                                                        _senhaValida = false;
                                                      });
                                                    }
                                                  }
                                                : null,
                                            child: _isLoading
                                                ? SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : Text(
                                                    "Entrar em VisionCase",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontFamily: 'Frutiger',
                                                      fontSize: 16,
                                                      height: 1.5,
                                                    ),
                                                  ),
                                          ),
                                          SizedBox(height: 8),
                                          SizedBox(
                                            width: 300,
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: InkWell(
                                                hoverColor: Colors.transparent,
                                                onTap: _showProblemaLogin,
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.info_outline,
                                                      size: 12,
                                                      color: Color.fromRGBO(
                                                          0, 114, 239, 1),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      "Problemas com o login?",
                                                      style: TextStyle(
                                                          color: Color.fromRGBO(
                                                              0, 114, 239, 1),
                                                          fontSize:  eTablet ? 14 : 12,
                                                          fontFamily:
                                                              'Frutiger',
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          height: 1.5,
                                                          letterSpacing: 0.5),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ]),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    ])))));
  }
}
