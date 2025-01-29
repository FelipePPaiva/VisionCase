import 'package:flutter/material.dart';
import 'home_page.dart';

class SenhaSucessoAppPage extends StatelessWidget {
  const SenhaSucessoAppPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            //Row de Topo com Logo e nome
            SizedBox(height: 91),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ilustração do topo
                Image.asset(
                  'assets/images/sucesso.png',
                ),
                const SizedBox(height: 40),
                // Título
                const Text(
                  'Senha alterada com sucesso!',
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Frutiger',
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(50, 55, 62, 1),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Subtítulo
                const Text(
                  'Lembre-se de usar sua nova senha nas próximas vezes que acessar.',
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Frutiger',
                      fontWeight: FontWeight.w400,
                      color: Color.fromRGBO(96, 106, 118, 1)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 180),
                // Botão para ir ao login
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => HomePage()));
                    },
                    label: const Text('Voltar para Início',
                    style:TextStyle(
                      fontSize: 16,
                      fontFamily: 'Frutiger',
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      letterSpacing: 0.32,
                    )),
                    style: ElevatedButton.styleFrom(
                      foregroundColor:
                          Colors.white, // Define a cor do texto e dos ícones
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Frutiger',),
                      backgroundColor: const Color.fromRGBO(0, 114, 239, 1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
