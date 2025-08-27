// @dart=2.9

import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/Products/payuniovo/layout/agreement/privacy_page.dart';
import 'package:mobile/Products/payuniovo/layout/agreement/service_page.dart';
import 'package:mobile/bloc/Api.dart';
import 'package:mobile/bloc/Bloc.dart';
import 'package:mobile/bloc/ConfigApp.dart';
import 'package:mobile/models/lokasi.dart';
import 'package:mobile/screen/select_state/kecamatan.dart';
import 'package:mobile/screen/select_state/kota.dart';
import 'package:mobile/screen/select_state/provinsi.dart';
import 'package:mobile/screen/linkverif.dart';

class RegisterUser extends StatefulWidget {
  @override
  _RegisterUserState createState() => _RegisterUserState();
}

class _RegisterUserState extends State<RegisterUser> {
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
  bool isReferalCode = false;
  bool isAgree = false;
  int currentStep = 0;
  String fieldNama;
  String fieldNomorHp;
  String fieldEmail;
  String fieldPin;
  String fieldAlamat;
  String fieldProvinsi;
  String fieldKota;
  String fieldKecamatan;

  List<GlobalKey<FormState>> _formKey = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

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
    print('=== PAYUNIOVO SUBMIT REGISTER START ===');
    print('Current context: $context');
    print('Current mounted: $mounted');
    
    if (pin.text.startsWith('0')) {
      print('PIN validation failed: PIN starts with 0');
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

    print('PIN validation passed');
    String kodeUpline = bloc.kodeUpline.valueWrapper?.value;
    print('Kode upline from bloc: $kodeUpline');

    print('=== PAYUNIOVO LOCATION VALIDATION ===');
    print('Provinsi: ${provinsi?.toString() ?? "NULL"}');
    print('Kota: ${kota?.toString() ?? "NULL"}');
    print('Kecamatan: ${kecamatan?.toString() ?? "NULL"}');
    print('Provinsi ID: ${provinsi?.id ?? "NULL"}');
    print('Kota ID: ${kota?.id ?? "NULL"}');
    print('Kecamatan ID: ${kecamatan?.id ?? "NULL"}');
    
    Map<String, dynamic> dataToSend = {
      'name': nama.text,
      'phone': nomorHp.text,
      'email': email.text,
      'pin': pin.text,
      'id_propinsi': provinsi?.id,
      'id_kabupaten': kota?.id,
      'id_kecamatan': kecamatan?.id,
      'alamat': alamat.text,
      'nama_toko': namaToko.text,
      'alamat_toko': alamatToko.text.isEmpty ? alamat.text : alamatToko.text,
    };
    
    print('=== PAYUNIOVO DATA PREPARATION ===');
    print('Name: ${nama.text}');
    print('Phone: ${nomorHp.text}');
    print('Email: ${email.text}');
    print('PIN: ${pin.text}');
    print('Provinsi ID: ${provinsi.id}');
    print('Kota ID: ${kota.id}');
    print('Kecamatan ID: ${kecamatan.id}');
    print('Alamat: ${alamat.text}');
    print('Nama Toko: ${namaToko.text}');
    print('Alamat Toko: ${alamatToko.text.isEmpty ? alamat.text : alamatToko.text}');
    if (referalCode.text.isNotEmpty) {
      dataToSend['kode_upline'] = referalCode.text.toUpperCase();
      print('Referral code from input: ${referalCode.text.toUpperCase()}');
    }

    if (kodeUpline != null) {
      dataToSend['kode_upline'] = kodeUpline;
      print('Kode upline from bloc: $kodeUpline');
    } else if (kodeUpline == null && brandId != null) {
      dataToSend['kode_upline'] = brandId;
      print('Brand ID used as kode upline: $brandId');
    }
    
    print('Final kode_upline value: ${dataToSend['kode_upline']}');

    print('=== PAYUNIOVO REGISTRATION DATA ===');
    print('Data to send: ${json.encode(dataToSend)}');
    print('Email value: ${email.text}');
    print('Email validation: ${email.text.isNotEmpty ? "NotEmpty" : "Empty"}');
    print('Email format check: ${RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.text) ? "Valid Format" : "Invalid Format"}');

    try {
      print('=== PAYUNIOVO REGISTRATION DEBUG ===');
      print('API URL: $apiUrl/user/register');
      print('API URL full: ${Uri.parse('$apiUrl/user/register')}');
      print('sigVendor: $sigVendor');
      print('brandId: $brandId');
      print('Headers: ${json.encode({
        'content-type': 'application/json',
        'merchantCode': sigVendor
      })}');
      print('Request Body: ${json.encode(dataToSend)}');
      print('Request Body length: ${json.encode(dataToSend).length}');
      
      http.Response response = await http.post(
        Uri.parse('$apiUrl/user/register'),
        headers: {
          'content-type': 'application/json',
          'merchantCode': sigVendor
        },
        body: json.encode(dataToSend),
      );
      
      print('Response Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      print('Response Content-Type: ${response.headers['content-type']}');
      print('Response Content-Length: ${response.headers['content-length']}');
      
      // Validasi response body sebelum parsing JSON
      if (response.body.isEmpty) {
        throw Exception('Response body kosong dari server');
      }
      
      // Cek apakah response adalah JSON valid
      if (!response.body.trim().startsWith('{') && !response.body.trim().startsWith('[')) {
        print('=== PAYUNIOVO REGISTRATION INVALID JSON RESPONSE ===');
        print('Response tidak valid JSON: ${response.body.substring(0, 200)}');
        print('====================================================');
        
        String errorMessage = 'Response tidak valid dari server';
        if (response.body.contains('<!DOCTYPE html>') || response.body.contains('<html>')) {
          errorMessage = 'Server mengembalikan halaman HTML, kemungkinan ada masalah dengan server';
        } else if (response.body.contains('timeout') || response.body.contains('Timeout')) {
          errorMessage = 'Request timeout, silakan coba lagi';
        } else if (response.body.contains('connection') || response.body.contains('Connection')) {
          errorMessage = 'Gagal terhubung ke server, periksa koneksi internet';
        }
        
        showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: Text('Error Server'),
              content: Text(errorMessage),
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
        return;
      }
      
      if (response.statusCode == 200) {
        print('=== REGISTRATION SUCCESS ===');
        var data;
        try {
          data = jsonDecode(response.body);
        } catch (jsonError) {
          print('=== PAYUNIOVO REGISTRATION JSON PARSE ERROR ===');
          print('JSON Parse Error: $jsonError');
          print('Response Body: ${response.body}');
          print('===============================================');
          
          showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text('Error Parsing Response'),
                content: Text('Gagal memproses response dari server. Silakan coba lagi atau hubungi customer service.'),
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
          return;
        }
        
        print('Response data type: ${data.runtimeType}');
        print('Response data keys: ${data.keys.toList()}');
        String message = data['message'];
        print('Registration Success - Message: $message');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LinkVerifPage()),
          (route) => false,
        );
      } else {
        print('=== REGISTRATION FAILED ===');
        print('Trying to parse error response...');
        var errorData;
        try {
          errorData = json.decode(response.body);
          print('Error response parsed successfully');
        } catch (parseError) {
          print('Failed to parse error response: $parseError');
          print('Raw error response body: ${response.body}');
          
          // Coba deteksi tipe error dari response body
          String errorMessage = 'Gagal memproses error response dari server';
          if (response.body.contains('<!DOCTYPE html>') || response.body.contains('<html>')) {
            errorMessage = 'Server mengembalikan halaman HTML, kemungkinan ada masalah dengan server';
          } else if (response.body.contains('timeout') || response.body.contains('Timeout')) {
            errorMessage = 'Request timeout, silakan coba lagi';
          } else if (response.body.contains('connection') || response.body.contains('Connection')) {
            errorMessage = 'Gagal terhubung ke server, periksa koneksi internet';
          }
          
          errorData = {'message': errorMessage};
        }
        
        String message = errorData['message'] ?? 'Unknown error';
        print('Registration Failed - Error Data: ${json.encode(errorData)}');
        print('Error Message: $message');
        
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
      print('=== PAYUNIOVO REGISTRATION EXCEPTION ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception message: $e');
      print('Exception stack trace: ${StackTrace.current}');
      
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text('Registrasi Gagal'),
            content: Text(e.toString()),
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
      print('=== PAYUNIOVO REGISTRATION FINALLY ===');
      print('Setting loading to false');
      setState(() {
        loading = false;
      });
      print('Loading state updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registrasi"),
        centerTitle: true,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
            colorScheme:
                ColorScheme.light(primary: Theme.of(context).primaryColor)),
        child: Stepper(
          type: StepperType.horizontal,
          steps: getSteps(),
          currentStep: currentStep,
          onStepContinue: () {
            setState(() {
              fieldNama = nama.text;
              fieldNomorHp = nomorHp.text;
              fieldEmail = email.text;
              fieldPin = pin.text;
              fieldProvinsi = provinsiText.text;
              fieldKota = kotaText.text;
              fieldKecamatan = kecamatanText.text;
              fieldAlamat = alamat.text;
            });
            setState(() {
              print('=== PAYUNIOVO FORM VALIDATION ===');
              print('Current step: $currentStep');
              print('Form validation result: ${_formKey[currentStep].currentState.validate()}');
              print('Email field value: ${email.text}');
              print('Email field error: ${_formKey[currentStep].currentState.validate() ? "No Error" : "Has Error"}');
              
              if (!_formKey[currentStep].currentState.validate()) {
                print('Form validation failed at step $currentStep');
                return;
              }
              
              setState(() {
                loading = true;
              });

              final isLastStep = currentStep == getSteps().length - 1;

              if (isLastStep) {
                print("=== REGISTRATION STEP REACHED ===");
                print("Calling submitRegister() function");
                submitRegister();
              } else {
                setState(() => currentStep += 1);
              }
            });
          },
          // onStepTapped: (step) => setState(() => currentStep = step),
          onStepCancel:
              currentStep == 0 ? null : () => setState(() => currentStep -= 1),
          controlsBuilder:
              (BuildContext context, ControlsDetails controlsDetails) {
            final isLastStep = currentStep == getSteps().length - 1;
            return Container(
              margin: EdgeInsets.only(top: 50),
              child: Row(
                children: [
                  if (currentStep != 0)
                    Expanded(
                      child: ElevatedButton(
                        child: Text('Kembali'),
                        onPressed: controlsDetails.onStepCancel,
                        style: ElevatedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor, backgroundColor: Colors.white,
                            side: BorderSide(
                                color: Theme.of(context).primaryColor)),
                      ),
                    ),
                  // Expanded(
                  //   child: ElevatedButton(
                  //     child: Text(isLastStep ? 'Register' : 'Lanjut'),
                  //     onPressed: isLastStep && !isAgree
                  //         ? null
                  //         : () {
                  //             if (isLastStep) {
                  //               submitRegister();
                  //             } else {
                  //               controlsDetails.onStepContinue();
                  //             }
                  //           },
                  //   ),
                  // ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      child: Text(isLastStep ? 'Register' : 'Lanjut'),
                      onPressed: isLastStep && !isAgree
                          ? null
                          : () {
                              if (isLastStep) {
                                submitRegister();
                              } else {
                                controlsDetails.onStepContinue();
                              }
                            },
                    ),
                  ),
                ],
              ),
            );
          },
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
        RichText(
          text: TextSpan(
            text: "Saya mengerti dan menyetujui\n",
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
                  ..onTap = () {
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

  Widget _buildInfoText(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
            ),
          ),
        ],
      ),
    );
  }

  List<Step> getSteps() => [
        Step(
          state: currentStep > 0 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 0,
          title: Text("Step 1"),
          content: Form(
            key: _formKey[0],
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: nama,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ).copyWith(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ).copyWith(
                    prefixIcon: Icon(
                      Icons.person_rounded,
                      color: Theme.of(context).primaryColor,
                    ),
                    hintText: 'Nama',
                  ),
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
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(13),
                  ],
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ).copyWith(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ).copyWith(
                    prefixIcon: Icon(
                      Icons.person_rounded,
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
                SizedBox(height: 15),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ).copyWith(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ).copyWith(
                    prefixIcon: Icon(
                      Icons.email_rounded,
                      color: Theme.of(context).primaryColor,
                    ),
                    hintText: 'Email',
                  ),
                  validator: (val) {
                    print('=== PAYUNIOVO EMAIL VALIDATION ===');
                    print('Email value to validate: "$val"');
                    print('Email is null: ${val == null}');
                    print('Email is empty: ${val.isEmpty}');
                    print('Email regex test: ${RegExp(r'\S+@\S+\.\S+').hasMatch(val)}');
                    
                    if (val == null || val.isEmpty) {
                      print('Email validation failed: Empty or null');
                      return 'Email tidak boleh kosong';
                    } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(val)) {
                      print('Email validation failed: Invalid format');
                      return 'Masukkan alamat email yang valid';
                    }
                    print('Email validation passed');
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: pin,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(pinCount),
                  ],
                  obscureText: true,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ).copyWith(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ).copyWith(
                    prefixIcon: Icon(
                      Icons.person_rounded,
                      color: Theme.of(context).primaryColor,
                    ),
                    hintText: 'PIN',
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'PIN tidak boleh kosong';
                    } else if (val.length != pinCount) {
                      return 'PIN harus berjumlah $pinCount karakter';
                    } else {
                      return null;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        Step(
          state: currentStep > 1 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 1,
          title: Text("Step 2"),
          content: Form(
            key: _formKey[1],
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: provinsiText,
                  readOnly: true,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ).copyWith(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ).copyWith(
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
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ).copyWith(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ).copyWith(
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
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ).copyWith(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ).copyWith(
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
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ).copyWith(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ).copyWith(
                    prefixIcon: Icon(
                      Icons.home_rounded,
                      color: Theme.of(context).primaryColor,
                    ),
                    hintText: 'Alamat Rumah',
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty)
                      return 'Alamat rumah tidak boleh kosong';
                    else
                      return null;
                  },
                ),
              ],
            ),
          ),
        ),
        Step(
          isActive: currentStep >= 2,
          title: Text("Step 3"),
          content: Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInfoText("Nama:", fieldNama, Icons.person),
                _buildInfoText("Nomor HP:", fieldNomorHp, Icons.phone),
                _buildInfoText("Email:", fieldEmail, Icons.email_rounded),
                _buildInfoText("PIN:", fieldPin, Icons.lock),
                _buildInfoText("Provinsi:", fieldProvinsi, Icons.place),
                _buildInfoText("Kota:", fieldKota, Icons.location_city),
                _buildInfoText("Kecamatan:", fieldKecamatan, Icons.map),
                _buildInfoText("Alamat:", fieldAlamat, Icons.home),
                SizedBox(height: 20),
                _agreeLabel(isAgree),
              ],
            ),
          ),
        )
      ];
}
