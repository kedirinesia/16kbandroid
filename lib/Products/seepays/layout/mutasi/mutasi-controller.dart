// @dart=2.9

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/bloc/ConfigApp.dart';
import 'dart:convert';
import 'package:mobile/models/mutasi.dart';
import 'package:mobile/modules.dart';
import 'package:mobile/provider/analitycs.dart';
import 'package:mobile/Products/seepays/layout/mutasi/mutasi.dart';
import 'package:http/http.dart' as http;
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:mobile/bloc/Bloc.dart' show bloc;
import 'package:mobile/bloc/Api.dart' show apiUrl;

abstract class MutasiController extends State<MutasiPage> {
  bool loadingNewPage = false;
  bool loading = true;
  bool isEdge = false;
  int currentPage = 0;
  DateTime startDate;
  DateTime endDate;
  String type;
  String tujuan;
  bool isExpanded = false;
  bool filtered = false;

  List<MutasiModel> listMutasi = [];
  RefreshController refreshController =
      RefreshController(initialRefresh: false);

  TextEditingController startDateText = TextEditingController();
  TextEditingController endDateText = TextEditingController();

  final List<DropdownMenuItem> typeList = [
    DropdownMenuItem(child: Text('Transaksi'), value: 'T'),
    DropdownMenuItem(child: Text('Deposit'), value: 'D'),
    DropdownMenuItem(child: Text('Transfer Saldo'), value: 'KS'),
    DropdownMenuItem(child: Text('Pemotongan Saldo'), value: 'P'),
    DropdownMenuItem(child: Text('Cashback'), value: 'C'),
    DropdownMenuItem(child: Text('Gagal'), value: 'G'),
    DropdownMenuItem(child: Text('Manual'), value: 'M'),
    DropdownMenuItem(child: Text('Semua Tipe'), value: 'ST'),
  ];

  @override
  void initState() {
    super.initState();
    analitycs.pageView('/history/mutasi',
        {'userId': bloc.userId.valueWrapper?.value, 'title': 'History Mutasi'});
    if (configAppBloc.autoReload.valueWrapper?.value) {
      Timer.periodic(new Duration(seconds: 1), (timer) => getData());
    } else {
      getData();
    }
    startDate = getCurrentDate();
    endDate = getCurrentDate();
    startDateText.text = formatDate(startDate.toIso8601String(), 'd MMM y');
    endDateText.text = formatDate(endDate.toIso8601String(), 'd MMM y');
  }

  @override
  void dispose() {
    startDateText.dispose();
    endDateText.dispose();
    super.dispose();
  }

  Future<void> getData() async {
    Map<String, dynamic> params = {};
    if (filtered) {
      params['tgl_awal'] = formatDate(startDate.toIso8601String(), 'd-M-y');
      params['tgl_akhir'] = formatDate(endDate.toIso8601String(), 'd-M-y');
      if (type != null && type != 'ST') params['type'] = type;
    }
    params['page'] = currentPage;

    List<String> listOfParams = [];
    params.forEach((key, value) {
      listOfParams.add('$key=$value');
    });
    String parameters = listOfParams.join('&');
    String url = '$apiUrl/mutasi/list?$parameters';

    print(url);

    if (isEdge) return;
    http.Response response = await http.get(Uri.parse(url),
        headers: {'Authorization': bloc.token.valueWrapper?.value});

    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body)['data'] as List;
      if (list.length == 0) isEdge = true;
      list.forEach((item) => listMutasi.add(MutasiModel.fromJson(item)));
      currentPage++;
    }

    if (this.mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void resetFilter() {
    setState(() {
      filtered = false;
      currentPage = 0;
      isEdge = false;
      listMutasi.clear();
      loading = true;
      startDate = getCurrentDate();
      endDate = getCurrentDate();
      startDateText.text = formatDate(startDate.toIso8601String(), 'd MMM y');
      endDateText.text = formatDate(endDate.toIso8601String(), 'd MMM y');
      type = null;
      tujuan = null;

      isExpanded = false;
    });

    getData();
  }

  void setFilter() async {
    setState(() {
      filtered = true;
      isExpanded = false;
      currentPage = 0;
      listMutasi.clear();
      isEdge = false;
      loading = true;
    });

    getData();
  }

  Future<void> setStartDate() async {
    DateTime newDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(1970, 1, 1),
      lastDate: getCurrentDate(),
      currentDate: getCurrentDate(),
      locale: Locale('id'),
      confirmText: 'PILIH',
      cancelText: 'BATAL',
      helpText: 'Tanggal Awal',
    );

    if (newDate == null) return;
    setState(() {
      startDate = newDate;
      startDateText.text = formatDate(startDate.toIso8601String(), 'd MMM y');
    });
  }

  Future<void> setEndDate() async {
    DateTime newDate = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: getCurrentDate(),
      currentDate: getCurrentDate(),
      locale: Locale('id'),
      confirmText: 'PILIH',
      cancelText: 'BATAL',
      helpText: 'Tanggal Akhir',
    );

    if (newDate == null) return;
    setState(() {
      endDate = newDate;
      endDateText.text = formatDate(endDate.toIso8601String(), 'd MMM y');
    });
  }
}
