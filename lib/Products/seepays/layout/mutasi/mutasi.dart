// @dart=2.9

import 'package:flutter/material.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/config.dart';
import 'package:mobile/models/mutasi.dart';
import 'package:mobile/modules.dart';
import 'package:mobile/Products/seepays/layout/mutasi/mutasi-controller.dart';
import 'package:mobile/screen/transaksi/detail_mutasi.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class MutasiPage extends StatefulWidget {
  @override
  _MutasiPageState createState() => _MutasiPageState();
}

class _MutasiPageState extends MutasiController with TickerProviderStateMixin {
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
                        'Filter Mutasi',
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
                                  items: typeList,
                                  value: type,
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
                                      hintText: 'Tipe Mutasi',
                                      hintStyle: TextStyle(
                                          color: Theme.of(context)
                                              .secondaryHeaderColor)),
                                  onChanged: (val) => setState(() {
                                    type = val;
                                  }),
                                )
                              : DropdownButtonFormField(
                                  items: typeList,
                                  value: type,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 15,
                                    ),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: packageName == 'com.lariz.mobile'
                                            ? Theme.of(context)
                                                .secondaryHeaderColor
                                            : Theme.of(context).primaryColor,
                                        width: 1,
                                      ),
                                    ),
                                    hintText: 'Tipe Mutasi',
                                    hintStyle: packageName == 'com.lariz.mobile'
                                        ? TextStyle(
                                            color: Theme.of(context)
                                                .secondaryHeaderColor)
                                        : null,
                                  ),
                                  onChanged: (val) => setState(() {
                                    type = val;
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
                                            contentPadding:
                                                EdgeInsets.symmetric(
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
                                                        .primaryColor))),
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
                                    color:
                                        packageName == 'com.eralink.mobileapk'
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey),
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
                                            contentPadding:
                                                EdgeInsets.symmetric(
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
                                                        .primaryColor))),
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
                          Row(
                            children: [
                              Expanded(
                                child: packageName == 'com.eralink.mobileapk'
                                    ? OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                                color: Theme.of(context)
                                                    .primaryColor)),
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
              listMutasi.isNotEmpty
                  ? Expanded(
                      child: SmartRefresher(
                        controller: refreshController,
                        enablePullUp: true,
                        enablePullDown: true,
                        onRefresh: () async {
                          currentPage = 0;
                          isEdge = false;
                          listMutasi.clear();
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
                          itemCount: listMutasi.length,
                          separatorBuilder: (_, i) => SizedBox(height: 10),
                          itemBuilder: (_, int index) {
                            MutasiModel m = listMutasi[index];
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
                                  return Navigator.of(context).push(
                                      PageTransition(
                                          child: DetailMutasi(m),
                                          type: PageTransitionType.rippleMiddle,
                                          duration:
                                              Duration(milliseconds: 350)));
                                },
                                leading: CircleAvatar(
                                  foregroundColor: packageName ==
                                          'com.lariz.mobile'
                                      ? Theme.of(context).secondaryHeaderColor
                                      : Theme.of(context).primaryColor,
                                  backgroundColor:
                                      packageName == 'com.lariz.mobile'
                                          ? Theme.of(context)
                                              .secondaryHeaderColor
                                              .withOpacity(.1)
                                          : Theme.of(context)
                                              .primaryColor
                                              .withOpacity(.1),
                                  child: Icon(Icons.list),
                                ),
                                title: Text(m.keterangan,
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    )),
                                subtitle: Text(
                                    formatDate(m.created_at,
                                            "dd MMMM yyyy HH:mm:ss") ??
                                        ' ',
                                    style: TextStyle(
                                        fontSize: 10.0,
                                        color: Colors.grey.shade700)),
                                trailing: Text(formatRupiah(m.jumlah),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: m.jumlah < 0
                                            ? Colors.red
                                            : Colors.green)),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : Expanded(
                      child: Container(
                        child: Center(
                          child: SvgPicture.asset('assets/img/empty.svg',
                              width: MediaQuery.of(context).size.width * .35),
                        ),
                      ),
                    ),
            ],
          );
  }
}
