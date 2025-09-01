// @dart=2.9

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile/screen/topup/bank/bank.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/screen/topup/bank/transfer-deposit.dart';
import '../../../bloc/Bloc.dart' show bloc;
import '../../../bloc/Api.dart' show apiUrl;

abstract class BankController extends State<TopupBank> {
  bool loading = false;
  TextEditingController nominal = TextEditingController();

  void topup() async {
    print('🔍 [TOPUP BANK CTRL] topup() called');
    print('🔍 [TOPUP BANK CTRL] Raw nominal text: ${nominal.text}');
    
    double parsedNominal = double.parse(nominal.text.replaceAll('.', ''));
    print('🔍 [TOPUP BANK CTRL] Parsed nominal: $parsedNominal');
    print('🔍 [TOPUP BANK CTRL] Payment type: ${widget.payment.type}');
    
    if (nominal.text.isEmpty) {
      print('🔍 [TOPUP BANK CTRL] Validation failed: nominal empty');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Nominal belum diisi')));
      return;
    } else if (parsedNominal < 10000) {
      print('🔍 [TOPUP BANK CTRL] Validation failed: nominal < 10000');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Minimal deposit adalah Rp 10.000')));
      return;
    }
    
    print('🔍 [TOPUP BANK CTRL] Validation passed');

    print('🔍 [TOPUP BANK CTRL] Setting loading to true');
    setState(() {
      loading = true;
    });

    var requestUrl = apiUrl + '/deposit/send';
    var requestHeaders = {
      'content-type': 'application/json',
      'Authorization': bloc.token.valueWrapper?.value
    };
    var requestBody = {'nominal': parsedNominal, 'type': widget.payment.type};
    
    print('🔍 [TOPUP BANK CTRL] FULL API REQUEST DETAILS:');
    print('🔍 [TOPUP BANK CTRL] URL: $requestUrl');
    print('🔍 [TOPUP BANK CTRL] Headers: ${requestHeaders.toString()}');
    print('🔍 [TOPUP BANK CTRL] Body: ${requestBody.toString()}');
    print('🔍 [TOPUP BANK CTRL] Body JSON: ${jsonEncode(requestBody)}');
    
    http.Response response = await http.post(
        Uri.parse(requestUrl),
        headers: requestHeaders,
        body: jsonEncode(requestBody));

    print('🔍 [TOPUP BANK CTRL] API response status: ${response.statusCode}');
    print('🔍 [TOPUP BANK CTRL] FULL API RESPONSE PAYLOAD:');
    print('🔍 [TOPUP BANK CTRL] ${response.body}');
    
    if (response.statusCode == 200) {
      print('🔍 [TOPUP BANK CTRL] API request successful');
      var responseData = jsonDecode(response.body);
      print('🔍 [TOPUP BANK CTRL] FULL PARSED RESPONSE DATA:');
      print('🔍 [TOPUP BANK CTRL] ${responseData.toString()}');
      
      var data = responseData['data'];
      print('🔍 [TOPUP BANK CTRL] Transfer data: ${data.toString()}');
      print('🔍 [TOPUP BANK CTRL] Nominal transfer: ${data['nominal_transfer']}');
      print('🔍 [TOPUP BANK CTRL] Navigating to TransferDepositPage');
      
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TransferDepositPage(
              data['nominal_transfer'], widget.payment.type)));
    } else {
      print('🔍 [TOPUP BANK CTRL] API request failed');
      var errorData = json.decode(response.body);
      print('🔍 [TOPUP BANK CTRL] Error response: ${errorData.toString()}');
      
      String message = errorData['message'] ??
          'Terjadi kesalahan pada server';
      print('🔍 [TOPUP BANK CTRL] Error message: $message');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }

    print('🔍 [TOPUP BANK CTRL] Setting loading to false');
    setState(() {
      loading = false;
    });
    print('🔍 [TOPUP BANK CTRL] State updated');
  }
  }

