// ignore_for_file: use_build_context_synchronously

import 'package:bm_qrcode_windows/models/cartela.dart';
import 'package:bm_qrcode_windows/models/cupom.dart';
import 'package:bm_qrcode_windows/screens/auth_screen/auth_screen.dart';
import 'package:bm_qrcode_windows/screens/create_numbers/create_numbers.dart';
import 'package:bm_qrcode_windows/services/qr_services.dart';
import 'package:bm_qrcode_windows/widgets/dialog_services.dart';
import 'package:bm_qrcode_windows/widgets/qrcode_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  Query<Cartela>? query;
  PageController pageController = PageController();
  int currentPage = 0;
  bool selectMode = false;
  bool selectedAll = false;
  List<Cupom> selecionados = [];
  Stream<User?>? userStream;

  @override
  void initState() {
    super.initState();
    userStream = FirebaseAuth.instance.authStateChanges();
    query = FirebaseFirestore.instance.collection("cartelas")
    .withConverter(fromFirestore: (snapshot, options)=> Cartela.fromMap(snapshot.data()!), toFirestore: (snapshot, options)=> {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: userStream,
      builder: (context, snapshot) {

        if(snapshot.connectionState == ConnectionState.waiting){
          return const Center(child: CircularProgressIndicator(),);
        }

        if(snapshot.data == null){
          return const AuthScreen();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("BM QR Code"),
            actions: [
              PopupMenuButton(
                itemBuilder: (itemBuilder){
                  return [
                    PopupMenuItem(
                      onTap: (){
                        FirebaseAuth.instance.signOut();
                      },
                      child: Text("Encerrar Sessão", style: TextStyle(color: Colors.redAccent[700]),),
                    )
                  ];
                }
              ),
            ],
          ),
          body: FirestoreQueryBuilder<Cartela>(
            query: query!,
            builder: (context, snapshot, child){
              if(snapshot.isFetching){
                return const Center(child: CircularProgressIndicator(),);
              }
              final cartelas = snapshot.docs;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: currentPage <= 0 ? null : ()=> pageController.previousPage(curve: Curves.ease, duration: const Duration(milliseconds: 300)),
                        child: const Icon(Icons.keyboard_arrow_left_rounded)
                      ),
                      ElevatedButton(
                        onPressed: currentPage+1 == cartelas.length ? null : ()=> pageController.nextPage(curve: Curves.ease, duration: const Duration(milliseconds: 300)),
                        child: const Icon(Icons.keyboard_arrow_right_rounded)
                      ),
                    ],
                  ),
                  Expanded(
                    child: PageView.builder(
                      itemCount: cartelas.length,
                      controller: pageController,
                      onPageChanged: (value){
                        setState(() {
                          currentPage = value;
                          selectMode = false;
                          selectedAll = false;
                          selecionados.clear();
                        });
                      },
                      itemBuilder: (context, index){
                        final cartela = cartelas[index].data();
                        return Scaffold(
                          appBar: AppBar(
                            actions: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(cartela.id!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                              ),
                              TextButton(
                                onPressed: (){
                                  setState(() {
                                    selectMode = !selectMode;
                                    selecionados.clear();
                                    selectedAll = false;
                                  });
                                },
                                child: Text(selectMode ? "Cancelar Seleção" : "Selecionar"),
                              ),
                              selectMode ?
                              selecionados.isNotEmpty ?
                              TextButton(
                                onPressed: () async {
                                  DialogServices.loading2(context);
                                  QrServices().generateAndSaveQRCodes(selecionados.map<String>((e)=> e.id!).toList())
                                  .then((_){
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text("QRCodes gerados na pasta \"Documentos\" do seu computador."),
                                        backgroundColor: Colors.greenAccent[700],
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }).catchError((e){
                                    Navigator.pop(context);
                                    DialogServices.alertDialog(context, "Erro eu gerar um ou mais QRCodes:\n\n$e");
                                  });
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.qr_code, color: Colors.greenAccent[700],),
                                    const SizedBox(width: 5,),
                                    Text("Gerar QRCode", style: TextStyle(color: Colors.greenAccent[700]),)
                                  ],
                                )
                              ): const SizedBox() : const SizedBox(),
                              selectMode ?
                              selecionados.isNotEmpty ?
                              TextButton(
                                onPressed: (){
                                  DialogServices.alertDialog(
                                    context,
                                    'Deseja excluir os números selecionados?',
                                    title: "Tem certeza?",
                                    buttonTitle1: "Excluir",
                                    buttonTitle2: "Cancelar",
                                    colorButton1: Colors.redAccent[700],
                                    colorButton2: Colors.grey,
                                    onTap2: ()=> Navigator.pop(context),
                                    onTap1: (){
                                      Navigator.pop(context);
                                      DialogServices.loading2(context);
                                      final newList = removeItensFromList(cartela.cupons!, selecionados);
                                      FirebaseFirestore.instance.collection("cartelas").doc(cartela.id).update({
                                        'cupons' : newList.map((e)=> e.toMap()).toList(),
                                        'length' : newList.length,
                                      }).then((e){
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text("Lista Atualizada!"),
                                            backgroundColor: Colors.greenAccent[700],
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                        setState(() {
                                          selecionados.clear();
                                          selectedAll = false;
                                        });
                                      }).catchError((e){
                                        Navigator.pop(context);
                                        DialogServices.alertDialog(context, "Erro ao excluir números");
                                      });
                                    }
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent[700],
                                ),
                                child: Text(
                                  "Excluir",
                                  style: TextStyle(color: Colors.redAccent[700]),
                                ),
                              ) : const SizedBox() : const SizedBox(),
                              selectMode ?
                              Text("${selecionados.length} selecionados"): const SizedBox(),
                              const Expanded(child: SizedBox()),
                              Text("QR Code gerados: ${cartela.length}/${cartela.limit}"),
                              const SizedBox(width: 10,),
                            ],
                          ),
                          body: Column(
                            children: [
                              Container(
                                height: 30,
                                color: const Color(0xFF021625),
                                child: Row(
                                  children: [
                                    selectMode ?
                                    Checkbox(
                                      value: selectedAll,
                                      onChanged: (value){
                                        setState(() {
                                          selectedAll = !selectedAll;
                                          if(selectedAll){
                                            selecionados.clear();
                                            for(var currentCupom in cartela.cupons!){
                                              selecionados.add(currentCupom);
                                            }
                                          } else {
                                            selecionados.clear();
                                          }
                                        });
                                      }
                                    ):
                                    const SizedBox(),
                                    const SizedBox(width: 40, child:  Text("SEQ |")),
                                    const Expanded(flex: 2,child: Text("NUM"),),
                                    const Expanded(child: Text("REFERÊNCIA", textAlign: TextAlign.center,)),
                                    const Expanded(child: Text("QR CODE", textAlign: TextAlign.center,)),
                                  ],
                                ),
                              ),
                              cartela.cupons!.isEmpty ?
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    "Não há Números",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ):
                              Expanded(
                                child: ListView.builder(
                                  itemCount: cartela.cupons!.length,
                                  itemBuilder: (context, index){
                                    final cupom = cartela.cupons![index];
                                    return InkWell(
                                      onTap: (){
                                        showDialog(context: context, builder: (context)=> QRCodeDetails(cupom: cupom));
                                      },
                                      child: Container(
                                        color: index.isEven ? Colors.white10 : Colors.transparent,
                                        child: SizedBox(
                                          height: 30,
                                          child: Row(
                                            children: [
                                              selectMode ?
                                              Checkbox(
                                                value: selecionados.where((e)=> e.id == cupom.id).isNotEmpty,
                                                onChanged: (value){
                                                  setState(() {
                                                    if(selecionados.where((e)=> e.id == cupom.id).isNotEmpty){
                                                      selecionados.removeAt(selecionados.indexWhere((e)=> e.id == cupom.id));
                                                    } else {
                                                      selecionados.add(cupom);
                                                    }
                                                    if(selecionados.length == cartela.cupons!.length){
                                                      selectedAll = true;
                                                    } else {
                                                      selectedAll = false;
                                                    }
                                                  });
                                                },
                                              ) : const SizedBox(),
                                              SizedBox(width: 40, child: Text("    ${index + 1} |")),
                                              Expanded(flex: 2,child: Text(cupom.value!),),
                                              Expanded(child: Text(cupom.reference!, textAlign: TextAlign.center,)),
                                              Expanded(child: SelectableText(cupom.id!, textAlign: TextAlign.center,)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                ),
                              )
                            ],
                          ),
                          floatingActionButton: ElevatedButton(
                            onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> CreateNumbers(cartelas: cartelas.map((e)=> e.data()).toList()))),
                            child: const Text("Novos Números"),
                          ),
                        );
                      }
                    ),
                  ),
                ],
              );
            }
          ),
        );
      }
    );
  }

  List<Cupom> removeItensFromList(List<Cupom> current, List<Cupom> selected){
    final currentList = current;
    for(var item in selected){
      currentList.removeAt(currentList.indexWhere((e)=> e.id == item.id));
    }
    for(int i = 0; i < currentList.length; i++){
      var currentValue = currentList[i];
      currentValue.sequence = i+1;
      currentList.removeAt(i);
      currentList.insert(i, currentValue);
    }
    return currentList;
  }
}