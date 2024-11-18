// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:bm_qrcode_windows/models/cupom.dart';

class Cartela {
  
  String? id;
  int? digits;
  int? length;
  int? limit;
  List<Cupom>? cupons;
  
  Cartela({
    this.id,
    this.digits,
    this.length,
    this.limit,
    this.cupons,
  });


  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'digits': digits,
      'length': length,
      'limit': limit,
      'cupons': cupons!.map((x) => x.toMap()).toList(),
    };
  }

  factory Cartela.fromMap(Map<String, dynamic> map) {
    return Cartela(
      id: map['id'] != null ? map['id'] as String : null,
      digits: map['digits'] != null ? map['digits'] as int : null,
      length: map['length'] != null ? map['length'] as int : null,
      limit: map['limit'] != null ? map['limit'] as int : null,
      cupons: map['cupons'] != null ? List<Cupom>.from((map['cupons'] as List).map<Cupom?>((x) => Cupom.fromMap(x as Map<String,dynamic>),),) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Cartela.fromJson(String source) => Cartela.fromMap(json.decode(source) as Map<String, dynamic>);
}
