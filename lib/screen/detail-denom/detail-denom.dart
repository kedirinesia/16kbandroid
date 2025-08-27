// @dart=2.9

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mobile/bloc/ConfigApp.dart';
import 'package:mobile/bloc/TemplateConfig.dart';
import 'package:mobile/component/contact.dart';
import 'package:mobile/config.dart';
import 'package:mobile/models/menu.dart';
import 'package:mobile/models/favorite_number.dart';
import 'package:mobile/models/prepaid-denom.dart';
import 'package:mobile/modules.dart';
import 'package:mobile/screen/detail-denom/detail-denom-controller.dart';
import 'package:mobile/screen/transaksi/inquiry_prepaid.dart';
import 'package:mobile/screen/favorite-number/favorite-number.dart';

class DetailDenom extends StatefulWidget {
  final MenuModel menu;

  DetailDenom(this.menu); 

  @override
  _DetailDenomState createState() => _DetailDenomState();
}

class _DetailDenomState extends DetailDenomController {
  bool activateContact = true;

  @override
  Widget build(BuildContext context) {
    List<String> pkgNameLogoAppCoverList = [
      'com.eazyin.mobile',
    ];
    bool logoAppCover = pkgNameLogoAppCoverList.contains(packageName);
    List<String> pkgNameLogoMenuCoverList = [
      'ayoba.co.id',
      'mobile.payuni.id',
      'id.paymobileku.app',
      'popay.id',
      'com.popayfdn',
      'com.xenaja.app',
      'com.talentapay.android',
    ];
    bool operatorLogoCover = pkgNameLogoMenuCoverList.contains(packageName);

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
    //   }
    // });

    Widget operatorIcon() {
      if (operatorLogoCover) {
        if (coverIcon.isEmpty) {
          return SizedBox();
        } else {
          return Container(
            padding: EdgeInsets.all(40),
            child: CachedNetworkImage(
              imageUrl: coverIcon,
              height: 10,
            ),
          );
        }
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
            child: Stack(children: <Widget>[
              Column(children: <Widget>[
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * .2,
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
                  child: logoAppCover
                      ? Center(
                          child: CachedNetworkImage(
                            imageUrl: configAppBloc
                                .iconApp.valueWrapper?.value['logoLogin'],
                            width: MediaQuery.of(context).size.width * .4,
                          ),
                        )
                      : operatorIcon(),
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  child: packageName == 'com.eralink.mobileapk'
                      ? TextFormField(
                          controller: tujuan,
                          keyboardType: widget.menu.isString
                              ? TextInputType.text
                              : TextInputType.number,
                          cursorColor: Theme.of(context).primaryColor,
                          inputFormatters: [
                            widget.menu.isString
                                ? FilteringTextInputFormatter.allow(
                                    RegExp("[0-9a-zA-Z-_.#@!&*+,/?]"))
                                : FilteringTextInputFormatter.digitsOnly,
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
                            isDense: true,
                            labelText: 'Nomor Tujuan',
                            labelStyle: TextStyle(
                                color: Theme.of(context).secondaryHeaderColor),
                            prefixIcon: activateContact
                                ? InkWell(
                                    child: Icon(
                                      Icons.cached,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    onTap: () async {
                                      FavoriteNumberModel response =
                                          await Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                FavoriteNumber('prepaid')),
                                      );

                                      print(
                                          'response favorite-number -> $response');
                                      if (response == null) return;
                                      setState(() {
                                        tujuan.text = response.tujuan;
                                      });
                                    })
                                : Icon(Icons.phone),
                            suffixIcon: activateContact
                                ? InkWell(
                                    child: Icon(
                                      Icons.contacts,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    onTap: () {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(
                                              builder: (_) => ContactPage()))
                                          .then((nomor) {
                                        if (nomor != null) {
                                          tujuan.text = nomor;
                                        }
                                      });
                                    })
                                : SizedBox(),
                          ),
                        )
                      : TextFormField(
                          controller: tujuan,
                          keyboardType: widget.menu.isString
                              ? TextInputType.text
                              : TextInputType.number,
                          inputFormatters: [
                            widget.menu.isString
                                ? FilteringTextInputFormatter.allow(
                                    RegExp("[0-9a-zA-Z-_.#@!&*+,/?]"))
                                : FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(
                            fontWeight:
                                configAppBloc.boldNomorTujuan.valueWrapper.value
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            labelText: 'Nomor Tujuan',
                            prefixIcon: activateContact
                                ? InkWell(
                                    child: Icon(Icons.cached),
                                    onTap: () async {
                                      FavoriteNumberModel response =
                                          await Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                FavoriteNumber('prepaid')),
                                      );

                                      print(
                                          'response favorite-number -> $response');
                                      if (response == null) return;
                                      setState(() {
                                        tujuan.text = response.tujuan;
                                      });
                                    })
                                : Icon(Icons.phone),
                            suffixIcon: activateContact
                                ? InkWell(
                                    child: Icon(Icons.contacts),
                                    onTap: () {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(
                                              builder: (_) => ContactPage()))
                                          .then((nomor) {
                                        if (nomor != null) {
                                          tujuan.text = nomor;
                                        }
                                      });
                                    })
                                : SizedBox(),
                          ),
                        ),
                ),
                // Suggest number chips/list - EKSKLUSIF UNTUK SEEPAYS DAN PAYUNIOVO
                (packageName == 'com.seepaysbiller.app' || packageName == 'mobile.payuni.id' || packageName == 'co.payuni.id')
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
                                : Container(
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
                                            onPressed: () {
                                              setState(() {
                                                tujuan.text = suggestNumbers[index];
                                              });
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ],
                        ),
                      )
                    : SizedBox(),
                
                loading
                    ? Expanded(
                        child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            child: Center(
                                child: SpinKitThreeBounce(
                                    color: packageName == 'com.lariz.mobile'
                                        ? Theme.of(context).secondaryHeaderColor
                                        : Theme.of(context).primaryColor,
                                    size: 35))),
                      )
                    : Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(20),
                          itemCount: listDenom.length > 0 ? listDenom.length * 2 - 1 : 0,
                          itemBuilder: (ctx, i) {
                            if (i.isOdd) {
                              return SizedBox(height: 10);
                            }
                            int actualIndex = i ~/ 2;
                            PrepaidDenomModel denom = listDenom[actualIndex];
                            Color boxColor = selectedDenom != null
                                ? selectedDenom.id == denom.id
                                    ? packageName == 'com.lariz.mobile'
                                        ? Theme.of(context)
                                            .secondaryHeaderColor
                                            .withOpacity(.8)
                                        : Theme.of(context)
                                            .primaryColor
                                            .withOpacity(.8)
                                    : Colors.white
                                : Colors.white;
                            Color textColor = selectedDenom != null
                                ? selectedDenom.id == denom.id
                                    ? Colors.white
                                    : Colors.grey.shade700
                                : Colors.grey.shade700;
                            Color priceColor = selectedDenom != null
                                ? selectedDenom.id == denom.id
                                    ? Colors.white
                                    : Colors.green
                                : Colors.green;
                            return InkWell(
                              onTap: () => onTapDenom(denom),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    color: boxColor,
                                    borderRadius: BorderRadius.circular(10.0),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(.1),
                                          offset: Offset(5, 10.0),
                                          blurRadius: 20)
                                    ]),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    foregroundColor: packageName ==
                                            'com.lariz.mobile'
                                        ? Theme.of(context).secondaryHeaderColor
                                        : Theme.of(context).primaryColor,
                                    backgroundColor: selectedDenom != null
                                        ? selectedDenom.id == denom.id
                                            ? Colors.white
                                            : packageName == 'com.lariz.mobile'
                                                ? Theme.of(context)
                                                    .secondaryHeaderColor
                                                    .withOpacity(.1)
                                                : Theme.of(context)
                                                    .primaryColor
                                                    .withOpacity(.1)
                                        : packageName == 'com.lariz.mobile'
                                            ? Theme.of(context)
                                                .secondaryHeaderColor
                                                .withOpacity(.1)
                                            : Theme.of(context)
                                                .primaryColor
                                                .withOpacity(.1),
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: CachedNetworkImage(
                                        imageUrl: widget.menu.icon,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    denom.nama,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  subtitle: Text(
                                    denom.description ?? '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textColor,
                                    ),
                                  ),
                                  trailing: !denom.bebas_nominal
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: denom.harga_promo == null
                                              ? <Widget>[
                                                  Text(
                                                    formatRupiah(
                                                        denom.harga_jual),
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: priceColor,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      height: !configAppBloc
                                                              .displayGangguan
                                                              .valueWrapper
                                                              .value
                                                          ? 0
                                                          : denom.note.isEmpty
                                                              ? 0
                                                              : 5),
                                                  !configAppBloc.displayGangguan
                                                          .valueWrapper.value
                                                      ? SizedBox()
                                                      : denom.note.isEmpty
                                                          ? SizedBox()
                                                          : Container(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                vertical: 3,
                                                                horizontal: 5,
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: denom.note ==
                                                                        'gangguan'
                                                                    ? Colors.red
                                                                        .shade800
                                                                    : denom.note ==
                                                                            'lambat'
                                                                        ? Colors
                                                                            .amber
                                                                            .shade800
                                                                        : Colors
                                                                            .green
                                                                            .shade800,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            5),
                                                              ),
                                                              child: Text(
                                                                denom.note
                                                                    .toUpperCase(),
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                ]
                                              : <Widget>[
                                                  Text(
                                                    formatRupiah(
                                                        denom.harga_promo),
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: priceColor,
                                                    ),
                                                  ),
                                                  SizedBox(height: 3),
                                                  Text(
                                                    formatRupiah(
                                                        denom.harga_jual),
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      height: !configAppBloc
                                                              .displayGangguan
                                                              .valueWrapper
                                                              .value
                                                          ? 0
                                                          : denom.note.isEmpty
                                                              ? 0
                                                              : 3),
                                                  !configAppBloc.displayGangguan
                                                          .valueWrapper.value
                                                      ? SizedBox()
                                                      : denom.note.isEmpty
                                                          ? SizedBox()
                                                          : Container(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                vertical: 3,
                                                                horizontal: 5,
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: denom.note ==
                                                                        'gangguan'
                                                                    ? Colors.red
                                                                        .shade800
                                                                    : denom.note ==
                                                                            'lambat'
                                                                        ? Colors
                                                                            .amber
                                                                            .shade800
                                                                        : Colors
                                                                            .green
                                                                            .shade800,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            5),
                                                              ),
                                                              child: Text(
                                                                denom.note
                                                                    .toUpperCase(),
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                ],
                                        )
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                // SizedBox(height: 50)
              ]),
              Container(
                alignment: Alignment.bottomRight,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                margin: EdgeInsets.only(
                  bottom: packageName == 'com.flobamora.app' ? 70.0 : 0.0, // Margin khusus Flobamora
                ),
                child: selectedDenom == null
                    ? null
                    : FloatingActionButton.extended(
                        backgroundColor: packageName == 'com.lariz.mobile'
                            ? Theme.of(context).secondaryHeaderColor
                            : Theme.of(context).primaryColor,
                        icon: Icon(Icons.navigate_next),
                        label: Text('Beli'),
                        onPressed: () async {
                          if (tujuan.text.length < 4) return;

                          if (selectedDenom.bebas_nominal) {
                            await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => AlertDialog(
                                        title: Text('Nominal'),
                                        content: TextFormField(
                                            controller: nominal,
                                            keyboardType: TextInputType.number,
                                            autofocus: true,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            decoration: InputDecoration(
                                                prefixText: 'Rp  ',
                                                focusedBorder:
                                                    UnderlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color:
                                                                Colors.grey)))),
                                        actions: <Widget>[
                                          TextButton(
                                              child:
                                                  Text('Lanjut'.toUpperCase()),
                                              onPressed: () {
                                                if (nominal.text.isEmpty)
                                                  return;
                                                if (int.parse(nominal.text) <=
                                                    0) return;
                                                Navigator.of(ctx).pop();
                                                Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            InquiryPrepaid(
                                                                selectedDenom
                                                                    .kode_produk,
                                                                tujuan.text,
                                                                nominal: int
                                                                    .parse(nominal
                                                                        .text))));
                                              }),
                                          TextButton(
                                              child:
                                                  Text('Batal'.toUpperCase()),
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop())
                                        ]));
                          } else {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => InquiryPrepaid(
                                    selectedDenom.kode_produk, tujuan.text)));
                          }
                        },
                      ),
              )
            ])));
  }
}
