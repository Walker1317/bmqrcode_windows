// ignore_for_file: use_build_context_synchronously

import 'package:bm_qrcode_windows/widgets/dialog_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController controllerEmail = TextEditingController();
  final TextEditingController controllerPass = TextEditingController();
  bool obscure = true;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 500
              ),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 20, 20, 20),
                borderRadius: BorderRadius.circular(20)
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const  Text("BM QrCode", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),),
                  const Text("Cadastro e gestão de cupons de desconto", style: TextStyle(fontSize: 16),),
                  const SizedBox(height: 20,),
                  TextFormField(
                    readOnly: loading,
                    controller: controllerEmail,
                    decoration: const InputDecoration(
                      labelText: "E-mail",
                    ),
                    validator: (text){
                      return !text!.contains("@") || !text.contains(".") ? "Email inválido" : null;
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(200),
                    ],
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10,),
                  TextFormField(
                    readOnly: loading,
                    controller: controllerPass,
                    decoration: InputDecoration(
                      labelText: "Senha",
                      suffixIcon: IconButton(
                        onPressed: (){
                          setState(() {
                            obscure = !obscure;
                          });
                        },
                        icon: Icon(obscure ? Ionicons.eye_outline : Ionicons.eye_off_outline),
                      )
                    ),
                    validator: (text){
                      return text!.length < 6 ? "Senha inválida" : null;
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(200),
                    ],
                    obscureText: obscure,
                  ),
                  const SizedBox(height: 20,),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : () async {
                        if(formKey.currentState!.validate()){
                          setState(() {
                            loading = true;
                          });
                          try{
                            //await FirebaseAuth.instance.signInWithEmailAndPassword(email: controllerEmail.text, password: controllerPass.text);
                          } catch (e){
                            setState(() {
                              loading = false;
                            });
                            DialogServices.alertDialog(context, "Credenciais Inválidas");
                          }
                        }
                      },
                      child: loading ? const CircularProgressIndicator() : const Text("Entrar")
                    ),
                  ),
                  const SizedBox(height: 10,),
                  const Text("0.0.1", textAlign: TextAlign.center,)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}