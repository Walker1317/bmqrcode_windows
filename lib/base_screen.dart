// ignore_for_file: use_build_context_synchronously
import 'package:bm_qrcode_windows/models/collection.dart';
import 'package:bm_qrcode_windows/models/cupom.dart';
import 'package:bm_qrcode_windows/screens/create_numbers/create_numbers.dart';
import 'package:bm_qrcode_windows/services/create_collection.dart';
import 'package:bm_qrcode_windows/services/delete_collection.dart';
import 'package:bm_qrcode_windows/services/qr_services.dart';
import 'package:bm_qrcode_windows/widgets/dialog_services.dart';
import 'package:bm_qrcode_windows/widgets/qrcode_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  Query<CupomCollection>? query;
  Query<Cupom>? queryCupom;
  PageController pageController = PageController();
  int currentPage = 0;
  bool selectMode = false;
  bool selectedAll = false;
  List<Cupom> selecionados = [];
  CupomCollection? currentCollection;
  List<int> digitsList = [2,3,4,6];

  changeCupomQuery(){
    setState(() {
      queryCupom = FirebaseFirestore.instance.collection("cupons").where("collection", isEqualTo: currentCollection!.id)
      .where("digits", isEqualTo: digitsList[currentPage])
      .orderBy("sequence", descending: false)
      .withConverter(fromFirestore: (snapshot, options)=> Cupom.fromMap(snapshot.data()!), toFirestore: (snapshot, options)=> {});
    });
  }

  @override
  void initState() {
    super.initState();
    query = FirebaseFirestore.instance.collection("collections").orderBy("created", descending: true)
    .withConverter(fromFirestore: (snapshot, options)=> CupomCollection.fromMap(snapshot.data()!), toFirestore: (snapshot, options)=> {});
  }

  @override
  Widget build(BuildContext context) {
    return FirestoreQueryBuilder<CupomCollection>(
      query: query!,
      builder: (context, snapshot, child){
        if(snapshot.isFetching){
          return const Center(child: CircularProgressIndicator(),);
        }
        final data = snapshot.docs;
        return Scaffold(
          appBar: AppBar(
            title: currentCollection == null ?
            ListTile(
              selected: true,
              onTap: () async {
                final value = await changeCollection(data.map<CupomCollection>((e)=> e.data()).toList());
                if(value != null){
                  setState(() {
                    currentCollection = value;
                    changeCupomQuery();
                  });
                }
              },
              title: const Text("Selecione a Coleção", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
            ):
            ListTile(
              onTap: () async {
                final value = await changeCollection(data.map<CupomCollection>((e)=> e.data()).toList());
                if(value != null){
                  setState(() {
                    currentCollection = value;
                    changeCupomQuery();
                  });
                }
              },
              selected: true,
              title: Text(currentCollection!.name!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
              subtitle: const Text("Toque para Alterar"),
              trailing: PopupMenuButton(
                itemBuilder: (context){
                  return [
                    PopupMenuItem(
                      onTap: (){
                        showDialog(
                          context: context,
                          builder: (context){
                            return DeleteCollection(
                              collection: currentCollection!,
                              onGet: (value){
                                setState(() {
                                  currentCollection = null;
                                });
                              },
                            );
                          }
                        );
                      },
                      child: Text("Excluir Coleção", style: TextStyle(color: Colors.redAccent[700]),)
                    )
                  ];
                }
              ),
            ),
            actions: const [
              /*PopupMenuButton(
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
              ),*/
            ],
          ),
          body: currentCollection == null ?
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("Para Iniciar, selecione uma coleção."),
                const SizedBox(height: 10,),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final value = await changeCollection(data.map<CupomCollection>((e)=> e.data()).toList());
                      if(value != null){
                        setState(() {
                          currentCollection = value;
                        });
                        changeCupomQuery();
                      }
                    },
                    child: const Text("Selecionar Coleção")
                  ),
                )
              ],
            ),
          ):
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Colors.black26,
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) {
                        final digits = digitsList[currentPage];
                        return Text("$digits Dígitos", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),);
                      }
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: currentPage <= 0 ? null : ()=> pageController.previousPage(curve: Curves.ease, duration: const Duration(milliseconds: 300)),
                          child: const Icon(Icons.keyboard_arrow_left_rounded)
                        ),
                        ElevatedButton(
                          onPressed: currentPage == 3 ? null : ()=> pageController.nextPage(curve: Curves.ease, duration: const Duration(milliseconds: 300)),
                          child: const Icon(Icons.keyboard_arrow_right_rounded)
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  itemCount: digitsList.length,
                  controller: pageController,
                  onPageChanged: (value){
                    setState(() {
                      currentPage = value;
                      selectMode = false;
                      selectedAll = false;
                      selecionados.clear();
                      changeCupomQuery();
                    });
                  },
                  itemBuilder: (context, index){
                    return Column(
                      children: [
                        Row(
                          children: [
                            TextButton(
                              onPressed: () async {
                                DialogServices.loading2(context);
                                QrServices().generateAndSaveQRCodes(currentCollection!, digitsList[currentPage])
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
                            ),
                            TextButton(
                              onPressed: () async {
                                DialogServices.loading2(context);
                                QrServices().createTxtFile(currentCollection!, digitsList[currentPage])
                                .then((_){
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text("Texto gerado na pasta \"Documentos\" do seu computador."),
                                      backgroundColor: Colors.greenAccent[700],
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }).catchError((e){
                                  Navigator.pop(context);
                                  DialogServices.alertDialog(context, "Erro eu gerar Documento de Texto:\n\n$e");
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Ionicons.document_text_outline, color: Colors.blueAccent[700],),
                                  const SizedBox(width: 5,),
                                  Text("Gerar Texto", style: TextStyle(color: Colors.blueAccent[700]),)
                                ],
                              )
                            ),
                            /*selectMode ?
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
                            ) : const SizedBox() : const SizedBox(),*/
                            selectMode ?
                            Text("${selecionados.length} selecionados"): const SizedBox(),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                        Expanded(
                          child: FirestoreListView<Cupom>(
                            query: queryCupom!,
                            emptyBuilder: (context)=> const Center(
                              child: Text(
                                "Não há Números",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            itemBuilder: (context, snapshot){
                              final cupom = snapshot.data();
                              return InkWell(
                                onTap: (){
                                  showDialog(context: context, builder: (context)=> QRCodeDetails(cupom: cupom));
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      height: 2,
                                      color: Colors.white10,
                                    ),
                                    SizedBox(
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
                                              });
                                            },
                                          ) : const SizedBox(),
                                          SizedBox(width: 60, child: Text("    ${cupom.sequence} |")),
                                          Expanded(flex: 2,child: Text(cupom.value!, style: cupom.validation == null ? const TextStyle() : TextStyle(color: Colors.greenAccent[700], fontWeight: FontWeight.bold)),),
                                          Expanded(child: Text(cupom.reference!, textAlign: TextAlign.center,)),
                                          Expanded(child: SelectableText(cupom.id!, textAlign: TextAlign.center,)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );/*Scaffold(
                                appBar: AppBar(
                                  actions: [
                                    
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
                                          const SizedBox(width: 60, child:  Text("SEQ |")),
                                          const Expanded(flex: 2,child: Text("NUM"),),
                                          const Expanded(child: Text("REFERÊNCIA", textAlign: TextAlign.center,)),
                                          const Expanded(child: Text("QR CODE", textAlign: TextAlign.center,)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: cartela.cupons!.length,
                                        itemBuilder: (context, index){
                                          final cupom = cartela.cupons![index];
                                          return 
                                        }
                                      ),
                                    )
                                  ],
                                ),
                              );*/
                            }
                          ),
                        ),
                      ],
                    );
                    
                    /*const */
                  }
                ),
              ),
            ],
          ),
          floatingActionButton: currentCollection == null ? null :
          ElevatedButton(
            onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> CreateNumbers(collection: currentCollection!,))),
            child: const Text("Novos Números"),
          ),
        );
      }
    );
  }

  Future<CupomCollection?> changeCollection(List<CupomCollection> collections) async {
    CupomCollection? value;
    await showDialog(
      context: context,
      builder: (context){
        return SimpleDialog(
          titlePadding: const EdgeInsets.only(),
          contentPadding: const EdgeInsets.all(20),
          title: ListTile(
            title: const Text("Selecione a Coleção"),
            trailing: IconButton(onPressed: ()=> Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
          ),
          children: [
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: (){
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context){
                      return CreateCollection(
                        onGet: (value){
                          setState(() {
                            currentCollection = value;
                            changeCupomQuery();
                          });
                        }
                      );
                    }
                  );
                },
                child: const Text("Nova Coleção")
              ),
            ),
            Column(
              children: collections.map<Widget>((e){
                return Column(
                  children: [
                    const Divider(),
                    ListTile(
                      onTap: (){
                        value = e;
                        Navigator.pop(context);
                      },
                      title: Text(e.name!),
                      trailing: Text(DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY, 'pt_BR').format(e.created!.toDate())),
                    ),
                  ],
                );
              }).toList(),
            )
          ]
        );
      }
    );
    return value;
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