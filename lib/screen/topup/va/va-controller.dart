// @dart=2.9

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile/bloc/Api.dart';
import 'package:mobile/bloc/Bloc.dart';
import 'package:mobile/config.dart';
import 'package:mobile/models/virtual_account.dart';
import 'package:mobile/screen/topup/va/va-deposit.dart';
import 'package:mobile/screen/topup/va/va.dart';
import 'package:http/http.dart' as http;

abstract class VAController extends State<TopupVA> {
  bool loading = false;
  TextEditingController nominal = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('🔍 [TOPUP VA CTRL] initState called');
  }

  Future<List<VirtualAccount>> getVa() async {
    print('🔍 [TOPUP VA CTRL] getVa() called');
    
    var requestUrl = '$apiUrl/deposit/virtual-account/list';
    var requestHeaders = {'Authorization': bloc.token.valueWrapper?.value};
    
    print('🔍 [TOPUP VA CTRL] FULL API REQUEST DETAILS:');
    print('🔍 [TOPUP VA CTRL] URL: $requestUrl');
    print('🔍 [TOPUP VA CTRL] Headers: ${requestHeaders.toString()}');
    
    http.Response response = await http.get(
        Uri.parse(requestUrl),
        headers: requestHeaders);

    print('🔍 [TOPUP VA CTRL] API response status: ${response.statusCode}');
    print('🔍 [TOPUP VA CTRL] FULL API RESPONSE PAYLOAD:');
    print('🔍 [TOPUP VA CTRL] ${response.body}');
    
    if (response.statusCode == 200) {
      print('🔍 [TOPUP VA CTRL] API request successful');
      var responseData = json.decode(response.body);
      print('🔍 [TOPUP VA CTRL] FULL PARSED RESPONSE DATA:');
      print('🔍 [TOPUP VA CTRL] ${responseData.toString()}');
      
      List<dynamic> datas = responseData['data'];
      print('🔍 [TOPUP VA CTRL] Number of VA options: ${datas.length}');
      
      var vaList = datas.map((el) {
        print('🔍 [TOPUP VA CTRL] Processing VA: ${el.toString()}');
        return VirtualAccount.fromJson(el);
      }).toList();
      
      print('🔍 [TOPUP VA CTRL] VA list created with ${vaList.length} items');
      return vaList;
    } else {
      print('🔍 [TOPUP VA CTRL] API request failed');
      return [];
    }
  }

  void topup(VirtualAccount va) async {
    print('🔍 [TOPUP VA CTRL] topup() called');
    print('🔍 [TOPUP VA CTRL] Selected VA: ${va.toString()}');
    print('🔍 [TOPUP VA CTRL] Raw nominal text: ${nominal.text}');
    
    double parsedNominal = double.parse(nominal.text.replaceAll('.', ''));
    print('🔍 [TOPUP VA CTRL] Parsed nominal: $parsedNominal');
    
    if (nominal.text.isEmpty) {
      print('🔍 [TOPUP VA CTRL] Validation failed: nominal empty');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Nominal belum diisi')));
      return;
    } else if (parsedNominal < 10000) {
      print('🔍 [TOPUP VA CTRL] Validation failed: nominal < 10000');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Minimal deposit adalah Rp 10.000')));
      return;
    }
    
    print('🔍 [TOPUP VA CTRL] Validation passed');

    print('🔍 [TOPUP VA CTRL] Setting loading to true');
    setState(() {
      loading = true;
    });
    
    try {
      var requestUrl = '$apiUrl/deposit/payment-va';
      var requestHeaders = {
        'Authorization': bloc.token.valueWrapper?.value,
        'Content-Type': 'application/json'
      };
      var requestBody = {'nominal': parsedNominal, 'vacode': va.code};
      
      print('🔍 [TOPUP VA CTRL] FULL API REQUEST DETAILS:');
      print('🔍 [TOPUP VA CTRL] URL: $requestUrl');
      print('🔍 [TOPUP VA CTRL] Headers: ${requestHeaders.toString()}');
      print('🔍 [TOPUP VA CTRL] Body: ${requestBody.toString()}');
      print('🔍 [TOPUP VA CTRL] Body JSON: ${json.encode(requestBody)}');
      
      http.Response response =
          await http.post(Uri.parse(requestUrl),
              headers: requestHeaders,
              body: json.encode(requestBody));

      print('🔍 [TOPUP VA CTRL] API response status: ${response.statusCode}');
      print('🔍 [TOPUP VA CTRL] FULL API RESPONSE PAYLOAD:');
      print('🔍 [TOPUP VA CTRL] ${response.body}');
      
      if (response.statusCode == 200) {
        print('🔍 [TOPUP VA CTRL] API request successful');
        var responseData = json.decode(response.body);
        print('🔍 [TOPUP VA CTRL] FULL PARSED RESPONSE DATA:');
        print('🔍 [TOPUP VA CTRL] ${responseData.toString()}');
        
        Map<String, dynamic> data = responseData['data'];
        print('🔍 [TOPUP VA CTRL] VA response data: ${data.toString()}');
        
        VirtualAccountResponse va = VirtualAccountResponse.fromJson(data);
        print('🔍 [TOPUP VA CTRL] VA response object created');
        print('🔍 [TOPUP VA CTRL] Navigating to DepositVa page');
        
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => DepositVa(va)));
      } else {
        print('🔍 [TOPUP VA CTRL] API request failed');
        var errorData = json.decode(response.body);
        print('🔍 [TOPUP VA CTRL] Error response: ${errorData.toString()}');
        
        String message = errorData['message'];
        print('🔍 [TOPUP VA CTRL] Error message: $message');
        
        showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                    title: Text("TopUp Gagal"),
                    content: Text(message),
                    actions: <Widget>[
                      TextButton(
                          child: Text(
                            'TUTUP',
                            style: TextStyle(
                              color: packageName == 'com.lariz.mobile'
                                  ? Theme.of(context).secondaryHeaderColor
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop())
                    ]));
      }
    } catch (err) {
      print('🔍 [TOPUP VA CTRL] Exception occurred: $err');
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: Text("TopUp Gagal"),
                  content: Text(err.toString()),
                  actions: <Widget>[
                    TextButton(
                        child: Text(
                          'TUTUP',
                          style: TextStyle(
                            color: packageName == 'com.lariz.mobile'
                                ? Theme.of(context).secondaryHeaderColor
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                        onPressed: () => Navigator.of(ctx).pop())
                  ]));
    } finally {
      print('🔍 [TOPUP VA CTRL] Setting loading to false');
      setState(() {
        loading = false;
      });
      print('🔍 [TOPUP VA CTRL] State updated');
    }
  }
}
