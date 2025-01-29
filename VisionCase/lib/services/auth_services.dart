import 'dart:convert';
import 'dart:io' show InternetAddress;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/home_page.dart';

class AutenticacaoUser {
  Future<void> logout() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    bool isLembreMeAtivo = sharedPreferences.getBool('lembreseDeMim') ?? false;
    
    if (isLembreMeAtivo) {
      String? savedEmail = sharedPreferences.getString('saved_email');
      String? savedPassword = sharedPreferences.getString('saved_password');
      String? refreshToken = sharedPreferences.getString('refreshToken');
      String? nome = sharedPreferences.getString('nome');
      String? idPerfil = sharedPreferences.getString('id_perfil');
      
      await sharedPreferences.clear();
      
      if (savedEmail != null) {
        await sharedPreferences.setString('saved_email', savedEmail);
      }
      if (savedPassword != null) {
        await sharedPreferences.setString('saved_password', savedPassword);
      }
      if (refreshToken != null) {
        await sharedPreferences.setString('refreshToken', refreshToken);
      }
      if (nome != null) {
        await sharedPreferences.setString('nome', nome);
      }
      if (idPerfil != null) {
        await sharedPreferences.setString('id_perfil', idPerfil);
      }
      await sharedPreferences.setBool('lembreseDeMim', true);
    } else {
      await sharedPreferences.clear();
    }
  }

  Future<String?> logar(String email, String password, bool lembreDeMim,
      BuildContext context) async {
    print('=== INICIANDO PROCESSO DE LOGIN ===');
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    print('1. Verificando conexão com internet...');
    bool hasInternet = false;
    try {
      final List<InternetAddress> result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        hasInternet = true;
        print('✓ Internet disponível');
      }
    } catch (e) {
      print('✗ Sem conexão com internet: $e');
      hasInternet = false;
    }

    print('2. Status da Internet: ${hasInternet ? "ONLINE" : "OFFLINE"}');

    // PRIMEIRO CAMINHO: COM INTERNET
    if (hasInternet) {
      print('3. Iniciando processo de login ONLINE...');
      try {
        final loginUrl = Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/login');

        var body = json.encode({
          'email': email,
          'senha': password,
          'lembreDeMim': lembreDeMim,
        });

        print('4. Enviando requisição para o servidor...');
        print('   URL: $loginUrl');
        print('   Email: $email');
        print('   LembreDeMim: $lembreDeMim');

        var response = await http.post(
          loginUrl,
          headers: {
            "Content-type": "application/json",
          },
          body: body,
        );

        print('5. Resposta do servidor:');
        print('   Status Code: ${response.statusCode}');
        print('   Body: ${response.body}');

        if (response.statusCode == 200) {
          print('6. Login online bem-sucedido!');
          var responseData = json.decode(response.body);
          print('Dados recebidos do servidor:');
          print('Nome: ${responseData['user']['nome']}');
          print('ID Perfil: ${responseData['user']['id_perfil']}');

          print('7. Salvando dados básicos da sessão...');
          try {
            if (lembreDeMim) {
              print('8. Salvando dados para login offline:');
              await sharedPreferences.setString('token', responseData['token']);
              await sharedPreferences.setString('nome', responseData['user']['nome']);
              await sharedPreferences.setString('email', responseData['user']['email']);
              await sharedPreferences.setString('id_perfil', responseData['user']['id_perfil'].toString());
              await sharedPreferences.setString('refreshToken', responseData['refreshToken']);
              await sharedPreferences.setString('saved_email', email);
              await sharedPreferences.setString('saved_password', password);
              await sharedPreferences.setBool('lembreseDeMim', true);

              print('Verificando dados salvos para offline:');
              print('Email: ${await sharedPreferences.getString('saved_email')}');
              print('RefreshToken: ${await sharedPreferences.getString('refreshToken')}');
              print('Nome: ${await sharedPreferences.getString('nome')}');
              print('ID Perfil: ${await sharedPreferences.getString('id_perfil')}');
              print('   ✓ Dados de login offline salvos');
            } else {
              print('8. Salvando apenas dados da sessão atual:');
              // Limpa dados do login offline mas mantém dados básicos da sessão
              await sharedPreferences.remove('refreshToken');
              await sharedPreferences.remove('saved_email');
              await sharedPreferences.remove('saved_password');
              await sharedPreferences.setBool('lembreseDeMim', false);

              // Salva dados básicos necessários para a sessão atual
              await sharedPreferences.setString('token', responseData['token']);
              await sharedPreferences.setString('nome', responseData['user']['nome']);
              await sharedPreferences.setString('email', responseData['user']['email']);
              await sharedPreferences.setString('id_perfil', responseData['user']['id_perfil'].toString());
              print('   ✓ Dados básicos da sessão salvos');
            }

            print('9. Navegando para HomePage...');
            if (!context.mounted) return null;
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
            print('   ✓ Navegação concluída');
            return null;
          } catch (e) {
            print('✗ Erro ao salvar dados: $e');
            print('Stack trace: ${e.toString()}');
            throw e;
          }
        } else if (response.statusCode == 403) {
          print('✗ Erro: Usuário bloqueado');
          return 'Usuário bloqueado. Favor entrar em contato com o Administrador';
        } else {
          print('✗ Erro: Credenciais inválidas');
          return 'Seu e-mail ou senha estão incorretos.';
        }
      } catch (e) {
        print('✗ Erro no login online: $e');
        return 'Erro ao tentar conectar com o servidor';
      }
    }

    // SEGUNDO CAMINHO: SEM INTERNET
    print('3. Iniciando verificação para login OFFLINE...');
    bool isLembreMeAtivo = sharedPreferences.getBool('lembreseDeMim') ?? false;
    print('   Lembre-me ativo? ${isLembreMeAtivo ? "SIM" : "NÃO"}');

    if (!isLembreMeAtivo) {
      print('✗ Login offline não permitido: Lembre-me não está ativo');
      return 'Não foi possível estabelecer conexão com o servidor';
    }

    // Recupera todos os dados necessários
    final savedEmail = sharedPreferences.getString('saved_email');
    final savedPassword = sharedPreferences.getString('saved_password');
    final refreshToken = sharedPreferences.getString('refreshToken');
    final nome = sharedPreferences.getString('nome');
    final idPerfil = sharedPreferences.getString('id_perfil');

    print('4. Verificando dados salvos:');
    print('   Email digitado: $email');
    print('   Email salvo: $savedEmail');
    print('   Senha salva: ${savedPassword != null ? "SIM" : "NÃO"}');
    print('   RefreshToken: ${refreshToken != null ? "SIM" : "NÃO"}');
    print('   Nome: ${nome ?? "NULO"}');
    print('   ID Perfil: ${idPerfil ?? "NULO"}');

    // Lista todas as chaves salvas no SharedPreferences
    print('Todas as chaves salvas:');
    print(sharedPreferences.getKeys());

    if (savedEmail == null || 
        savedPassword == null || 
        refreshToken == null ||
        nome == null ||
        idPerfil == null) {
      print('✗ Login offline falhou: dados incompletos');
      print('Dados faltantes:');
      if (savedEmail == null) print('- Email');
      if (savedPassword == null) print('- Senha');
      if (refreshToken == null) print('- RefreshToken');
      if (nome == null) print('- Nome');
      if (idPerfil == null) print('- ID Perfil');
      return 'Não foi possível estabelecer conexão com o servidor';
    }

    // Verifica se as credenciais correspondem
    if (email.toLowerCase() != savedEmail.toLowerCase() || 
        password != savedPassword) {
      print('✗ Login offline falhou: credenciais incorretas');
      return 'E-mail ou senha incorretos';
    }

    print('5. Credenciais offline validadas com sucesso');
    print('6. Realizando login offline...');

    if (!context.mounted) return null;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
    print('   ✓ Navegação concluída');
    return null;
  }
}