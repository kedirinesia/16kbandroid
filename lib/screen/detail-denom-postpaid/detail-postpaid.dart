// @dart=2.9

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/bloc/ConfigApp.dart';
import 'package:mobile/bloc/TemplateConfig.dart';
import 'package:mobile/component/contact.dart';
import 'package:mobile/config.dart';
import 'package:mobile/models/favorite_number.dart';
import 'package:mobile/models/menu.dart';
import 'package:mobile/modules.dart';
import 'package:mobile/screen/detail-denom-postpaid/detail-postpaid-controller.dart';
import 'package:mobile/screen/favorite-number/favorite-number.dart';

class DetailDenomPostpaid extends StatefulWidget {
  final MenuModel menu;

  DetailDenomPostpaid(this.menu);

  @override
  _DetailDenomPostpaidState createState() => _DetailDenomPostpaidState();
}

class _DetailDenomPostpaidState extends DetailDenomPostpaidController {
  bool activateContact = true;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // List<String> pkgListActivateContact = [
    //   'id.payuni.mobile',
    //   'com.tapayment.mobile',
    //   'id.popay.app',
    //   'id.ndmmobile.apk',
    //   'com.staypay.app',
    //   'id.bisabayar.app',
    //   'com.phoenixpayment.app',
    //   'com.kingreloads.app',
    //   'com.mopay.mobile',
    //   'id.funmo.mobile',
    //   'id.yukpay.mobile',
    //   'id.pmpay.mobile',
    //   'id.paymobileku.app',
    //   'com.passpay.agenpulsamurah',
    //   'id.warungpayid.mobile',
    //   'ayoba.co.id',
    //   'com.ptspayment.mobile',
    //   'id.esaldoku.mobile',
    //   'id.akupay.mobile',
    //   'id.wallpayku.apk',
    // ];

    // pkgListActivateContact.forEach((element) {
    //   if (element == packageName) {
    //     activateContact = true;
    //     boxFavorite = false;
    //   }
    // });

    List<String> pkgNameLogoMenuCoverList = [
      'ayoba.co.id',
      'mobile.payuni.id',
      'id.paymobileku.app',
    ];
    bool isUseMenuLogo = pkgNameLogoMenuCoverList.contains(packageName);

    Widget menuLogoWidget() {
      if (isUseMenuLogo && menuLogo.isNotEmpty) {
        return Container(
          padding: EdgeInsets.all(40),
          child: CachedNetworkImage(
            imageUrl: menuLogo,
            height: 10,
          ),
        );
      } else {
        return SizedBox();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.menu.name),
        centerTitle: true,
        elevation: 0,
        backgroundColor: packageName == 'com.lariz.mobile'
            ? Theme.of(context).secondaryHeaderColor
            : Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.home_rounded),
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) =>
                      configAppBloc.layoutApp?.valueWrapper?.value['home'] ??
                      templateConfig[
                          configAppBloc.templateCode.valueWrapper?.value],
                ),
                (route) => false),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height / 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    packageName == 'com.lariz.mobile'
                        ? Theme.of(context).secondaryHeaderColor
                        : Theme.of(context).primaryColor,
                    Theme.of(context).canvasColor
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: packageName == 'com.eazyin.mobile'
                  ? Center(
                      child: CachedNetworkImage(
                        imageUrl: configAppBloc
                            .iconApp.valueWrapper?.value['logoLogin'],
                        width: MediaQuery.of(context).size.width * .4,
                      ),
                    )
                  : menuLogoWidget(),
            ),
            Container(
              padding: EdgeInsets.all(20),
              child: packageName == 'com.eralink.mobileapk'
                  ? TextFormField(
                      controller: idpel,
                      keyboardType: widget.menu.isString
                          ? TextInputType.text
                          : TextInputType.number,
                      cursorColor: Theme.of(context).primaryColor,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp("[0-9a-zA-Z-_.]")),
                      ],
                      style: TextStyle(
                        fontWeight:
                            configAppBloc.boldNomorTujuan.valueWrapper.value
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor)),
                        labelText: 'Nomor Pelanggan',
                        labelStyle: TextStyle(
                          color: Theme.of(context).secondaryHeaderColor,
                        ),
                        isDense: true,
                        prefixIcon: InkWell(
                            child: Icon(
                              Icons.cached,
                              color: Theme.of(context).primaryColor,
                            ),
                            onTap: () async {
                              FavoriteNumberModel response =
                                  await Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => FavoriteNumber('postpaid')),
                              );

                              if (response == null) return;
                              setState(() {
                                idpel.text = response.tujuan;
                              });
                            }),
                        suffixIcon: InkWell(
                            child: Icon(
                              Icons.contacts,
                              color: Theme.of(context).primaryColor,
                            ),
                            onTap: () async {
                              idpel.text = await Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => ContactPage())) ??
                                  idpel.text;
                            }),
                      ),
                      onFieldSubmitted: (value) =>
                          cekTagihan(widget.menu.kodeProduk),
                    )
                  : TextFormField(
                      controller: idpel,
                      keyboardType: widget.menu.isString
                          ? TextInputType.text
                          : TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp("[0-9a-zA-Z-_.]")),
                      ],
                      style: TextStyle(
                        fontWeight:
                            configAppBloc.boldNomorTujuan.valueWrapper.value
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Nomor Pelanggan',
                        isDense: true,
                        prefixIcon: InkWell(
                            child: Icon(Icons.cached),
                            onTap: () async {
                              FavoriteNumberModel response =
                                  await Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => FavoriteNumber('postpaid')),
                              );

                              if (response == null) return;
                              setState(() {
                                idpel.text = response.tujuan;
                              });
                            }),
                        suffixIcon: InkWell(
                            child: Icon(Icons.contacts),
                            onTap: () async {
                              idpel.text = await Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => ContactPage())) ??
                                  idpel.text;
                            }),
                      ),
                      onFieldSubmitted: (value) =>
                          cekTagihan(widget.menu.kodeProduk),
                    ),
            ),
            
            // FITUR SUGGEST HISTORY NOMOR PEMBELI - EKSKLUSIF UNTUK PAYUNIOVO
            (packageName == 'mobile.payuni.id' || packageName == 'co.payuni.id')
                ? Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                        SizedBox(height: 4),
                        
                        // Loading State
                        loadingSuggest
                            ? Container(
                                width: double.infinity,
                                height: 40,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Loading History . . . ...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : suggestNumbers.isNotEmpty
                                ? Container(
                                    height: 40,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: suggestNumbers.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          margin: EdgeInsets.only(right: 8),
                                          child: ActionChip(
                                            label: Text(
                                              suggestNumbers[index],
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            backgroundColor: Colors.blue[50],
                                            labelStyle: TextStyle(color: Colors.blue[700]),
                                            onPressed: () => selectSuggestNumber(suggestNumbers[index]),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Container(
                                    height: 40,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.orange[600],
                                            size: 16,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Belum pernah transaksi produk ini',
                                            style: TextStyle(
                                              color: Colors.orange[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                      ],
                    ),
                  )
                : SizedBox(),
            
            Flexible(
              flex: 1,
              child: loading
                  ? loadingWidget()
                  : isChecked
                      ? ListView(
                          padding: EdgeInsets.all(20),
                          physics: ScrollPhysics(),
                          shrinkWrap: true,
                          children: <Widget>[
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10.0),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(.1),
                                          offset: Offset(5, 10.0),
                                          blurRadius: 20)
                                    ]),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text('Informasi Tagihan',
                                                style: TextStyle(
                                                    color: packageName ==
                                                            'com.lariz.mobile'
                                                        ? Theme.of(context)
                                                            .secondaryHeaderColor
                                                        : Theme.of(context)
                                                            .primaryColor,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            InkWell(
                                                child: Container(
                                                    padding: EdgeInsets.all(3),
                                                    child: Icon(
                                                      Icons.close,
                                                      color: packageName ==
                                                              'com.lariz.mobile'
                                                          ? Theme.of(context)
                                                              .secondaryHeaderColor
                                                          : Theme.of(context)
                                                              .primaryColor,
                                                    ),
                                                    decoration: BoxDecoration(
                                                        color: packageName ==
                                                                'com.lariz.mobile'
                                                            ? Theme.of(context)
                                                                .secondaryHeaderColor
                                                                .withOpacity(.2)
                                                            : Theme.of(context)
                                                                .primaryColor
                                                                .withOpacity(
                                                                    .2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15))),
                                                onTap: () {
                                                  setState(() {
                                                    idpel.clear();
                                                    isChecked = false;
                                                    inq = null;
                                                  });
                                                })
                                          ]),
                                      Divider(),
                                      SizedBox(height: 10),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text('Produk',
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 11)),
                                            Text(inq.produk,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))
                                          ]),
                                      SizedBox(height: 10),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text('Nomor Pelanggan',
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 11)),
                                            Text(inq.noPelanggan,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))
                                          ]),
                                      SizedBox(height: 10),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text('Nama Pelanggan',
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 11)),
                                            Text(inq.nama,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))
                                          ]),
                                      ListView.builder(
                                          shrinkWrap: true,
                                          physics: ScrollPhysics(),
                                          itemCount: inq.params.length,
                                          itemBuilder: (_, int index) {
                                            return Container(
                                              margin:
                                                  EdgeInsets.only(top: 10.0),
                                              child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: <Widget>[
                                                    Text(
                                                        inq.params[index]
                                                                ['label']
                                                            .toString(),
                                                        style: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 11)),
                                                    SizedBox(width: 5),
                                                    Flexible(
                                                      flex: 1,
                                                      child: Text(
                                                          inq.params[index]
                                                                  ['value']
                                                              .toString(),
                                                          overflow:
                                                              TextOverflow.clip,
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    )
                                                  ]),
                                            );
                                          }),
                                      SizedBox(height: 10),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text('Tagihan',
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 11)),
                                            Text(formatRupiah(inq.tagihan),
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))
                                          ]),
                                      SizedBox(height: 10),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text('Biaya Admin',
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 11)),
                                            Text(formatRupiah(inq.admin),
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))
                                          ]),
                                      SizedBox(height: 10),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text('Cashback',
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 11)),
                                            Text(formatRupiah(inq.fee),
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))
                                          ]),
                                      Divider(),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text('Total Tagihan',
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 11)),
                                            Text(formatRupiah(inq.total),
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green))
                                          ]),
                                      SizedBox(height: 10),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text('Total Bayar',
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 11)),
                                            Text(
                                                formatRupiah(
                                                    inq.total - inq.fee),
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green))
                                          ]),
                                      SizedBox(height: 50.0)
                                    ]),
                              ),
                              SizedBox(height: boxFavorite ? 15.0 : 0.0),
                              boxFavorite
                                  ? formFavorite()
                                  : SizedBox(height: 0.0),
                            ])
                      : SizedBox(width: 0, height: 0),
            ),
          ],
        ),
      ),
      floatingActionButton: loading
          ? null
          : FloatingActionButton.extended(
              backgroundColor: packageName == 'com.lariz.mobile'
                  ? Theme.of(context).secondaryHeaderColor
                  : Theme.of(context).primaryColor,
              label: Text(isChecked ? 'Bayar' : 'Cek Tagihan'),
              icon: Icon(Icons.navigate_next),
              onPressed: () {
                if (isChecked) {
                  bayar();
                } else {
                  cekTagihan(widget.menu.kodeProduk);
                }
              }),
    );
  }
}
