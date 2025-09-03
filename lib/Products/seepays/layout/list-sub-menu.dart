// @dart=2.9

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/bloc/ConfigApp.dart';
import 'package:mobile/bloc/TemplateConfig.dart';
import 'package:mobile/config.dart';
import 'package:mobile/models/menu.dart';
import 'package:mobile/Products/seepays/layout/list-sub-menu-controller.dart';

// ignore: must_be_immutable
class ListSubMenu extends StatefulWidget {
  final MenuModel menuModel;

  ListSubMenu(this.menuModel);

  @override
  _ListSubMenuState createState() => _ListSubMenuState();
}

class _ListSubMenuState extends ListSubMenuController {
  @override
  Widget build(BuildContext context) {
    List<String> pkgName = [
      'com.funmo.id',
      'com.seepaysbiller.app' // ✅ tambahkan
    ];

    List<String> searchFeaturePkgName = [
      'id.ualreload.mobile',
      'id.alpay.mobile',
      'com.seepaysbiller.app' // ✅ tambahkan
    ];

    bool useSearchMenu = searchFeaturePkgName.contains(packageName);

    if (pkgName.contains(packageName)) {
      isProductIconMenu = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentMenu.name),
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
      body: packageName.isEmpty
          ? Center(
              child: SpinKitThreeBounce(
                color: Theme.of(context).primaryColor,
                size: 35,
              ),
            )
          : Container(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                children: <Widget>[
                  // HEADER
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * .2,
                    decoration: BoxDecoration(
                      color: packageName == 'com.lariz.mobile'
                          ? Theme.of(context).secondaryHeaderColor
                          : Theme.of(context).primaryColor,
                    ),
                    child: packageName == 'com.eazyin.mobile'
                        ? Center(
                            child: CachedNetworkImage(
                              imageUrl: configAppBloc
                                  .iconApp.valueWrapper?.value['logoLogin'],
                              width: MediaQuery.of(context).size.width * .4,
                            ),
                          )
                        : null,
                  ),

                  // SEARCH BAR
                  (useSearchMenu && currentMenu.type == 1) ||
                          currentMenu.type == 2
                      ? Container(
                          padding: EdgeInsets.all(20),
                          child: TextFormField(
                            controller: query,
                            keyboardType: TextInputType.text,
                            cursorColor: Theme.of(context).primaryColor,
                            decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300)),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Theme.of(context)
                                            .primaryColor)),
                                hintText: 'Cari disini...',
                                isDense: true,
                                suffixIcon: InkWell(
                                    child: Icon(
                                      Icons.search,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    onTap: () {
                                      List<MenuModel> list = tempMenu
                                          .where((menu) => menu.name
                                              .toLowerCase()
                                              .contains(
                                                  query.text.toLowerCase()))
                                          .toList();
                                      setState(() {
                                        listMenu = list;
                                      });
                                    })),
                            onEditingComplete: () {
                              List<MenuModel> list = tempMenu
                                  .where((menu) => menu.name
                                      .toLowerCase()
                                      .contains(query.text.toLowerCase()))
                                  .toList();
                              setState(() {
                                listMenu = list;
                              });
                            },
                            onChanged: (value) {
                              if (value.isEmpty) {
                                setState(() {
                                  listMenu = tempMenu;
                                });
                              }
                            },
                          ),
                        )
                      : Container(),

                  // LIST MENU
                  Flexible(
                    flex: 1,
                    child: loading
                        ? Center(
                            child: SpinKitThreeBounce(
                              color: packageName == 'com.lariz.mobile'
                                  ? Theme.of(context).secondaryHeaderColor
                                  : Theme.of(context).primaryColor,
                              size: 35,
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              try {
                                // Refresh menu data
                                await getData();
                                
                                // Add a small delay to show refresh animation
                                await Future.delayed(Duration(milliseconds: 500));
                                
                              } catch (e) {
                                print('Error during refresh: $e');
                              }
                            },
                            color: packageName == 'com.lariz.mobile'
                                ? Theme.of(context).secondaryHeaderColor
                                : Theme.of(context).primaryColor,
                            backgroundColor: Colors.white,
                            strokeWidth: 3.0,
                            child: listMenu.isEmpty && showEmptyState
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.inbox_outlined,
                                          size: 80,
                                          color: Colors.grey[400],
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Produk Masih Kosong',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Belum ada produk tersedia\nuntuk kategori ini',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            try {
                                              await getData();
                                            } catch (e) {
                                              print('Error during refresh: $e');
                                            }
                                          },
                                          icon: Icon(Icons.refresh),
                                          label: Text('Coba Lagi'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: packageName == 'com.lariz.mobile'
                                                ? Theme.of(context).secondaryHeaderColor
                                                : Theme.of(context).primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : listMenu.isEmpty && !showEmptyState
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SpinKitThreeBounce(
                                              color: packageName == 'com.lariz.mobile'
                                                  ? Theme.of(context).secondaryHeaderColor
                                                  : Theme.of(context).primaryColor,
                                              size: 35,
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'Memuat produk...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                : ListView.separated(
                                    padding: EdgeInsets.all(20),
                                    itemCount: listMenu.length,
                                    separatorBuilder: (_, i) => SizedBox(height: 10),
                                    itemBuilder: (ctx, i) {
                                  MenuModel menu = listMenu[i];
                                  return InkWell(
                                    onTap: () => onTapMenu(menu),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10.0),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black.withOpacity(.1),
                                                offset: Offset(5, 10.0),
                                                blurRadius: 20)
                                          ]),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          foregroundColor:
                                              packageName == 'com.lariz.mobile'
                                                  ? Theme.of(context)
                                                      .secondaryHeaderColor
                                                  : Theme.of(context).primaryColor,
                                          backgroundColor:
                                              packageName == 'com.lariz.mobile'
                                                  ? Theme.of(context)
                                                      .secondaryHeaderColor
                                                      .withOpacity(.1)
                                                  : Theme.of(context)
                                                      .primaryColor
                                                      .withOpacity(.1),
                                          child: menu.icon != ''
                                              ? Container(
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  padding: EdgeInsets.all(10),
                                                  child: CachedNetworkImage(
                                                    imageUrl: menu.icon,
                                                  ),
                                                )
                                              : Container(
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  padding: EdgeInsets.all(10),
                                                  child: CachedNetworkImage(
                                                    imageUrl: currentMenu.icon,
                                                  ),
                                                ),
                                        ),
                                        title: Text(
                                          menu.name,
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        subtitle: Text(
                                          menu.description ?? ' ',
                                          style: TextStyle(
                                            fontSize: 10.0,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ),
                  )
                ],
              ),
            ),
    );
  }
}
