import 'package:flutter/material.dart';

class DialogServices{

  DialogServices.loading(BuildContext context){
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context){
        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async {
            return true;
          },
          child: Center(
            child: Container(
              height: 120,
              width: 120,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                //color: Colors.white,
              ),
              child: const CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
        );
      }
    );
  }

  DialogServices.loading2(BuildContext context){
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context){
        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async {
            return true;
          },
          child: Center(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)
              ),
              child: const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          ),
        );
      }
    );
  }

  DialogServices.alertDialog(BuildContext context, String content, {String? title, Color? colorButton1, Color? colorButton2,
  VoidCallback? onTap1, VoidCallback? onTap2, String? buttonTitle1 = 'OK', String? buttonTitle2, Widget? contentWidget, EdgeInsetsGeometry? contentPadding,
  }){
    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Text(title ?? "Oops!"),
          contentPadding: contentPadding ?? const EdgeInsets.all(24),
          content: contentWidget ?? Text(content),
          actions: [
            buttonTitle1! == 'emptyButton' ? Container():
            TextButton(
              onPressed: onTap1 ?? ()=> Navigator.of(context).pop(),
              child: Text(buttonTitle1, style: TextStyle(color: colorButton1),)
            ),
            buttonTitle2 != null?
            TextButton(
              onPressed: onTap2 ?? (){},
              child: Text(buttonTitle2, style: TextStyle(color: colorButton2),)
            ) : Container(),
          ],
        );
      }
    );
  }
}