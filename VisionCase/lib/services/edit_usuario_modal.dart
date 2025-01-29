import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ModalEditarUsuario extends StatefulWidget {
  final int usuarioId;
  final String nome;
  final String email;
  final int? perfilId;
  final bool? ativoSn;
  final List<dynamic> perfis;
  final Function onUserUpdated;

  const ModalEditarUsuario({
    required this.usuarioId,
    required this.nome,
    required this.email,
    required this.perfilId,
    required this.ativoSn,
    required this.perfis,
    required this.onUserUpdated,
    Key? key,
  }) : super(key: key);

  @override
  _ModalEditarUsuarioState createState() => _ModalEditarUsuarioState();
}

class _ModalEditarUsuarioState extends State<ModalEditarUsuario> {
  late TextEditingController nomeController;
  late TextEditingController emailController;
  late bool ativo;
  late int? perfilSelecionado;
  bool _isLoading = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    nomeController = TextEditingController(text: widget.nome);
    emailController = TextEditingController(text: widget.email);
    // Aqui está a mudança principal
    ativo = widget.ativoSn == true; // Forçando a comparação booleana
    perfilSelecionado = widget.perfilId;
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
                // Barra superior com título e ícone de fechar
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
                        'Editar Usuário',
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
                // Conteúdo do formulário
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Campo Nome
                        _buildInputField(
                          controller: nomeController,
                          label: 'Nome',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),

                        // Campo Email
                        _buildInputField(
                          controller: emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                        ),
                        const SizedBox(height: 16),

                        // Dropdown Perfil
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonFormField<int>(
                            dropdownColor: Colors.white,
                            value: widget.perfis.any(
                                    (p) => p['id_perfil'] == perfilSelecionado)
                                ? perfilSelecionado
                                : null,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.badge_outlined,
                                  color: Colors.grey[600], size: 18),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                            hint: const Text('Selecione um perfil'),
                            onChanged: (int? newValue) {
                              setState(() {
                                perfilSelecionado = newValue;
                              });
                            },
                            items: () {
                              // Cria uma cópia da lista e ordena
                              var sortedPerfis =
                                  List<Map<String, dynamic>>.from(
                                      widget.perfis);
                              sortedPerfis.sort((a, b) =>
                                  (a['perfil'] as String)
                                      .compareTo(b['perfil'] as String));

                              return sortedPerfis
                                  .map<DropdownMenuItem<int>>((perfil) {
                                return DropdownMenuItem<int>(
                                  value: perfil['id_perfil'],
                                  child: Text(
                                    perfil['perfil'] ?? '',
                                    style: const TextStyle(fontSize: 14, fontFamily: 'Frutiger',),
                                  ),
                                );
                              }).toList();
                            }(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Switch de Ativo
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.toggle_on_outlined,
                                color: Colors.grey[600],
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              const Text('Status do usuário'),
                              const Spacer(),
                              Switch.adaptive(
                                value: ativo,
                                onChanged: (value) {
                                  setState(() {
                                    ativo = value;
                                // Para debug
                                  });
                                },
                                activeColor:
                                    const Color.fromRGBO(0, 114, 239, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botões de ação
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
                            backgroundColor:
                                const Color.fromRGBO(0, 114, 239, 1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.white, fontFamily: 'Frutiger',),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(0, 114, 239, 1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  // Faz a validação do email quando clicar em Salvar
                                  _validateEmail(emailController.text);
                                  if (_emailError != null) {
                                    // Se houver erro no email, mostra o SnackBar e não prossegue
                                    return;
                                  }
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  await _atualizarUsuario(
                                    widget.usuarioId,
                                    nomeController.text,
                                    emailController.text,
                                    ativo,
                                    perfilSelecionado,
                                  );
                                  widget.onUserUpdated();
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
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
                                  'Salvar',
                                  style: TextStyle(
                                    color: Colors.white,
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
        ));
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
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
          borderSide: const BorderSide(color: Color(0xFF1A237E)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Future<void> _atualizarUsuario(
    int usuarioId,
    String nome,
    String email,
    bool ativo,
    int? perfilId,
  ) async {
    // Valida o email antes de prosseguir
    _validateEmail(email);
    if (_emailError != null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token = sharedPreferences.getString('token');

    try {
      // Imprimir o body para debug
      final bodyData = {
        "nome": nome,
        "email": email,
        "ativado_sn":
            ativo, // Garantir que está enviando o valor booleano correto
        "id_perfil": perfilId,
      };
      // Para debug

      final response = await http.patch(
        Uri.parse(
          'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/user/$usuarioId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(bodyData),
      );

      if (response.statusCode != 200) {
  
        throw Exception('Erro ao atualizar usuário: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao atualizar usuário'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
