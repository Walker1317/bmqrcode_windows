// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Cupom {

  String? id;
  String? value;
  String? reference;
  String? status;
  int? digits;
  int? sequence;
  String? image;
  String? text;
  Timestamp? validation;
  Timestamp? created;
  String? collection;

  Cupom({
    this.id,
    this.value,
    this.reference,
    this.status,
    this.digits,
    this.sequence,
    this.image,
    this.text,
    this.validation,
    this.created,
    this.collection,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'value': value,
      'reference': reference,
      'status' : status,
      'digits': digits,
      'sequence': sequence,
      'image': image,
      'text': text,
      'validation': validation,
      'created': created,
      'collection': collection,
    };
  }

  factory Cupom.fromMap(Map<String, dynamic> map) {
    return Cupom(
      id: map['id'] != null ? map['id'] as String : null,
      value: map['value'] != null ? map['value'] as String : null,
      reference: map['reference'] != null ? map['reference'] as String : null,
      status: map['status'] != null ? map['status'] as String : null,
      digits: map['digits'] != null ? map['digits'] as int : null,
      sequence: map['sequence'] != null ? map['sequence'] as int : null,
      image: map['image'] != null ? map['image'] as String : null,
      text: map['text'] != null ? map['text'] as String : null,
      validation: map['validation'] != null ? map['validation'] as Timestamp : null,
      created: map['created'] != null ? map['created'] as Timestamp : null,
      collection: map['collection'] != null ? map['collection'] as String : null,
    );
  }

  String toPrintString(){
    return "${value!.replaceAll("/", "\t")}\t$reference\t$sequence";
  }

  String toJson() => json.encode(toMap());

  factory Cupom.fromJson(String source) => Cupom.fromMap(json.decode(source) as Map<String, dynamic>);
}
