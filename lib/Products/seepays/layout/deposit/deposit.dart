// @dart=2.9

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/config.dart';
import 'package:mobile/models/deposit.dart';
import 'package:mobile/modules.dart';
import 'package:mobile/Products/seepays/layout/deposit/deposit-controller.dart';
import 'package:mobile/screen/transaksi/detail_deposit.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class DepositPage extends StatefulWidget {
  @override
  _DepositPageState createState() => _DepositPageState();
}

class _DepositPageState extends DepositController
    with TickerProviderStateMixin {
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  Widget build(BuildContext context) {
    print('🔍 [DEPOSIT] build() called');
    print('🔍 [DEPOSIT] Loading state: $loading');
    print('🔍 [DEPOSIT] ListDeposit length: ${listDeposit.length}');
    print('🔍 [DEPOSIT] Package name: $packageName');
    
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
        : listDeposit.length == 0
            ? Container(
                width: double.infinity,
                height: double.infinity,
                child: Center(
                    child: SvgPicture.asset('assets/img/empty.svg',
                        width: MediaQuery.of(context).size.width * .35)),
              )
            : SmartRefresher(
                controller: _refreshController,
                enablePullDown: true,
                enablePullUp: true,
                onRefresh: () async {
                  print('🔍 [DEPOSIT] Pull to refresh triggered');
                  print('🔍 [DEPOSIT] Resetting currentPage to 0');
                  currentPage = 0;
                  print('🔍 [DEPOSIT] Setting isEdge to false');
                  isEdge = false;
                  print('🔍 [DEPOSIT] Clearing listDeposit');
                  listDeposit.clear();
                  print('🔍 [DEPOSIT] Calling getData()');
                  await getData();
                  print('🔍 [DEPOSIT] Refresh completed, calling refreshCompleted()');
                  _refreshController.refreshCompleted();
                },
                onLoading: () async {
                  print('🔍 [DEPOSIT] Pull to load more triggered');
                  print('🔍 [DEPOSIT] Calling getData() for more items');
                  await getData();
                  print('🔍 [DEPOSIT] Load complete, calling loadComplete()');
                  _refreshController.loadComplete();
                },
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: ScrollPhysics(),
                  padding: EdgeInsets.symmetric(vertical: 10),
                  itemCount: listDeposit.length,
                  separatorBuilder: (_, i) => SizedBox(height: 10),
                  itemBuilder: (_, int index) {
                    print('🔍 [DEPOSIT] Building list item at index: $index');
                    DepositModel m = listDeposit[index];
                    print('🔍 [DEPOSIT] Deposit item - Nominal: ${m.nominal}, Status: ${m.statusModel.statusText}, Created: ${m.created_at}');
                    
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
                        onTap: () {
                          print('🔍 [DEPOSIT] Deposit item tapped at index: $index');
                          print('🔍 [DEPOSIT] Navigating to DetailDeposit with deposit: ${m.nominal} - ${m.statusModel.statusText}');
                          Navigator.of(context).push(
                            PageTransition(
                              child: DetailDeposit(m),
                              type: PageTransitionType.rippleMiddle,
                              duration: Duration(milliseconds: 10),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                            foregroundColor: packageName == 'com.lariz.mobile'
                                ? Theme.of(context).secondaryHeaderColor
                                : Theme.of(context).primaryColor,
                            backgroundColor: packageName == 'com.lariz.mobile'
                                ? Theme.of(context)
                                    .secondaryHeaderColor
                                    .withOpacity(.1)
                                : Theme.of(context)
                                    .primaryColor
                                    .withOpacity(.1),
                            child: m.statusModel?.icon != null && m.statusModel.icon.isNotEmpty
                                ? Image.asset(
                                    m.statusModel.icon,
                                    width: 20.0,
                                    height: 20.0,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('🔍 [DEPOSIT] Asset error for: ${m.statusModel.icon} - Exception: $error');
                                      return Icon(
                                        m.statusModel.status == 0 
                                            ? Icons.hourglass_empty 
                                            : m.statusModel.status == 1 
                                                ? Icons.check_circle 
                                                : Icons.error,
                                        size: 20.0,
                                        color: m.statusModel.color,
                                      );
                                    })
                                : Icon(
                                    m.statusModel?.status == 0 
                                        ? Icons.hourglass_empty 
                                        : m.statusModel?.status == 1 
                                            ? Icons.check_circle 
                                            : Icons.error,
                                    size: 20.0,
                                    color: m.statusModel?.color ?? Colors.grey,
                                  )),
                        title: Text(formatRupiah(m.nominal),
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            )),
                        subtitle: Text(
                            formatDate(m.created_at, "d MMMM yyyy HH:mm:ss") ??
                                ' ',
                            style: TextStyle(
                                fontSize: 10.0, color: Colors.grey.shade700)),
                        trailing: Text(m.statusModel.statusText,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: m.statusModel.color)),
                      ),
                    );
                  },
                ));
  }
}
