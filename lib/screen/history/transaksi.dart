// @dart=2.9

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/bloc/Api.dart';
import 'package:mobile/bloc/Bloc.dart';
import 'package:mobile/component/alert.dart';
import 'package:mobile/config.dart';
import 'package:mobile/models/trx.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/modules.dart';
import 'package:mobile/provider/analitycs.dart';
import 'package:mobile/screen/transaksi/detail_transaksi.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class HistoryTransaksi extends StatefulWidget {
  const HistoryTransaksi({key}) : super(key: key);

  @override
  _HistoryTransaksiState createState() => _HistoryTransaksiState();
}

class _HistoryTransaksiState extends State<HistoryTransaksi> {
  RefreshController refreshController =
      RefreshController(initialRefresh: false);

  TextEditingController startDateText = TextEditingController();
  TextEditingController endDateText = TextEditingController();
  TextEditingController tujuanText = TextEditingController();
  final List<DropdownMenuItem> statusList = [
    DropdownMenuItem(child: Text('Pending'), value: 0),
    DropdownMenuItem(child: Text('Sukses'), value: 2),
    DropdownMenuItem(child: Text('Gagal'), value: 3),
    DropdownMenuItem(child: Text('Semua Status'), value: 4),
  ];
  DateTime startDate;
  DateTime endDate;
  int status;
  int currentPage = 0;
  String tujuan;
  bool isEdge = false;
  bool loading = true;
  bool isExpanded = false;
  bool filtered = false;
  List<TrxModel> listTrx = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    startDateText.dispose();
    endDateText.dispose();
    tujuanText.dispose();
    super.dispose();
  }

  void init() {
    // FIREBASE ANALYTICS
    analitycs.pageView(
      '/history/transaksi',
      {
        'userId': bloc.userId.valueWrapper?.value,
        'title': 'History Transaksi',
      },
    );
    // FIREBASE ANALYTICS

    startDate = getCurrentDate();
    endDate = getCurrentDate();
    startDateText.text = formatDate(startDate.toIso8601String(), 'd MMM y');
    endDateText.text = formatDate(endDate.toIso8601String(), 'd MMM y');
    getData();
  }

  Future<void> getData() async {
    Map<String, dynamic> params = {};
    if (filtered) {
      params['tgl_akhir'] = formatDate(endDate.toIso8601String(), 'd-M-y');
      params['tgl_awal'] = formatDate(startDate.toIso8601String(), 'd-M-y');
      if (status != null && status != 4) params['status'] = status.toString();
      if (tujuan != null && tujuan.isNotEmpty) params['tujuan'] = tujuan;
    }
    params['page'] = currentPage;

    List<String> listOfParams = [];
    params.forEach((key, value) {
      listOfParams.add('$key=$value');
    });
    String parameters = listOfParams.join('&');
    String url = '$apiUrl/trx/list?$parameters';
    print(url);
    print(bloc.token.valueWrapper?.value);

    http.Response response = await http.get(Uri.parse(url), headers: {
      'Authorization': bloc.token.valueWrapper?.value,
    });

    if (response.statusCode == 200) {
      print(response.body);
      List<dynamic> datas = json.decode(response.body)['data'];
      if (datas.length == 0) isEdge = true;
      listTrx.addAll(datas.map((e) => TrxModel.fromJson(e)).toList());
      currentPage++;
    } else {
      String message = json.decode(response.body)['message'] ??
          'Terjadi kesalahan saat mengambil data';
      ScaffoldMessenger.of(context).showSnackBar(Alert(
        message,
        isError: true,
      ));
    }

    setState(() {
      loading = false;
    });
  }

  void resetFilter() {
    setState(() {
      filtered = false;
      currentPage = 0;
      isEdge = false;
      listTrx.clear();
      loading = true;
      startDate = getCurrentDate();
      endDate = getCurrentDate();
      startDateText.text = formatDate(startDate.toIso8601String(), 'd MMM y');
      endDateText.text = formatDate(endDate.toIso8601String(), 'd MMM y');
      status = null;
      tujuan = null;
      tujuanText.clear();

      isExpanded = false;
    });

    getData();
  }

  void setFilter() {
    setState(() {
      filtered = true;
      tujuan = tujuanText.text;
      isExpanded = false;
      currentPage = 0;
      listTrx.clear();
      isEdge = false;
      loading = true;
    });

    getData();
  }

  Widget _buildProductLogo(TrxModel trx) {
    // Cek apakah ada logo produk dari kategori
    String productLogoUrl;
    
    if (trx.produk != null && 
        trx.produk['kategori_id'] != null && 
        trx.produk['kategori_id']['url_image'] != null &&
        trx.produk['kategori_id']['url_image'].toString().isNotEmpty) {
      productLogoUrl = trx.produk['kategori_id']['url_image'];
    } else {
      productLogoUrl = '';
    }
    
    // Jika ada logo produk, gunakan itu, jika tidak gunakan gambar "no image"
    if (productLogoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: productLogoUrl,
        width: 20,
        height: 20,
        fit: BoxFit.contain,
        placeholder: (context, url) => Icon(
          Icons.image,
          size: 20,
          color: trx.statusModel.color,
        ),
        errorWidget: (context, url, error) => CachedNetworkImage(
          imageUrl: 'https://png.pngtree.com/png-vector/20190820/ourmid/pngtree-no-image-vector-illustration-isolated-png-image_1694547.jpg',
          width: 20,
          height: 20,
          fit: BoxFit.contain,
          
          errorWidget: (context, url, error) => Icon(
            Icons.image,
            size: 20,
            color: Colors.grey,
          ),
        ),
      );
    } else {
      // Gunakan gambar "no image" jika tidak ada logo produk
      return CachedNetworkImage(
        imageUrl: 'https://png.pngtree.com/png-vector/20190820/ourmid/pngtree-no-image-vector-illustration-isolated-png-image_1694547.jpg',
        width: 20,
        height: 20,
        fit: BoxFit.contain,
        placeholder: (context, url) => Icon(
          Icons.image,
          size: 20,
          color: Colors.grey,
        ),
        errorWidget: (context, url, error) => Icon(
          Icons.image,
          size: 20,
          color: Colors.grey,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return loading
        ? Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.all(15),
            child: Center(
              child: SpinKitThreeBounce(
                color: packageName == 'com.lariz.mobile'
                    ? Theme.of(context).secondaryHeaderColor
                    : Theme.of(context).primaryColor,
                size: 30,
              ),
            ),
          )
        : Column(
            children: [
              ExpansionPanelList(
                elevation: 0,
                children: [
                  ExpansionPanel(
                    headerBuilder: (_, expanded) => Container(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        'Filter Transaksi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: packageName == 'com.lariz.mobile' ||
                                  packageName == 'com.eralink.mobileapk'
                              ? Theme.of(context).secondaryHeaderColor
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    body: Container(
                      padding: EdgeInsets.all(10),
                      color: packageName == 'com.lariz.mobile'
                          ? Theme.of(context)
                              .secondaryHeaderColor
                              .withOpacity(.05)
                          : Theme.of(context).primaryColor.withOpacity(.05),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          packageName == 'com.eralink.mobileapk'
                              ? DropdownButtonFormField(
                                  iconEnabledColor:
                                      Theme.of(context).primaryColor,
                                  items: statusList,
                                  value: status,
                                  decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 15,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .primaryColor)),
                                      focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .primaryColor)),
                                      hintText: 'Status Transaksi',
                                      hintStyle: TextStyle(
                                          color: Theme.of(context)
                                              .secondaryHeaderColor)),
                                  onChanged: (val) => setState(() {
                                    status = val;
                                  }),
                                )
                              : DropdownButtonFormField(
                                  items: statusList,
                                  value: status,
                                  decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 15,
                                      ),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: packageName ==
                                                  'com.lariz.mobile'
                                              ? Theme.of(context)
                                                  .secondaryHeaderColor
                                              : Theme.of(context).primaryColor,
                                          width: 1,
                                        ),
                                      ),
                                      hintText: 'Status Transaksi',
                                      hintStyle:
                                          packageName == 'com.lariz.mobile'
                                              ? TextStyle(
                                                  color: Theme.of(context)
                                                      .secondaryHeaderColor)
                                              : null),
                                  onChanged: (val) => setState(() {
                                    status = val;
                                  }),
                                ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: packageName == 'com.eralink.mobileapk'
                                    ? TextField(
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .secondaryHeaderColor),
                                        controller: startDateText,
                                        readOnly: true,
                                        textAlign: TextAlign.center,
                                        onTap: setStartDate,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 15,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Theme.of(context)
                                                      .primaryColor)),
                                          focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Theme.of(context)
                                                      .primaryColor)),
                                        ),
                                      )
                                    : TextField(
                                        controller: startDateText,
                                        readOnly: true,
                                        textAlign: TextAlign.center,
                                        onTap: setStartDate,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 15,
                                          ),
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: packageName ==
                                                      'com.lariz.mobile'
                                                  ? Theme.of(context)
                                                      .secondaryHeaderColor
                                                  : Theme.of(context)
                                                      .primaryColor,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              Text(
                                '  -  ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: packageName == 'com.eralink.mobileapk'
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                                ),
                              ),
                              Expanded(
                                child: packageName == 'com.eralink.mobileapk'
                                    ? TextField(
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .secondaryHeaderColor),
                                        controller: endDateText,
                                        readOnly: true,
                                        textAlign: TextAlign.center,
                                        onTap: setEndDate,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 15,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Theme.of(context)
                                                      .primaryColor)),
                                          focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Theme.of(context)
                                                      .primaryColor)),
                                        ),
                                      )
                                    : TextField(
                                        controller: endDateText,
                                        readOnly: true,
                                        textAlign: TextAlign.center,
                                        onTap: setEndDate,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 15,
                                          ),
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: packageName ==
                                                      'com.lariz.mobile'
                                                  ? Theme.of(context)
                                                      .secondaryHeaderColor
                                                  : Theme.of(context)
                                                      .primaryColor,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          packageName == 'com.eralink.mobileapk'
                              ? TextField(
                                  controller: tujuanText,
                                  cursorColor: Theme.of(context).primaryColor,
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 15,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .primaryColor)),
                                      focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .primaryColor)),
                                      hintText: 'Nomor Tujuan',
                                      hintStyle: TextStyle(
                                          color: Theme.of(context)
                                              .secondaryHeaderColor)),
                                )
                              : TextField(
                                  controller: tujuanText,
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 15,
                                      ),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: packageName ==
                                                  'com.lariz.mobile'
                                              ? Theme.of(context)
                                                  .secondaryHeaderColor
                                              : Theme.of(context).primaryColor,
                                          width: 1,
                                        ),
                                      ),
                                      hintText: 'Nomor Tujuan',
                                      hintStyle:
                                          packageName == 'com.lariz.mobile'
                                              ? TextStyle(
                                                  color: Theme.of(context)
                                                      .secondaryHeaderColor)
                                              : null),
                                ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: packageName == 'com.eralink.mobileapk'
                                    ? OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                          color: Theme.of(context).primaryColor,
                                        )),
                                        child: Text(
                                          'ATUR ULANG',
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        onPressed: resetFilter,
                                      )
                                    : OutlinedButton(
                                        child: Text(
                                          'ATUR ULANG',
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        onPressed: resetFilter,
                                      ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: packageName == 'com.eralink.mobileapk'
                                    ? OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                                color: Theme.of(context)
                                                    .primaryColor)),
                                        child: Text(
                                          'ATUR FILTER',
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onPressed: setFilter,
                                      )
                                    : OutlinedButton(
                                        child: Text(
                                          'ATUR FILTER',
                                          style: TextStyle(
                                            color: packageName ==
                                                    'com.lariz.mobile'
                                                ? Theme.of(context)
                                                    .secondaryHeaderColor
                                                : Theme.of(context)
                                                    .primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onPressed: setFilter,
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    isExpanded: isExpanded,
                    canTapOnHeader: true,
                  ),
                ],
                expansionCallback: (_, __) {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
              ),
              listTrx.isNotEmpty
                  ? Expanded(
                      child: SmartRefresher(
                        controller: refreshController,
                        enablePullUp: true,
                        enablePullDown: true,
                        onRefresh: () async {
                          currentPage = 0;
                          isEdge = false;
                          listTrx.clear();
                          await getData();
                          refreshController.refreshCompleted();
                        },
                        onLoading: () async {
                          await getData();
                          refreshController.loadComplete();
                        },
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: ScrollPhysics(),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          itemCount: listTrx.length,
                          separatorBuilder: (_, __) => SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            TrxModel trx = listTrx[i];

                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.grey.withOpacity(.5),
                                        offset: Offset(3, 3),
                                        blurRadius: 15)
                                  ]),
                              child: ListTile(
                                // onTap: () {
                                //   if (trx != null) {
                                //     Navigator.of(context).push(
                                //       MaterialPageRoute(
                                //         builder: (_) => DetailTransaksi(
                                //             data: trx,
                                //             isPostpaid:
                                //                 trx.produk['type'] == 1),
                                //       ),
                                //     );
                                //   } else {
                                //     debugPrint('Error: trx object is null');
                                //   }
                                // },
                                // onTap: () {
                                //   if (trx != null &&
                                //       trx.produk != null &&
                                //       trx.produk.containsKey('type')) {
                                //     Navigator.of(context).push(
                                //       MaterialPageRoute(
                                //         builder: (_) => DetailTransaksi(
                                //             data: trx,
                                //             isPostpaid:
                                //                 trx.produk['type'] == 1),
                                //       ),
                                //     );
                                //   } else {
                                //     showCustomDialog(
                                //       context: context,
                                //       type: DialogType.error,
                                //       title: 'Produk Tidak Ditemukan',
                                //       content:
                                //           'Maaf, Produk Yang Anda Pilih Tidak Ditemukan',
                                //     );
                                //     debugPrint(
                                //         'Error: Produk tidak ditemukan atau telah dihapus');
                                //   }
                                // },
                                onTap: () {
                                  return Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DetailTransaksi(trx),
                                    ),
                                  );
                                },

                                leading: CircleAvatar(
                                  foregroundColor: packageName ==
                                          'com.lariz.mobile'
                                      ? Theme.of(context).secondaryHeaderColor
                                      : Theme.of(context).primaryColor,
                                  backgroundColor:
                                      trx.statusModel.color.withOpacity(.1),
                                  child: _buildProductLogo(trx),
                                ),
                                title: Text(
                                  trx.tujuan,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                subtitle: Text(
                                  trx.produk == null ? '-' : trx.produk['nama'],
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 10.0,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                trailing: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Hero(
                                      tag: 'harga-${trx.id}',
                                      child: Text(
                                        formatRupiah(trx.harga_jual),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      trx.statusModel.statusText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: trx.statusModel.color,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : Expanded(
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/img/empty.svg',
                            width: MediaQuery.of(context).size.width * .35,
                          ),
                        ),
                      ),
                    ),
            ],
          );
  }
}
