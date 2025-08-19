  // @dart=2.9
import 'package:flutter/cupertino.dart';
import 'package:mobile/models/count_trx.dart';
import 'package:mobile/models/user.dart';
import 'package:rxdart/rxdart.dart';

class Bloc extends Object {
  final amount = BehaviorSubject<int>.seeded(0);
  sinkamount(String a) => amount.sink.add(int.parse(a.replaceAll('.', '')));

  final user = BehaviorSubject<UserModel>();
  final userId = BehaviorSubject<String>();
  final userPhone = BehaviorSubject<String>();
  final username = BehaviorSubject<String>();
  final namaToko = BehaviorSubject<String>();
  final alamat = BehaviorSubject<String>();
  final kodeReseller = BehaviorSubject<String>();
  final token = BehaviorSubject<String>();
  final saldo = BehaviorSubject<int>();
  final poin = BehaviorSubject<int>();
  final komisi = BehaviorSubject<int>();
  final totalNotif = BehaviorSubject<int>();
  final deviceToken = BehaviorSubject<String>();
  final notificationData = BehaviorSubject<Map<String, dynamic>>();
  final kodeUpline = BehaviorSubject<String>();
  final printerType = BehaviorSubject<int>();
  final printerFontSize = BehaviorSubject<int>();

  final mainColor = BehaviorSubject<Color>();
  final mainTextColor = BehaviorSubject<Color>();

  final todayTrxCount = BehaviorSubject<CountTrx>();
  final allTrxCount = BehaviorSubject<CountTrx>();

  /*
  LISTEN NOTIFICATION ON FOREGROUND
  */

  void initState() {}

  void dispose() {
    mainColor.close();
    mainTextColor.close();
    user.close();
    userId.close();
    userPhone.close();
    username.close();
    namaToko.close();
    kodeReseller.close();
    token.close();
    saldo.close();
    alamat.close();
    amount.close();
    poin.close();
    komisi.close();
    totalNotif.close();
    deviceToken.close();
    notificationData.close();
    kodeUpline.close();
    printerType.close();
    printerFontSize.close();
    todayTrxCount.close();
    allTrxCount.close();
  }
}

final bloc = Bloc();
