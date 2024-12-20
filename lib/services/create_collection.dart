// ignore_for_file: use_build_context_synchronously
import 'package:bm_qrcode_windows/models/collection.dart';
import 'package:bm_qrcode_windows/widgets/dialog_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateCollection extends StatefulWidget {
  const CreateCollection({super.key, required this.onGet});
  final ValueChanged<CupomCollection> onGet;

  @override
  State<CreateCollection> createState() => _CreateCollectionState();
}

class _CreateCollectionState extends State<CreateCollection> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController controllerTitle = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SimpleDialog(
        titlePadding: const EdgeInsets.only(),
        contentPadding: const EdgeInsets.all(20),
        title: ListTile(
          title: const Text("Nova Coleção"),
          trailing: IconButton(onPressed: ()=> Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
        ),
        children: [
          TextFormField(
            controller: controllerTitle,
            decoration: const InputDecoration(
              labelText: "Nome da Coleção"
            ),
            validator: (text){
              return text!.isEmpty ? "Digite o título" : null;
            },
            maxLength: 100,
          ),
          const SizedBox(height: 10,),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: (){
                DialogServices.loading2(context);
                final db = FirebaseFirestore.instance.collection("collections").doc();
                final collection = CupomCollection(
                  id: db.id,
                  name: controllerTitle.text,
                  created: Timestamp.now(),
                );
                db.set(collection.toMap())
                .then((_){
                  widget.onGet.call(collection);
                  Navigator.pop(context);
                  Navigator.pop(context);
                }).catchError((e){
                  Navigator.pop(context);
                  DialogServices.alertDialog(context, "Não foi possível criar uma nova coleção.");
                });
              },
              child: const Text("Criar Coleção")
            ),
          )
        ],
      ),
    );
  }
}