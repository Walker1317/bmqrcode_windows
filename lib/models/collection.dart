// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class CupomCollection {

  String? id;
  String? name;
  Timestamp? created;

  CupomCollection({
    this.id,
    this.name,
    this.created,
  });


  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'created': created,
    };
  }

  factory CupomCollection.fromMap(Map<String, dynamic> map) {
    return CupomCollection(
      id: map['id'] != null ? map['id'] as String : null,
      name: map['name'] != null ? map['name'] as String : null,
      created: map['created'] != null ? map['created'] as Timestamp : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CupomCollection.fromJson(String source) => CupomCollection.fromMap(json.decode(source) as Map<String, dynamic>);
}
