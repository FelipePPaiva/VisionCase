import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/edit_usuario_modal.dart';
import '../services/criar_usuario_modal.dart';

class UsuarioPage extends StatefulWidget {
  const UsuarioPage({super.key});

  @override
  State<UsuarioPage> createState() => _UsuarioPageState();
}

class _UsuarioPageState extends State<UsuarioPage> {
  List<dynamic> _usuarios = [];
  List<dynamic> _perfis = [];
  List<dynamic> _usuariosFiltrados = [];
  bool _isLoading = true;
  String _message = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    validarAcesso();
    buscarPerfis();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarUsuarios(String query) {
    setState(() {
      if (query.isEmpty) {
        _usuariosFiltrados = List.from(_usuarios);
      } else {
        _usuariosFiltrados = _usuarios.where((usuario) {
          final nome = usuario['nome']?.toString().toLowerCase() ?? '';
          final email = usuario['email']?.toString().toLowerCase() ?? '';
          final perfil =
              usuario['perfil']?['perfil']?.toString().toLowerCase() ?? '';
          return nome.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase()) ||
              perfil.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> validarAcesso() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token = sharedPreferences.getString('token');

    try {
      final response = await http.get(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['users'] != null && data['users'].isNotEmpty) {
          setState(() {
            _usuarios = data['users'];
            _usuariosFiltrados = List.from(_usuarios);
            _isLoading = false;
          });
        } else {
          throw Exception('Nenhum usuário encontrado.');
        }
      } else {
        throw Exception('Usuário não tem permissão para acessar');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Erro ao buscar usuários: $e';
      });
    }
  }

  Future<void> buscarUsuarios() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token = sharedPreferences.getString('token');

    try {
      final response = await http.get(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _usuarios = data['users'];
          _usuariosFiltrados = List.from(_usuarios);
        });
      } else {
        throw Exception('Erro ao buscar usuários: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _message = 'Erro ao buscar usuários: $e';
      });
    }
  }

  Future<void> buscarPerfis() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token = sharedPreferences.getString('token');

    try {
      final response = await http.get(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/profiles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _perfis = data['profiles'];
        });
      } else {
        throw Exception('Erro ao buscar perfis: ${response.statusCode}');
      }
    } catch (e) {}
  }

  Future<void> _abrirModalEdicao(int usuarioId, String nome, String email,
      int? perfilId, bool? ativoSn) async {
    await showDialog(
      context: context,
      builder: (context) {
        return ModalEditarUsuario(
          usuarioId: usuarioId,
          nome: nome,
          email: email,
          perfilId: perfilId,
          ativoSn: ativoSn,
          perfis: _perfis,
          onUserUpdated: () async {
            await buscarUsuarios();
          },
        );
      },
    );
  }

  Future<void> _confirmarExclusao(Map<String, dynamic> usuario) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 18),
                  const SizedBox(width: 12),
                  Text(
                    'Excluir Usuário',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Frutiger',
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Tem certeza que deseja excluir o usuário ${usuario['nome']}?',
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Frutiger',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Botões
            Padding(
              padding: const EdgeInsets.all(16),
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
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deletarUsuario(usuario['id_usuario']);
                      },
                      child: const Text(
                        'Excluir',
                        style: TextStyle(fontSize: 16, fontFamily: 'Frutiger',),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletarUsuario(int usuarioId) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token = sharedPreferences.getString('token');

    try {
      final response = await http.delete(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/user/$usuarioId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _usuarios
              .removeWhere((usuario) => usuario['id_usuario'] == usuarioId);
          _usuariosFiltrados = List.from(_usuarios);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Usuário excluído com sucesso!',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Frutiger',
                  fontSize: 16,
                ),
              ),
              backgroundColor: const Color.fromRGBO(0, 114, 239, 1),
            ),
          );
        }
      } else {
        throw Exception('Erro ao excluir usuário: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _message = 'Erro ao excluir usuário: $e';
      });
    }
  }

  String _getIniciais(String nome) {
    List<String> partes = nome.split(' ');
    return partes
        .where((parte) => parte.isNotEmpty)
        .map((parte) => parte[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  String _formatarData(String? data) {
    if (data == null) return 'Data não disponível';
    try {
      DateTime dateTime = DateTime.parse(data);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return 'Data inválida';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 114, 239, 1),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _message.isNotEmpty
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _message,
                      style: TextStyle(color: Colors.red.shade700, fontFamily: 'Frutiger',),
                    ),
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        title: const Text(
                          'Gerenciamento de Usuários',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Frutiger',
                            fontSize: 20,
                          ),
                        ),
                        centerTitle: false,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filtrarUsuarios,
                          style: const TextStyle(color: Colors.black, fontFamily: 'Frutiger',),
                          decoration: InputDecoration(
                            hintText: 'Buscar usuários...',
                            hintStyle: TextStyle(color: Colors.grey[600],fontFamily: 'Frutiger',),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Card(
                                elevation: 1,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return ModalCriarUsuario(
                                          perfis: _perfis,
                                          onUserCreated: () async {
                                            await buscarUsuarios();
                                          },
                                        );
                                      },
                                    );
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Color(0xFFE3F2FD),
                                          child: Icon(
                                            Icons.add,
                                            color:
                                                Color.fromRGBO(0, 114, 239, 1),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Text(
                                          'Adicionar Usuário',
                                          style: TextStyle(
                                            color:
                                                Color.fromRGBO(0, 114, 239, 1),
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Frutiger',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              ..._usuariosFiltrados.map((usuario) {
                                final nome =
                                    usuario['nome'] ?? 'Nome não disponível';
                                final email =
                                    usuario['email'] ?? 'Email não disponível';
                                final perfil = usuario['perfil'] != null
                                    ? usuario['perfil']['perfil'] ??
                                        'Perfil não disponível'
                                    : 'Perfil não disponível';
                                final ativo = usuario['ativado_sn'] ?? false;

                                return Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFFE3F2FD),
                                      child: Text(
                                        _getIniciais(nome),
                                        style: const TextStyle(
                                          color: Color.fromRGBO(0, 114, 239, 1),
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Frutiger',
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      nome,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Frutiger',
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(email),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.badge_outlined,
                                              size: 16,
                                              color: Color.fromRGBO(
                                                  0, 114, 239, 1),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                perfil,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontFamily: 'Frutiger',
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.circle,
                                              size: 8,
                                              color: ativo
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              ativo ? 'Ativo' : 'Inativo',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontFamily: 'Frutiger',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_outlined,
                                              size: 16,
                                              color: Color.fromRGBO(
                                                  0, 114, 239, 1),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Último acesso: ${_formatarData(usuario['ultimo_acesso'])}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontFamily: 'Frutiger',
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: Color.fromRGBO(0, 114, 239, 1),
                                      ),
                                      itemBuilder: (context) => [
                                        if (usuario['perfil']['id_perfil'] != 1)
                                          PopupMenuItem(
                                            child: const ListTile(
                                              leading:
                                                  Icon(Icons.edit_outlined),
                                              title: Text('Editar'),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            onTap: () {
                                              Future.delayed(
                                                const Duration(seconds: 0),
                                                () => _abrirModalEdicao(
                                                  usuario['id_usuario'],
                                                  nome,
                                                  email,
                                                  usuario['perfil']
                                                      ['id_perfil'],
                                                  usuario['ativado_sn'],
                                                ),
                                              );
                                            },
                                          ),
                                        PopupMenuItem(
                                          child: const ListTile(
                                            leading: Icon(
                                              Icons.delete_outline,
                                            ),
                                            title: Text(
                                              'Excluir',
                                            ),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onTap: () {
                                            Future.delayed(
                                              const Duration(seconds: 0),
                                              () => _confirmarExclusao(usuario),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final double? iconSize;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize ?? 16,
            color: color ?? Colors.blue,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color ?? Colors.blue,
                fontSize: 12,
                fontFamily: 'Frutiger',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
