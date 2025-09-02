// @dart=2.9

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile/models/menu.dart';
import 'package:mobile/provider/analitycs.dart';
import 'package:mobile/screen/detail-denom-postpaid/detail-postpaid.dart';
import 'package:mobile/screen/detail-denom/detail-denom.dart';
import 'package:mobile/Products/seepays/layout/detail-denom.dart';
import 'package:mobile/Products/seepays/layout/detail-denom-postpaid.dart';
import 'package:mobile/screen/dynamic-prepaid/dynamic-denom.dart';
import 'package:mobile/Products/seepays/layout/list-sub-menu.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/bloc/Bloc.dart' show bloc;
import 'package:mobile/bloc/Api.dart' show apiUrl;

abstract class ListSubMenuController extends State<ListSubMenu>
    with TickerProviderStateMixin {
  bool loading = true;
  MenuModel currentMenu;
  List<MenuModel> listMenu = [];
  List<MenuModel> tempMenu = [];
  TextEditingController query = TextEditingController();

  bool isProductIconMenu = false;

  @override
  void initState() {
    super.initState();
    currentMenu = widget.menuModel;
    analitycs.pageView('/menu/' + currentMenu.id, {
      'userId': bloc.userId.valueWrapper?.value,
      'title': 'Buka Menu ' + currentMenu.name
    });
    getData();
  }

  getData() async {
    setState(() {
      loading = true;
    });

    String apiEndpoint = '$apiUrl/menu/${currentMenu.id}/child';
    print('🌐 ListSubMenu API Endpoint: $apiEndpoint');
    
    http.Response response = await http.get(
        Uri.parse(apiEndpoint),
        headers: {'Authorization': bloc.token.valueWrapper?.value});

    print('📡 ListSubMenu Response Status: ${response.statusCode}');
    print('📡 ListSubMenu Response Body: ${response.body}');

    if (response.statusCode == 200) {
      List<MenuModel> lm = (jsonDecode(response.body)['data'] as List)
          .map((m) => MenuModel.fromJson(m))
          .toList();
      
      print('📊 ListSubMenu: ${lm.length} sub-menu items found');
      for (MenuModel menu in lm) {
        print('📋 Sub-menu: ${menu.name} | type: ${menu.type} | category_id: "${menu.category_id}" | kodeProduk: "${menu.kodeProduk}"');
      }
      
      tempMenu = lm;
      listMenu = lm;
    } else {
      listMenu = [];
    }

    setState(() {
      loading = false;
    });
  }

  onTapMenu(MenuModel menu) async {
    print('📌 ListSubMenu Menu diklik: ${menu.name} | type: ${menu.type} | category_id: "${menu.category_id}" | kodeProduk: "${menu.kodeProduk}"');
    
    if (menu.category_id.isNotEmpty && menu.type == 1) {
      print('➡️ ListSubMenu menuju ke: SeepaysDetailDenom (Prepaid)');
      return Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SeepaysDetailDenom(menu),
        ),
      );
    } else if (menu.kodeProduk.isNotEmpty && menu.type == 2) {
      print('➡️ ListSubMenu menuju ke: SeepaysDetailDenomPostpaid (Postpaid)');
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => SeepaysDetailDenomPostpaid(menu)));
    } else if (menu.category_id.isEmpty) {
      if (menu.type == 3) {
        print('➡️ ListSubMenu menuju ke: DynamicPrepaidDenom');
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => DynamicPrepaidDenom(menu)));
      } else {
        print('➡️ ListSubMenu menuju ke: ListSubMenu (nested)');
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => ListSubMenu(menu)));
      }
    } else {
      print('❌ ListSubMenu: Menu tidak memenuhi kondisi routing apapun');
    }
  }
} 