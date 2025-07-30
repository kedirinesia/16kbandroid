// @dart=2.9

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/Products/centralbayar/layout/agreement/privacy_page.dart';
import 'package:mobile/Products/centralbayar/layout/agreement/service_page.dart';
import 'package:mobile/bloc/Api.dart';
import 'package:mobile/bloc/Bloc.dart';
import 'package:mobile/bloc/ConfigApp.dart';
import 'package:mobile/component/bezierContainer.dart';
import 'package:mobile/config.dart';
import 'package:mobile/models/lokasi.dart';
import 'package:mobile/provider/analitycs.dart';
import 'package:mobile/screen/select_state/kecamatan.dart';
import 'package:mobile/screen/select_state/kota.dart';
import 'package:mobile/screen/select_state/provinsi.dart';
import 'package:mobile/screen/text_kapital.dart';

class RegisterUser extends StatefulWidget {
  @override
  _RegisterUserState createState() => _RegisterUserState();
}

class _RegisterUserState extends State<RegisterUser> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nama = TextEditingController();
  TextEditingController nomorHp = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController pin = TextEditingController();
  TextEditingController alamat = TextEditingController();
  TextEditingController namaToko = TextEditingController();
  TextEditingController alamatToko = TextEditingController();
  TextEditingController provinsiText = TextEditingController();
  TextEditingController kotaText = TextEditingController();
  TextEditingController kecamatanText = TextEditingController();
  TextEditingController referalCode = TextEditingController();
  bool loading = false;
  Lokasi provinsi;
  Lokasi kota;
  Lokasi kecamatan;
  // bool isEmail = false;
  bool isNamaToko = true;
  bool isAlmtToko = true;
  bool isReferalCode = false;
  bool isAgree = false;

  @override
  void initState() {
    super.initState();
    analitycs.pageView('/register/', {
      'userId': bloc.userId.valueWrapper?.value,
      'title': 'Registrasi',
    });
  }

  @override
  void dispose() {
    nama.dispose();
    nomorHp.dispose();
    email.dispose();
    pin.dispose();
    alamat.dispose();
    namaToko.dispose();
    alamatToko.dispose();
    provinsiText.dispose();
    kotaText.dispose();
    kecamatanText.dispose();
    referalCode.dispose();
    super.dispose();
  }

  Future<void> submitRegister() async {
    if (pin.text.startsWith('0')) {
      return showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Gagal'),
          content: const Text('Nomor PIN Tidak Boleh Diawali Dengan Angka 0'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'TUTUP'),
              child: const Text('TUTUP'),
            ),
          ],
        ),
      );
    }

    if (!_formKey.currentState.validate()) return;
    setState(() {
      loading = true;
    });

    String kodeUpline = bloc.kodeUpline.valueWrapper?.value;

    Map<String, dynamic> dataToSend = {
      'name': nama.text,
      'phone': nomorHp.text,
      'email': email.text,
      'pin': pin.text,
      'id_propinsi': provinsi.id,
      'id_kabupaten': kota.id,
      'id_kecamatan': kecamatan.id,
      'alamat': alamat.text,
      'nama_toko': namaToko.text,
      'alamat_toko': alamatToko.text.isEmpty ? alamat.text : alamatToko.text,
    };
    if (referalCode.text.isNotEmpty) {
      dataToSend['kode_upline'] = referalCode.text.toUpperCase();
    }

    if (kodeUpline != null) {
      dataToSend['kode_upline'] = kodeUpline;
    } else if (kodeUpline == null && brandId != null) {
      dataToSend['kode_upline'] = brandId;
    }

    try {
      http.Response response = await http.post(
        Uri.parse('$apiUrl/user/register'),
        headers: {
          'content-type': 'application/json',
          'merchantCode': sigVendor
        },
        body: json.encode(dataToSend),
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String message = data['message'];
        showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text('Registrasi Berhasil'),
                content: Text(message),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                      'TUTUP',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(_, rootNavigator: true).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            });
      } else {
        String message = json.decode(response.body)['message'];
        showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: Text('Registrasi Gagal'),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  child: Text(
                    'TUTUP',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text('Registrasi Gagal'),
            content: Text(e ?? 'Terjadi kesalahan pada sistem'),
            actions: <Widget>[
              TextButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                child: Text(
                  'TUTUP',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Widget _imageLogo() {
    return CachedNetworkImage(
      imageUrl: configAppBloc.iconApp.valueWrapper?.value['logoLogin'],
      height: MediaQuery.of(context).size.width * .15,
      fit: BoxFit.contain,
    );
  }

  Widget _title() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: configAppBloc.namaApp.valueWrapper?.value,
        style: TextStyle(
          shadows: [
            Shadow(color: Colors.white, offset: Offset(0, 0), blurRadius: 10)
          ],
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _agreeLabel(bool checklist) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isAgree
            ? GestureDetector(
                onTap: () => setState(() => isAgree = false),
                child: Container(
                  padding: EdgeInsets.all(5),
                  child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          border: Border.all(width: 1.0, color: Colors.grey)),
                      child: Icon(Icons.check_circle,
                          size: 23, color: Theme.of(context).primaryColor)),
                ),
              )
            : GestureDetector(
                onTap: () => setState(() => isAgree = true),
                child: Container(
                  padding: EdgeInsets.all(5),
                  child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          border: Border.all(
                              width: 1.0, color: Colors.grey.shade400)),
                      child: Icon(Icons.check_circle,
                          size: 23, color: Colors.grey[300])),
                ),
              ),
        SizedBox(width: 5),
        // Row(
        //   children: [
        //     Text(
        //       'Agree with',
        //       style: TextStyle(
        //           color: Colors.black87,
        //           fontSize: 15,
        //           fontWeight: FontWeight.w500),
        //     ),
        //     SizedBox(width: 5),
        //     GestureDetector(
        //       onTap: () async {
        //         await launchUrl(Uri.parse(
        //             configAppBloc.info.valueWrapper.value.urlPrivacyPolicy));
        //       },
        //       child: Text(
        //         'Term & Conditions',
        //         style: TextStyle(
        //           color: Theme.of(context).primaryColor,
        //           fontSize: 15,
        //           fontWeight: FontWeight.w500,
        //         ),
        //       ),
        //     )
        //   ],
        // ),
        RichText(
          text: TextSpan(
            text: "Lihat ",
            style: TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500),
            children: [
              TextSpan(
                text: "Syarat & Ketentuan ",
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) {
                        return ServicePolicyPage();
                      },
                    ));
                  },
              ),
              TextSpan(text: "dan "),
              TextSpan(
                text: "Kebijakan Privasi! ",
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) {
                        return PrivacyPolicyPage();
                      },
                    ));
                  },
              ),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> pkgNameRefCode = [
      'mobile.payuni.id',
      'id.funmo.mobile',
      'id.paymobileku.app',
      'popay.id',
      'id.ualreload.mobile',
      'com.funmoid.app',
      'com.popayfdn',
      'com.xenaja.app',
      'com.alpay.mobile',
    ];

    pkgNameRefCode.forEach((element) {
      if (element == packageName) {
        isReferalCode = true;
      }
    });

    List<String> pkgNameToko = [
      'id.paymobileku.app',
    ];

    pkgNameToko.forEach((element) {
      if (element == packageName) {
        isNamaToko = false;
        isAlmtToko = false;
      }
    });

    // List<String> pkgNameEmail = ['id.paymobileku.app'];

    // pkgNameEmail.forEach((element) {
    //   if (element == packageName) {
    //     isEmail = true;
    //   }
    // });

    OutlineInputBorder _normalBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.grey.shade300,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(20),
    );

    InputDecoration _inputDecoration = InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      border: _normalBorder,
      enabledBorder: _normalBorder,
      focusedBorder: _normalBorder.copyWith(
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
      ),
      hintStyle: TextStyle(
        color: Colors.grey,
      ),
    );

    return Scaffold(
      body: loading
          ? SpinKitThreeBounce(
              color: Theme.of(context).primaryColor,
              size: 35,
            )
          : Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: configAppBloc.iconApp.valueWrapper?.value['texture'] !=
                        null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          configAppBloc.iconApp.valueWrapper?.value['texture'],
                        ),
                        fit: BoxFit.fitWidth,
                      )
                    : null,
              ),
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
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: EdgeInsets.all(20),
                        children: <Widget>[
                          SizedBox(height: 20),
                          configAppBloc.iconApp.valueWrapper
                                      .value['logoLogin'] !=
                                  null
                              ? _imageLogo()
                              : _title(),
                          SizedBox(
                            height: 50,
                          ),
                          TextFormField(
                            controller: nama,
                            keyboardType: TextInputType.text,
                            cursorColor: Theme.of(context).primaryColor,
                            decoration: _inputDecoration.copyWith(
                              prefixIcon: Icon(
                                Icons.person_rounded,
                                color: Theme.of(context).primaryColor,
                              ),
                              hintText: 'Nama',
                            ),
                            inputFormatters: [
                              UpperCaseTextFormatter(),
                            ],
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Nama tidak boleh kosong';
                              else
                                return null;
                            },
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: nomorHp,
                            keyboardType: TextInputType.phone,
                            cursorColor: Theme.of(context).primaryColor,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(13),
                            ],
                            decoration: _inputDecoration.copyWith(
                              prefixIcon: Icon(
                                Icons.phone_rounded,
                                color: Theme.of(context).primaryColor,
                              ),
                              hintText: 'Nomor HP',
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Nomor HP tidak boleh kosong';
                              else
                                return null;
                            },
                          ),
                          Column(
                            children: [
                              SizedBox(height: 15),
                              TextFormField(
                                controller: email,
                                keyboardType: TextInputType.emailAddress,
                                cursorColor: Theme.of(context).primaryColor,
                                decoration: _inputDecoration.copyWith(
                                  prefixIcon: Icon(
                                    Icons.email_rounded,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  hintText: 'Email',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Email tidak boleh kosong';
                                  else if (!RegExp(r'\S+@\S+\.\S+')
                                      .hasMatch(value))
                                    return 'Masukkan alamat email yang valid';
                                  else
                                    return null;
                                },
                              )
                            ],
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: pin,
                            keyboardType: TextInputType.number,
                            cursorColor: Theme.of(context).primaryColor,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(pinCount),
                            ],
                            obscureText: true,
                            decoration: _inputDecoration.copyWith(
                              prefixIcon: Icon(
                                Icons.lock_rounded,
                                color: Theme.of(context).primaryColor,
                              ),
                              hintText: 'PIN',
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'PIN tidak boleh kosong';
                              else
                                return null;
                            },
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: provinsiText,
                            readOnly: true,
                            decoration: _inputDecoration.copyWith(
                              prefixIcon: Icon(
                                Icons.place_rounded,
                                color: Theme.of(context).primaryColor,
                              ),
                              hintText: 'Provinsi',
                            ),
                            onTap: () async {
                              Lokasi lokasi = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SelectProvinsiPage(),
                                ),
                              );

                              if (lokasi == null) return;

                              setState(() {
                                provinsi = lokasi;
                                kota = null;
                                kecamatan = null;

                                provinsiText.text = lokasi.nama;
                                kotaText.clear();
                                kecamatanText.clear();
                              });
                            },
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Provinsi tidak boleh kosong';
                              else
                                return null;
                            },
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: kotaText,
                            readOnly: true,
                            decoration: _inputDecoration.copyWith(
                              prefixIcon: Icon(
                                Icons.place_rounded,
                                color: Theme.of(context).primaryColor,
                              ),
                              hintText: 'Kota atau Kabupaten',
                            ),
                            onTap: () async {
                              if (provinsi == null) return;

                              Lokasi lokasi = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SelectKotaPage(provinsi),
                                ),
                              );

                              if (lokasi == null) return;

                              setState(() {
                                kota = lokasi;
                                kecamatan = null;

                                kotaText.text = lokasi.nama;
                                kecamatanText.clear();
                              });
                            },
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Kota tidak boleh kosong';
                              else
                                return null;
                            },
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: kecamatanText,
                            readOnly: true,
                            decoration: _inputDecoration.copyWith(
                              prefixIcon: Icon(
                                Icons.place_rounded,
                                color: Theme.of(context).primaryColor,
                              ),
                              hintText: 'Kecamatan',
                            ),
                            onTap: () async {
                              if (kota == null) return;

                              Lokasi lokasi = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SelectKecamatanPage(kota),
                                ),
                              );

                              if (lokasi == null) return;

                              setState(() {
                                kecamatan = lokasi;
                                kecamatanText.text = lokasi.nama;
                              });
                            },
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Kecamatan tidak boleh kosong';
                              else
                                return null;
                            },
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: alamat,
                            cursorColor: Theme.of(context).primaryColor,
                            keyboardType: TextInputType.text,
                            decoration: _inputDecoration.copyWith(
                              prefixIcon: Icon(
                                Icons.home_rounded,
                                color: Theme.of(context).primaryColor,
                              ),
                              hintText: 'Alamat Rumah',
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Alamat Rumah tidak boleh kosong';
                              else
                                return null;
                            },
                          ),
                          // SizedBox(height: 15),
                          isNamaToko
                              ? Column(
                                  children: [
                                    SizedBox(height: 15),
                                    TextFormField(
                                      controller: namaToko,
                                      cursorColor:
                                          Theme.of(context).primaryColor,
                                      keyboardType: TextInputType.text,
                                      decoration: _inputDecoration.copyWith(
                                        prefixIcon: Icon(
                                          Icons.storefront_rounded,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        hintText: 'Nama Toko',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty)
                                          return 'Nama Toko tidak boleh kosong';
                                        else
                                          return null;
                                      },
                                    )
                                  ],
                                )
                              : SizedBox(),
                          // SizedBox(height: 15),
                          // TextFormField(
                          //   controller: namaToko,
                          //   keyboardType: TextInputType.text,
                          //   decoration: _inputDecoration.copyWith(
                          //     prefixIcon: Icon(
                          //       Icons.storefront_rounded,
                          //       color: Theme.of(context).primaryColor,
                          //     ),
                          //     hintText: 'Nama Toko',
                          //   ),
                          //   validator: (val) {
                          //     if (val == null || val.isEmpty)
                          //       return 'Nama toko tidak boleh kosong';
                          //     else
                          //       return null;
                          //   },
                          // ),
                          // SizedBox(height: 15),
                          // TextField(
                          //   controller: alamatToko,
                          //   keyboardType: TextInputType.text,
                          //   decoration: _inputDecoration.copyWith(
                          //     prefixIcon: Icon(
                          //       Icons.place_rounded,
                          //       color: Theme.of(context).primaryColor,
                          //     ),
                          //     hintText: 'Alamat Toko',
                          //   ),
                          // ),
                          isAlmtToko
                              ? Column(
                                  children: [
                                    SizedBox(height: 15),
                                    TextFormField(
                                      controller: alamatToko,
                                      cursorColor:
                                          Theme.of(context).primaryColor,
                                      keyboardType: TextInputType.text,
                                      decoration: _inputDecoration.copyWith(
                                        prefixIcon: Icon(
                                          Icons.place_rounded,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        hintText: 'Alamat Toko',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty)
                                          return 'Alamat Toko tidak boleh kosong';
                                        else
                                          return null;
                                      },
                                    )
                                  ],
                                )
                              : SizedBox(),
                          isReferalCode
                              ? Column(
                                  children: [
                                    SizedBox(height: 15),
                                    TextFormField(
                                      controller: referalCode,
                                      cursorColor:
                                          Theme.of(context).primaryColor,
                                      keyboardType: TextInputType.text,
                                      decoration: _inputDecoration.copyWith(
                                        prefixIcon: Icon(
                                          Icons.groups_sharp,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        hintText: 'Kode Referal',
                                      ),
                                      inputFormatters: [
                                        UpperCaseTextFormatter(),
                                      ],
                                      validator: (value) {
                                        if (packageName ==
                                                'id.paymobileku.app' &&
                                            (value == null || value.isEmpty)) {
                                          return 'Kode Referal tidak boleh kosong';
                                        }
                                        return null;
                                      },
                                    )
                                  ],
                                )
                              : SizedBox(),
                          SizedBox(height: 20),
                          _agreeLabel(isAgree),
                          SizedBox(height: 20),
                          isAgree
                              ? MaterialButton(
                                  onPressed: submitRegister,
                                  child: Text('Daftar Sekarang'),
                                  elevation: 0,
                                  color: Theme.of(context).primaryColor,
                                  textColor: Colors.white,
                                  padding: EdgeInsets.all(10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                )
                              : MaterialButton(
                                  onPressed: null,
                                  child: Text(
                                    'Daftar Sekarang',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  elevation: 0,
                                  disabledColor: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(.4),
                                  color: Theme.of(context).primaryColor,
                                  textColor: Colors.white,
                                  padding: EdgeInsets.all(10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Sudah memiliki akun? ',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              InkWell(
                                onTap: Navigator.of(context).pop,
                                child: Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ],
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
