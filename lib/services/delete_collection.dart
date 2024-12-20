// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:bm_qrcode_windows/models/collection.dart';
import 'package:bm_qrcode_windows/models/cupom.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeleteCollection extends StatefulWidget {
  const DeleteCollection({super.key, required this.collection, required this.onGet});
  final CupomCollection collection;
  final ValueChanged<CupomCollection> onGet;

  @override
  State<DeleteCollection> createState() => _CreateCollectionState();
}

class _CreateCollectionState extends State<DeleteCollection> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController controllerTitle = TextEditingController();
  int deleteds = 0;
  int length = 0;
  int errors = 0;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return !loading;
      },
      child: Form(
        key: _formKey,
        child: SimpleDialog(
          titlePadding: const EdgeInsets.only(),
          contentPadding: const EdgeInsets.all(20),
          title: ListTile(
            title: const Text("Excluir Coleção"),
            trailing: loading ? null : IconButton(onPressed: ()=> Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
          ),
          children: loading ?
          [Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                length == (deleteds + errors) ? const SizedBox() : const CircularProgressIndicator(),
                const SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, color: Colors.greenAccent[700],),
                    const SizedBox(width: 10,),
                    Text("$deleteds QrCodes Excluídos de $length"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close_rounded, color: Colors.redAccent[700],),
                    const SizedBox(width: 10,),
                    Text("$errors erros"),
                  ],
                ),
              ],
            ),
          )]: [
            const Text("Para excluir esta coleção e todos os seus QrCodes digite no campo abaixo a palabra \"DELETE\" e em seguida pressione \"Excluir\"."),
            const SizedBox(height: 10,),
            TextFormField(
              controller: controllerTitle,
              decoration: InputDecoration(
                hintText: "DELETE",
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.redAccent[700]!),
                )
              ),
              validator: (text){
                return text! != "DELETE" ? "Palavra Incorreta" : null;
              },
            ),
            const SizedBox(height: 10,),
            const Text("Obs: Após a exclusão, não será possível recuperar os dados."),
            const SizedBox(height: 10,),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if(_formKey.currentState!.validate()){
                    setState(() {
                      loading = true;
                    });
                    QuerySnapshot snapshots = await FirebaseFirestore.instance.collection("cupons").where("collection", isEqualTo: widget.collection.id).get();
                    List<Cupom> cupons = snapshots.docs.map((e)=> Cupom.fromMap(e.data()! as Map<String, dynamic>)).toList();

                    setState(() {
                      length = cupons.length;
                    });
      
                    for(var cupom in cupons){
                      await FirebaseFirestore.instance.collection("cupons").doc(cupom.id).delete();
                      setState(() {
                        deleteds = deleteds + 1;
                      });
                    }

                    FirebaseFirestore.instance.collection("collections").doc(widget.collection.id).delete()
                    .then((_){
                      widget.onGet.call(widget.collection);
                      Navigator.pop(context);
                    }).catchError((e){
                      Navigator.pop(context);
                    });
                  }
                },
                child: const Text("Excluir")
              ),
            )
          ],
        ),
      ),
    );
  }
}