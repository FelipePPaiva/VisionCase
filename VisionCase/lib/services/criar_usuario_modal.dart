import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ModalCriarUsuario extends StatefulWidget {
  final List<dynamic> perfis; // Lista de perfis
  final Function onUserCreated; // Função a ser chamada após criar o usuário

  ModalCriarUsuario({
    required this.perfis,
    required this.onUserCreated,
  });

  @override
  _ModalCriarUsuarioState createState() => _ModalCriarUsuarioState();
}

class _ModalCriarUsuarioState extends State<ModalCriarUsuario> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _idPerfilController = TextEditingController();
  bool _isLoading = false;

  // Variáveis de controle para a complexidade da senha
  bool hasMinLength = false;
  bool hasUpperCase = false;
  bool hasLowerCase = false;
  bool hasNumber = false;
  bool hasSpecialChar = false;
  String? _emailError;

  // Variável para controle de erro no campo Nome
  String? _nomeError;

  // Função para verificar a complexidade da senha
  void _checkPasswordComplexity(String password) {
    setState(() {
      hasMinLength = password.length >= 10;
      hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      hasLowerCase = password.contains(RegExp(r'[a-z]'));
      hasNumber = password.contains(RegExp(r'[0-9]'));
      hasSpecialChar = password.contains(RegExp(r'[\W_]'));
    });
  }

  void _validateEmail(String email) {
    setState(() {
      if (email.isEmpty) {
        _emailError = 'O email não pode estar vazio';
      } else if (!email.contains('@')) {
        _emailError = 'Email inválido: deve conter @';
      } else if (!email.toLowerCase().endsWith('@zeiss.com')) {
        _emailError = 'Email inválido: deve ser um email @zeiss.com';
      } else {
        _emailError = null;
      }
    });
  }

  bool _isPasswordValid() {
    return hasMinLength &&
        hasUpperCase &&
        hasLowerCase &&
        hasNumber &&
        hasSpecialChar;
  }

  Future<void> _criarUsuario() async {
    // Validar se o campo Nome está vazio
    if (_nomeController.text.isEmpty) {
      setState(() {
        _nomeError = 'O nome não pode estar em branco.';
      });
      return;
    }

    // Validar email
    _validateEmail(_emailController.text);
    if (_emailError != null) {
      return; // Não prossegue se houver erro no email
    } else {
      setState(() {
        _nomeError = null; // Limpar a mensagem de erro se o nome estiver válido
      });
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      return;
    }

    // Ajuste do token para "Bearer <token>"
    token = token.replaceFirst("Token ", "");

    try {
      final response = await http.post(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/user/register'),
        //Uri.parse('http://localhost:3000/user/register'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nome': _nomeController.text,
          'email': _emailController.text,
          'senha': _senhaController.text,
          'id_perfil': int.tryParse(_idPerfilController.text) ?? 1,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        widget.onUserCreated();
        Navigator.of(context).pop();
      } else {
        // Tratamento para mensagens de erro
        try {
          final errorData = jsonDecode(response.body);

          // Verifica especificamente se o e-mail já existe
          if (response.statusCode == 422 &&
              errorData['message'] == 'Usuário já cadastrado.') {
            // Mostra um SnackBar ou um diálogo informando que o e-mail já está cadastrado
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Este e-mail já está cadastrado.'),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            // Outros erros

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorData['message'] ?? 'Erro ao criar usuário'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao processar a requisição'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Criar Usuário',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Frutiger',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Formulário
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputField(
                        controller: _nomeController,
                        label: 'Nome',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          error: _emailError,
                          onEditingComplete: () {
                            _validateEmail(_emailController.text);
                          }),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _senhaController,
                        label: 'Senha',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        onChanged: _checkPasswordComplexity,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonFormField<int>(
                          dropdownColor: Colors.white,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.badge_outlined,
                              color: Colors.grey[600],
                              size: 18,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Frutiger',
                            color: Colors.black,
                          ),
                          hint: const Text('Selecione um perfil'),
                          isExpanded: true,
                          items: () {
                            var sortedPerfis =
                                List<Map<String, dynamic>>.from(widget.perfis);
                            sortedPerfis.sort((a, b) => (a['perfil'] as String)
                                .compareTo(b['perfil'] as String));
                            return sortedPerfis
                                .map<DropdownMenuItem<int>>((perfil) {
                              return DropdownMenuItem<int>(
                                value: perfil['id_perfil'],
                                child: Text(
                                  perfil['perfil'],
                                  style: const TextStyle(fontSize: 14, fontFamily: 'Frutiger',),
                                ),
                              );
                            }).toList();
                          }(),
                          onChanged: (value) {
                            _idPerfilController.text = value?.toString() ?? '';
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordRules(),
                    ],
                  ),
                ),
              ),

              // Botões
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(0, 114, 239, 1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontSize: 16, fontFamily: 'Frutiger',),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(0, 114, 239, 1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: _isPasswordValid() && !_isLoading
                            ? () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                await _criarUsuario();
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            : null,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Criar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Frutiger',
                                  fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? error,
    Function(String)? onChanged,
    VoidCallback? onEditingComplete,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600], size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color.fromRGBO(0, 114, 239, 1)),
        ),
        errorText: error,
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildPasswordRules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requisitos da senha:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Frutiger',
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _buildRuleItem(hasMinLength, 'Pelo menos 10 caracteres'),
        _buildRuleItem(hasUpperCase, 'Pelo menos uma letra maiúscula'),
        _buildRuleItem(hasLowerCase, 'Pelo menos uma letra minúscula'),
        _buildRuleItem(hasNumber, 'Pelo menos um número'),
        _buildRuleItem(hasSpecialChar, 'Pelo menos um caractere especial'),
      ],
    );
  }

  Widget _buildRuleItem(bool conditionMet, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            conditionMet ? Icons.check_circle : Icons.cancel,
            color: conditionMet ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Frutiger',
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
