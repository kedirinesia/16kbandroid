// @dart=2.9

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/bloc/Bloc.dart';
import 'package:mobile/config.dart';
import 'package:mobile/models/virtual_account.dart';
import 'package:mobile/modules.dart';
import 'package:mobile/provider/analitycs.dart';
import 'package:mobile/screen/topup/va/va-controller.dart';

class TopupVA extends StatefulWidget {
  @override
  _TopupVAState createState() => _TopupVAState();
}

class _TopupVAState extends VAController {
  @override
  void initState() {
    super.initState();
    print('🔍 [TOPUP VA] initState called');
    print('🔍 [TOPUP VA] User ID: ${bloc.userId.valueWrapper?.value}');
    
    var analyticsData = {
      'userId': bloc.userId.valueWrapper?.value,
      'title': 'Virtual Account',
    };
    print('🔍 [TOPUP VA] Analytics payload: ${analyticsData.toString()}');
    analitycs.pageView('/va', analyticsData);
    print('🔍 [TOPUP VA] Analytics page view sent');
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 [TOPUP VA] build() called');
    print('🔍 [TOPUP VA] Loading state: $loading');
    return Scaffold(
      appBar: AppBar(
        title: Text("Virtual Account"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: packageName == 'com.lariz.mobile'
            ? Theme.of(context).secondaryHeaderColor
            : Theme.of(context).primaryColor,
      ),
      body: loading
          ? Container(
              width: double.infinity,
              height: double.infinity,
              child: Center(
                  child: SpinKitThreeBounce(
                      color: packageName == 'com.lariz.mobile'
                          ? Theme.of(context).secondaryHeaderColor
                          : Theme.of(context).primaryColor,
                      size: 35)))
          : Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: SvgPicture.asset('assets/img/va.svg',
                        width: MediaQuery.of(context).size.width * .5),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * .05),
                  TextFormField(
                    controller: nominal,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Nominal",
                        prefixText: "Rp ",
                        isDense: true),
                    onChanged: (value) {
                      print('🔍 [TOPUP VA] Nominal field changed: $value');
                      int amount = int.tryParse(
                              nominal.text.replaceAll(RegExp('[^0-9]'), '')) ??
                          0;
                      print('🔍 [TOPUP VA] Parsed amount: $amount');
                      nominal.text = FormatRupiah(amount);
                      print('🔍 [TOPUP VA] Formatted nominal: ${nominal.text}');
                      nominal.selection = TextSelection.fromPosition(
                          TextPosition(offset: nominal.text.length));
                    },
                  ),
                  SizedBox(height: 15),
                  Divider(),
                  SizedBox(height: 15),
                  Expanded(
                    child: FutureBuilder<List<VirtualAccount>>(
                      future: getVa(),
                      builder: (ctx, snapshot) {
                        if (!snapshot.hasData)
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            child: Center(
                              child: SpinKitThreeBounce(
                                color: packageName == 'com.lariz.mobile'
                                    ? Theme.of(context).secondaryHeaderColor
                                    : Theme.of(context).primaryColor,
                                size: 25,
                              ),
                            ),
                          );

                        return ListView.separated(
                          itemCount: snapshot.data.length,
                          separatorBuilder: (_, i) => SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            VirtualAccount va = snapshot.data[i];

                            return Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(.2),
                                        offset: Offset(5, 10),
                                        blurRadius: 10.0)
                                  ]),
                              child: ListTile(
                                  onTap: () => topup(va),
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        packageName == 'com.lariz.mobile'
                                            ? Theme.of(context)
                                                .secondaryHeaderColor
                                                .withOpacity(.15)
                                            : Theme.of(context)
                                                .primaryColor
                                                .withOpacity(.15),
                                    child: Text(
                                      (i + 1).toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: packageName == 'com.lariz.mobile'
                                            ? Theme.of(context)
                                                .secondaryHeaderColor
                                            : Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    va.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: packageName == 'com.lariz.mobile'
                                          ? Theme.of(context)
                                              .secondaryHeaderColor
                                          : Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    va.description,
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  )),
                            );
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
