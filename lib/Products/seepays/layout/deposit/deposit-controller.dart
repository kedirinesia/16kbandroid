// @dart=2.9

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/bloc/ConfigApp.dart';
import 'dart:convert';
import 'package:mobile/models/deposit.dart';
import 'package:mobile/provider/analitycs.dart';
import 'package:mobile/Products/seepays/layout/deposit/deposit.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/bloc/Bloc.dart' show bloc;
import 'package:mobile/bloc/Api.dart' show apiUrl;

abstract class DepositController extends State<DepositPage> {
  bool loadingNewPage = false;
  bool loading = true;
  bool isEdge = false;
  int limit = 20;
  int currentPage = 0;
  List<DepositModel> listDeposit = [];

  @override
  void initState() {
    super.initState();
    print('🔍 [DEPOSIT] initState called');
    print('🔍 [DEPOSIT] User ID: ${bloc.userId.valueWrapper?.value}');
    print('🔍 [DEPOSIT] Auto reload enabled: ${configAppBloc.autoReload.valueWrapper?.value}');
    
    var analyticsData = {
      'userId': bloc.userId.valueWrapper?.value,
      'title': 'History Deposit'
    };
    print('🔍 [DEPOSIT] Analytics payload: ${analyticsData.toString()}');
    analitycs.pageView('/history/deposit', analyticsData);
    print('🔍 [DEPOSIT] Analytics page view sent');

    if (configAppBloc.autoReload.valueWrapper?.value) {
      print('🔍 [DEPOSIT] Setting up periodic timer for auto reload');
      Timer.periodic(new Duration(seconds: 1), (timer) {
        print('🔍 [DEPOSIT] Auto reload timer triggered');
        getData();
      });
    } else {
      print('🔍 [DEPOSIT] Auto reload disabled, calling getData once');
      getData();
    }
  }

  getData() async {
    print('🔍 [DEPOSIT] getData() called');
    print('🔍 [DEPOSIT] Current page: $currentPage, Limit: $limit, Is edge: $isEdge');
    
    if (isEdge) {
      print('🔍 [DEPOSIT] Reached edge, returning early');
      return;
    }
    
    var requestUrl = '$apiUrl/deposit/list?page=$currentPage&limit=$limit';
    var requestHeaders = {'Authorization': bloc.token.valueWrapper?.value};
    
    print('🔍 [DEPOSIT] FULL API REQUEST DETAILS:');
    print('🔍 [DEPOSIT] URL: $requestUrl');
    print('🔍 [DEPOSIT] Headers: ${requestHeaders.toString()}');
    print('🔍 [DEPOSIT] Token: ${bloc.token.valueWrapper?.value?.substring(0, 20)}...');
    
    http.Response response = await http.get(
        Uri.parse(requestUrl),
        headers: requestHeaders);

    print('🔍 [DEPOSIT] API response status: ${response.statusCode}');
    print('🔍 [DEPOSIT] API response body length: ${response.body.length}');
    print('🔍 [DEPOSIT] FULL API RESPONSE PAYLOAD:');
    print('🔍 [DEPOSIT] ${response.body}');

    if (response.statusCode == 200) {
      print('🔍 [DEPOSIT] API request successful');
      var responseData = jsonDecode(response.body);
      print('🔍 [DEPOSIT] FULL PARSED RESPONSE DATA:');
      print('🔍 [DEPOSIT] ${responseData.toString()}');
      
      List<dynamic> list = responseData['data'] as List;
      print('🔍 [DEPOSIT] Received ${list.length} deposit items');
      
      if (list.length == 0) {
        print('🔍 [DEPOSIT] No more data, setting isEdge to true');
        isEdge = true;
      }
      
      print('🔍 [DEPOSIT] Current listDeposit length before adding: ${listDeposit.length}');
      list.forEach((item) {
        print('🔍 [DEPOSIT] Processing deposit item: ${item.toString().substring(0, 100)}...');
        listDeposit.add(DepositModel.fromJson(item));
      });
      print('🔍 [DEPOSIT] ListDeposit length after adding: ${listDeposit.length}');
      
      currentPage++;
      print('🔍 [DEPOSIT] Incremented currentPage to: $currentPage');
    } else {
      print('🔍 [DEPOSIT] API request failed with status: ${response.statusCode}');
      print('🔍 [DEPOSIT] Error response: ${response.body}');
    }

    if (this.mounted) {
      print('🔍 [DEPOSIT] Widget is mounted, updating state');
      setState(() {
        loading = false;
      });
      print('🔍 [DEPOSIT] State updated, loading set to false');
    } else {
      print('🔍 [DEPOSIT] Widget not mounted, skipping setState');
    }
  }
}
