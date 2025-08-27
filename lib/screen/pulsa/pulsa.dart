// @dart=2.9

import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mobile/bloc/Bloc.dart';
import 'package:mobile/bloc/ConfigApp.dart';
import 'package:mobile/bloc/TemplateConfig.dart';
import 'package:mobile/component/contact.dart';
import 'package:mobile/config.dart';
import 'package:mobile/models/menu.dart'; 
import 'package:mobile/models/pulsa.dart';
import 'package:mobile/models/favorite_number.dart';
import 'package:mobile/modules.dart';
import 'package:mobile/provider/analitycs.dart';
import 'package:mobile/screen/pulsa/pulsa-controller.dart';
import 'package:mobile/screen/transaksi/inquiry_prepaid.dart';
import 'package:mobile/screen/favorite-number/favorite-number.dart';

class Pulsa extends StatefulWidget {
  final MenuModel menuModel;

  Pulsa(this.menuModel);

  @override
  _PulsaState createState() => _PulsaState();
}

class _PulsaState extends PulsaController {
  bool logoAppCover = false;
  bool logoProductMenuCover = false;
  String operatorIcon = '';
  bool activateContact = true;

  @override
  void initState() {
    super.initState();
    analitycs.pageView('/pulsa', {
      'userId': bloc.userId.valueWrapper?.value,
      'title': 'Pulsa',
    });
  }

  @override
  Widget build(BuildContext context) {
    // List<String> pkgListActivateContact = [
    // 'id.payuni.mobile',
    // 'com.tapayment.mobile',
    // 'id.popay.app',
    // 'id.ndmmobile.apk',
    // 'com.staypay.app',
    // 'id.bisabayar.app',
    // 'com.phoenixpayment.app',
    // 'com.kingreloads.app',
    // 'com.mopay.mobile',
    // 'id.funmo.mobile',
    // 'id.yukpay.mobile',
    // 'id.pmpay.mobile',
    // 'id.paymobileku.app',
    // 'com.passpay.agenpulsamurah',
    // 'id.warungpayid.mobile',
    // 'ayoba.co.id',
    // 'com.ptspayment.mobile',
    // 'id.esaldoku.mobile',
    // 'id.akupay.mobile',
    // 'id.wallpayku.apk',
    // ];

    // pkgListActivateContact.forEach((element) {
    //   if (element == packageName) {
    //     activateContact = true;
    //   }
    // });

    List<String> pkgNameLogoAppCoverList = [
      'com.eazyin.mobile',
    ];

    pkgNameLogoAppCoverList.forEach((e) {
      if (e == packageName) logoAppCover = true;
    });

    List<Map<String, dynamic>> operatorTelp = [
      {
        'name': 'indosat',
        'prefix': '0814, 0815, 0816, 0855, 0856, 0857, 0858',
        'url': 'https://ayoba.co.id/dokumen/provider/indosat.png',
      },
      {
        'name': 'telkomsel',
        'prefix': '0811, 0812, 0813, 0821, 0822, 0823, 0852, 0853, 0851',
        'url': 'https://ayoba.co.id/dokumen/provider/tsel.png',
      },
      {
        'name': 'three',
        'prefix': '0895, 0896, 0897, 0898, 0899',
        'url': 'https://ayoba.co.id/dokumen/provider/three.png',
      },
      {
        'name': 'xl',
        'prefix': '0817, 0818, 0819, 0859, 0877, 0878',
        'url': 'https://ayoba.co.id/dokumen/provider/xl.png',
      },
      {
        'name': 'smartfren',
        'prefix': '0881, 0882, 0883, 0884, 0885, 0886, 0887, 0888, 0889',
        'url': 'https://ayoba.co.id/dokumen/provider/smart.png',
      },
      {
        'name': 'axis',
        'prefix': '0838, 0831, 0832, 0833',
        'url':
            // 'https://i.pinimg.com/originals/d0/31/31/d031314a78e8ac9d4b4ce2593698ee1f.png',
            'https://ayoba.co.id/dokumen/provider/axis.png',
      },
    ];

    List<String> pkgNameLogoMenuCoverList = [
      'ayoba.co.id',
      'com.eralink.mobileapk',
      'mobile.payuni.id',
      'id.paymobileku.app',
      'popay.id',
      'com.popayfdn',
      'com.xenaja.app',
      'com.talentapay.android',
    ];

    List<String> pkgNameIconMenuList = [
      'id.outletpay.mobile',
    ];

    var regex = new RegExp("\\b(?:$prefixNomor)\\b", caseSensitive: false);
    var find =
        operatorTelp.where((element) => regex.hasMatch(element['prefix']));

    if (find.isNotEmpty) {
      find.forEach((element) => operatorIcon = element['url']);
    } else {
      operatorIcon = '';
    }

    Widget operatorHeaderIcon() {
      if (operatorIcon.isNotEmpty) {
        return Container(
          padding: EdgeInsets.all(40),
          child: CachedNetworkImage(
            imageUrl: operatorIcon,
            height: 10,
          ),
        );
      } else {
        return SizedBox();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.menuModel.name),
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
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
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
                      : logoProductMenuCover
                          ? operatorHeaderIcon()
                          : null,
                ),
                Container(
                    padding: EdgeInsets.all(20),
                    child: packageName == 'com.eralink.mobileapk'
                        ? TextFormField(
                            controller: nomorHp,
                            keyboardType: TextInputType.number,
                            cursorColor: Theme.of(context).primaryColor,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
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
                                  color:
                                      Theme.of(context).secondaryHeaderColor),
                              prefixIcon: InkWell(
                                  child: Icon(
                                    Icons.cached,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  onTap: () async {
                                    FavoriteNumberModel response =
                                        await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            FavoriteNumber('prepaid'),
                                      ),
                                    );

                                    print(
                                        'response favorite-number -> $response');
                                    if (response == null) return;
                                    setState(() {
                                      nomorHp.text = response.tujuan;
                                    });

                                    if (response.tujuan.length >= 4 &&
                                        response.tujuan.startsWith('08')) {
                                      if (response.tujuan.substring(0, 4) !=
                                          prefixNomor) {
                                        setState(() {
                                          listDenom.clear();
                                          prefixNomor =
                                              response.tujuan.substring(0, 4);
                                          loading = true;
                                          pkgNameLogoMenuCoverList.forEach((e) {
                                            if (e == packageName)
                                              logoProductMenuCover = true;
                                          });
                                        });
                                        getDenom(response.tujuan);
                                      }
                                    }
                                  }),
                              suffixIcon: InkWell(
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
                                      nomorHp.text = nomor;
                                      getDenom(nomor);
                                    }
                                  });
                                },
                              ),
                            ),
                            style: TextStyle(
                              fontWeight: configAppBloc
                                      .boldNomorTujuan.valueWrapper.value
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onChanged: (str) {
                              if (str.length >= 4 && str.startsWith('08')) {
                                if (str.substring(0, 4) != prefixNomor) {
                                  setState(() {
                                    listDenom.clear();
                                    prefixNomor = str.substring(0, 4);
                                    loading = true;
                                    pkgNameLogoMenuCoverList.forEach((e) {
                                      if (e == packageName)
                                        logoProductMenuCover = true;
                                    });
                                  });
                                  getDenom(str);
                                }
                              }
                            },
                          )
                        : TextFormField(
                            controller: nomorHp,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              labelText: 'Nomor Tujuan',
                              prefixIcon: InkWell(
                                  child: Icon(Icons.cached),
                                  onTap: () async {
                                    FavoriteNumberModel response =
                                        await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            FavoriteNumber('prepaid'),
                                      ),
                                    );

                                    print(
                                        'response favorite-number -> $response');
                                    if (response == null) return;
                                    setState(() {
                                      nomorHp.text = response.tujuan;
                                    });

                                    if (response.tujuan.length >= 4 &&
                                        response.tujuan.startsWith('08')) {
                                      if (response.tujuan.substring(0, 4) !=
                                          prefixNomor) {
                                        setState(() {
                                          listDenom.clear();
                                          prefixNomor =
                                              response.tujuan.substring(0, 4);
                                          loading = true;
                                          pkgNameLogoMenuCoverList.forEach((e) {
                                            if (e == packageName)
                                              logoProductMenuCover = true;
                                          });
                                        });
                                        getDenom(response.tujuan);
                                      }
                                    }
                                  }),
                              suffixIcon: InkWell(
                                child: Icon(Icons.contacts),
                                onTap: () {
                                  Navigator.of(context)
                                      .push(MaterialPageRoute(
                                          builder: (_) => ContactPage()))
                                      .then((nomor) {
                                    if (nomor != null) {
                                      nomorHp.text = nomor;
                                      getDenom(nomor);
                                    }
                                  });
                                },
                              ),
                            ),
                            style: TextStyle(
                              fontWeight: configAppBloc
                                      .boldNomorTujuan.valueWrapper.value
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onChanged: (str) {
                              if (str.length >= 4 && str.startsWith('08')) {
                                if (str.substring(0, 4) != prefixNomor) {
                                  setState(() {
                                    listDenom.clear();
                                    prefixNomor = str.substring(0, 4);
                                    loading = true;
                                    pkgNameLogoMenuCoverList.forEach((e) {
                                      if (e == packageName)
                                        logoProductMenuCover = true;
                                    });
                                  });
                                  getDenom(str);
                                }
                              }
                            },
                          )),
                          
                          // Suggest number chips/list - EKSKLUSIF UNTUK SEEPAYS DAN PAYUNIOVO
                          (packageName == 'com.seepaysbiller.app' || packageName == 'mobile.payuni.id' || packageName == 'co.payuni.id')
                              ? Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
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
                                                      onPressed: () => selectSuggestNumber(suggestNumbers[index]),
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
                          height: 200,
                          child: Center(
                            child: SpinKitThreeBounce(
                                color: packageName == 'com.lariz.mobile'
                                    ? Theme.of(context).secondaryHeaderColor
                                    : Theme.of(context).primaryColor,
                                size: 35),
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(20),
                          itemCount: max(0, listDenom?.length * 2 - 1 ?? 0),
                          itemBuilder: (ctx, i) {
                            if (i.isOdd) {
                              return SizedBox(height: 10);
                            }
                            int actualIndex = i ~/ 2;
                            PulsaModel denom = listDenom[actualIndex];
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
                              onTap: () => selectDenom(denom),
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
                                        imageUrl: pkgNameIconMenuList
                                                .contains(packageName)
                                            ? operatorIcon
                                            : (denom.category
                                                        is KategoriPulsaModel &&
                                                    denom.category.iconUrl !=
                                                        null)
                                                ? denom.category.iconUrl
                                                : widget.menuModel.icon,
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
                                  subtitle: Text(denom.desc ?? '',
                                      style: TextStyle(
                                          fontSize: 10, color: textColor)),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: denom.hargaPromo == null
                                        ? <Widget>[
                                            Text(
                                              formatRupiah(denom.hargaJual),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
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
                                                      : 5,
                                            ),
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
                                                              ? Colors
                                                                  .red.shade800
                                                              : denom.note ==
                                                                      'lambat'
                                                                  ? Colors.amber
                                                                      .shade800
                                                                  : Colors.green
                                                                      .shade800,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                        child: Text(
                                                          denom.note
                                                              .toUpperCase(),
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                          ]
                                        : <Widget>[
                                            Text(
                                              formatRupiah(denom.hargaPromo),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: priceColor,
                                              ),
                                            ),
                                            SizedBox(height: 3),
                                            Text(
                                              formatRupiah(denom.hargaJual),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.grey,
                                                decoration:
                                                    TextDecoration.lineThrough,
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
                                                      : 3,
                                            ),
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
                                                              ? Colors
                                                                  .red.shade800
                                                              : denom.note ==
                                                                      'lambat'
                                                                  ? Colors.amber
                                                                      .shade800
                                                                  : Colors.green
                                                                      .shade800,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                        child: Text(
                                                          denom.note
                                                              .toUpperCase(),
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                          ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: selectedDenom == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: packageName == 'com.lariz.mobile'
                  ? Theme.of(context).secondaryHeaderColor
                  : Theme.of(context).primaryColor,
              foregroundColor:
                  Theme.of(context).floatingActionButtonTheme.foregroundColor,
              icon: Icon(Icons.navigate_next),
              label: Text('Beli'),
              onPressed: () {
                if (nomorHp.text.length > 3) {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => InquiryPrepaid(
                          selectedDenom.kodeProduk, nomorHp.text)));
                }
              },
            ),
    );
  }
}
