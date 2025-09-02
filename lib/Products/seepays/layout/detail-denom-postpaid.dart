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
import 'package:mobile/Products/seepays/layout/detail-denom-postpaid-controller.dart';
import 'package:mobile/screen/favorite-number/favorite-number.dart';

class SeepaysDetailDenomPostpaid extends StatefulWidget {
  final MenuModel menu;

  SeepaysDetailDenomPostpaid(this.menu);

  @override
  _SeepaysDetailDenomPostpaidState createState() => _SeepaysDetailDenomPostpaidState();
}

class _SeepaysDetailDenomPostpaidState extends SeepaysDetailDenomPostpaidController {
  bool activateContact = true;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Stack(children: <Widget>[
          Column(children: <Widget>[
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * .2,
              decoration: BoxDecoration(
                color: packageName == 'com.lariz.mobile'
                    ? Theme.of(context).secondaryHeaderColor
                    : Theme.of(context).primaryColor,
              ),
              child: menuLogoWidget(),
            ),
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  TextFormField(
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
                                      FavoriteNumber('postpaid')),
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
               SizedBox(height: 20),
               // Suggest Numbers untuk Seepays
               if (suggestNumbers.isNotEmpty && packageName == 'com.seepaysbiller.app')
                 Container(
                   width: double.infinity,
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         'Riwayat Transaksi:',
                         style: TextStyle(
                           fontWeight: FontWeight.bold,
                           fontSize: 14,
                         ),
                       ),
                       SizedBox(height: 8),
                       Wrap(
                         spacing: 8,
                         runSpacing: 8,
                         children: suggestNumbers
                             .map((number) => 
                               number == 'Belum pernah transaksi di produk ini'
                                 ? Container(
                                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                     decoration: BoxDecoration(
                                       color: Colors.grey[200],
                                       borderRadius: BorderRadius.circular(20),
                                     ),
                                     child: Text(
                                       number,
                                       style: TextStyle(
                                         fontSize: 12,
                                         color: Colors.grey[600],
                                         fontStyle: FontStyle.italic,
                                       ),
                                     ),
                                   )
                                 : ActionChip(
                                     label: Text(
                                       number,
                                       style: TextStyle(fontSize: 12),
                                     ),
                                     onPressed: () => selectSuggestNumber(number),
                                   )
                             )
                             .toList(),
                       ),
                     ],
                   ),
                 ),
               SizedBox(height: 20),
               Container(
                 width: double.infinity,
                 child: ElevatedButton(
                   style: ElevatedButton.styleFrom(
                     backgroundColor: packageName == 'com.lariz.mobile'
                         ? Theme.of(context).secondaryHeaderColor
                         : Theme.of(context).primaryColor,
                     padding: EdgeInsets.symmetric(vertical: 15),
                   ),
                   onPressed: () {
                     if (tujuan.text.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                           content: Text('Nomor tujuan harus diisi'),
                           backgroundColor: Colors.red,
                         ),
                       );
                       return;
                     }
                     inquiryPostpaid(widget.menu.kodeProduk, tujuan.text);
                   },
                   child: Text(
                     'Cek Tagihan',
                     style: TextStyle(
                       color: Colors.white,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 ),
               ),
             ],
           ),
         ),
            loading
                ? Expanded(
                    child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: Center(
                            child: CircularProgressIndicator(
                                color: packageName == 'com.lariz.mobile'
                                    ? Theme.of(context).secondaryHeaderColor
                                    : Theme.of(context).primaryColor))),
                  )
                : Expanded(
                    child: selectedDenom != null
                        ? Container(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(.1),
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Informasi Tagihan',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: packageName == 'com.lariz.mobile'
                                              ? Theme.of(context).secondaryHeaderColor
                                              : Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text('Nama: ${selectedDenom['nama'] ?? '-'}'),
                                      Text('No Pelanggan: ${selectedDenom['no_pelanggan'] ?? '-'}'),
                                      Text('Produk: ${selectedDenom['product'] ?? '-'}'),
                                      SizedBox(height: 10),
                                      Text(
                                        'Total Tagihan: ${formatRupiah(selectedDenom['total_tagihan'] ?? 0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.symmetric(vertical: 15),
                                    ),
                                    onPressed: () {
                                      // Implement payment logic here
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Fitur pembayaran akan segera tersedia'),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Bayar Tagihan',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'Klik tombol "Cek Tagihan" untuk melihat produk',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                  ),
          ]),
          // Floating action button removed for postpaid
          // Postpaid uses inquiry button instead
        ])),
    );
  }
} 