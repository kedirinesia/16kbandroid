// @dart=2.9
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mobile/screen/privacy_policy.dart';
import 'package:mobile/bloc/Bloc.dart';
import 'package:mobile/bloc/ConfigApp.dart';
import 'package:mobile/config.dart';
import 'package:mobile/provider/analitycs.dart';
import 'package:mobile/screen/forgot-password/step_1.dart';
import 'package:mobile/screen/otp.dart';
import 'package:mobile/screen/profile/cs/cs.dart';
import '../component/bezierContainer.dart';
import 'package:http/http.dart' as http;
import '../bloc/Api.dart' show apiUrl, sigVendor;
import 'cs.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController nomorHp = TextEditingController();
  TextEditingController pin = TextEditingController();
  bool loading = false;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    analitycs.pageView('/login/', {
      'userId': bloc.userId.valueWrapper?.value,
      'title': 'Login',
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<String> pkgNameBorder = ['com.eralink.mobileapk'];

  submitLogin() async {
    if (formKey.currentState.validate()) {
      setState(() {
        loading = true;
      });
      Map<String, dynamic> dataToSend = {
        'phone': nomorHp.text,
        'pin': pin.text
      };

      http.Response response = await http.post(
          Uri.parse(apiUrl + '/user/login'),
          body: jsonEncode(dataToSend),
          headers: {
            'content-type': 'application/json',
            'merchantCode': sigVendor
          });
      setState(() {
        loading = false;
      });
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body)['data'];
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => OtpPage(data['phone'], data['validate_id'])));
      } else {
        String message = json.decode(response.body)['message'];
        return showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text('Warning'),
                content: Text(message),
                actions: <Widget>[
                  TextButton(
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      child: Text('OK'))
                ],
              );
            });
      }
    }
  }

  Widget _entryField(
    String title, {
    bool isPassword = false,
    int maxLength,
    TextEditingController controller,
    Function(String value) validator,
    List<TextInputFormatter> formatters = const [],
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(
            height: 10,
          ),
          packageName == 'com.eralink.mobileapk'
              ? TextFormField(
                  controller: controller,
                  validator: validator,
                  keyboardType: TextInputType.number,
                  cursorColor: Theme.of(context).primaryColor,
                  obscureText: isPassword,
                  maxLength: maxLength,
                  inputFormatters: formatters,
                  decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).secondaryHeaderColor)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).secondaryHeaderColor)),
                      fillColor: Colors.white,
                      filled: true),
                )
              : TextFormField(
                  controller: controller,
                  validator: validator,
                  keyboardType: TextInputType.number,
                  obscureText: isPassword,
                  maxLength: maxLength,
                  inputFormatters: formatters,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      fillColor: Color(0xfff3f3f4),
                      filled: true))
        ],
      ),
    );
  }

  Widget _submitButton() {
    var loadingWidget = Center(
        child: SpinKitThreeBounce(
            color: Theme.of(context).primaryColor, size: 35));

    return loading
        ? loadingWidget
        : InkWell(
            onTap: submitLogin,
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.symmetric(vertical: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        color: Colors.grey.shade200,
                        offset: Offset(2, 4),
                        blurRadius: 5,
                        spreadRadius: 2)
                  ],
                  gradient: packageName == "com.eralink.mobileapk"
                      ? LinearGradient(colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor
                        ])
                      : LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).secondaryHeaderColor,
                            ])),
              child: Text(
                'Masuk',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          );
  }

  Widget _createAccountLabel() {
    return Container(
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Belum Punya Akun ?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          SizedBox(
            width: 10,
          ),
          InkWell(
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => PrivacyPolicyPage()));
            },
            child: Text(
              'Daftar Sekarang',
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageLogo() {
    return Hero(
      tag: 'icon-apk',
      child: CachedNetworkImage(
        imageUrl: configAppBloc.iconApp.valueWrapper?.value['logoLogin'],
        height: MediaQuery.of(context).size.width * .15,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _title() {
    return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: configAppBloc.namaApp.valueWrapper?.value,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).primaryColor,
          ),
        ));
  }

  Widget _emailPasswordWidget() {
    return Form(
      key: formKey,
      child: Column(
        children: <Widget>[
          _entryField(
            "Nomor HP",
            controller: nomorHp,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
          _entryField(
            "PIN",
            isPassword: true,
            controller: pin,
            maxLength: configAppBloc.limitPinLogin.valueWrapper?.value
                ? configAppBloc.pinCount.valueWrapper?.value
                : null,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(pinCount),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
            image: configAppBloc.iconApp.valueWrapper?.value['texture'] != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(
                        configAppBloc.iconApp.valueWrapper?.value['texture']),
                    fit: BoxFit.fitWidth)
                : null),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -MediaQuery.of(context).size.height * .15,
              right: -MediaQuery.of(context).size.width * .4,
              child: BezierContainer(),
            ),
            Container(
              width: double.infinity,
              height: double.infinity,
              child: ListView(
                padding: EdgeInsets.all(20),
                children: <Widget>[
                  SizedBox(height: MediaQuery.of(context).size.height * .2),
                  configAppBloc.iconApp.valueWrapper?.value['logoLogin'] != null
                      ? _imageLogo()
                      : _title(),
                  SizedBox(
                    height: 50,
                  ),
                  _emailPasswordWidget(),
                  SizedBox(
                    height: 20,
                  ),
                  _submitButton(),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => StepOneForgotPIN())),
                      child: Text('Lupa PIN ?',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).primaryColor)),
                    ),
                  ),
                  SizedBox(height: 20),
                  (configAppBloc.info.valueWrapper?.value?.register == true)
                      ? Align(
                          alignment: Alignment.bottomCenter,
                          child: _createAccountLabel(),
                        )
                      : SizedBox(width: 0, height: 0),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 15,
                left: 15,
              ),
              child: InkWell(
                onTap: () {
                  List<String> packages = [
                    'payku.id',
                    'pdpay.id',
                    'com.maripay.app',
                    'ayoba.co.id',
                    'com.ecuan.mobile',
                    'com.pgkreload.app',
                    Platform.isAndroid ? 'com.payuni.id' : 'co.payuni.id',
                  ];

                  return Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          packages.contains(packageName) ? CS1() : CS(),
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      backgroundColor: Theme.of(context).primaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      child: Icon(Icons.support_agent_rounded),
                      onPressed: null,
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Bantuan',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
