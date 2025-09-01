// @dart=2.9

import 'package:flutter/material.dart';
import 'package:mobile/bloc/ConfigApp.dart';
import 'package:mobile/config.dart';
import 'package:mobile/Products/seepays/layout/deposit/deposit.dart';
import 'package:mobile/Products/seepays/layout/mutasi/mutasi.dart';
import 'package:mobile/Products/seepays/layout/transaksi.dart';
import 'package:mobile/screen/history/order.dart';

// ignore: must_be_immutable
class HistoryPage extends StatefulWidget {
  int initIndex;

  HistoryPage({this.initIndex = 0});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: configAppBloc.isMarketplace.valueWrapper?.value ? 4 : 3,
      initialIndex: widget.initIndex,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: packageName == 'com.lariz.mobile'
              ? Theme.of(context).secondaryHeaderColor
              : Theme.of(context).appBarTheme.backgroundColor,
          bottom: TabBar(
              indicatorColor: Theme.of(context).appBarTheme.iconTheme.color,
              labelColor: Theme.of(context).appBarTheme.iconTheme.color,
              unselectedLabelColor:
                  Theme.of(context).appBarTheme.iconTheme.color.withOpacity(.7),
              tabs: configAppBloc.isMarketplace.valueWrapper?.value
                  ? [
                      Tab(
                        child: Text('Deposit'),
                        icon: Icon(Icons.tab),
                      ),
                      Tab(
                        child: Text('Transaksi'),
                        icon: Icon(Icons.sort),
                      ),
                      Tab(
                        child: Text('Mutasi'),
                        icon: Icon(Icons.line_style),
                      ),
                      Tab(
                        child: Text(
                          'Order',
                          style: TextStyle(fontSize: 11),
                        ),
                        icon: Icon(Icons.local_shipping_rounded),
                      )
                    ]
                  : [
                      Tab(
                        child: Text('Deposit'),
                        icon: Icon(Icons.tab),
                      ),
                      Tab(
                        child: Text('Transaksi'),
                        icon: Icon(Icons.sort),
                      ),
                      Tab(
                        child: Text('Mutasi'),
                        icon: Icon(Icons.line_style),
                      ),
                    ]),
        ),
        body: TabBarView(
            physics: ScrollPhysics(),
            children: configAppBloc.isMarketplace.valueWrapper?.value
                ? [
                    DepositPage(),
                    HistoryTransaksi(),
                    MutasiPage(),
                    HistoryOrderPage(),
                  ]
                : [
                    DepositPage(),
                    HistoryTransaksi(),
                    MutasiPage(),
                  ]),
      ),
    );
  }
}
