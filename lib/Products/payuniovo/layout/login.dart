  import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/Products/payuniovo/layout/privacy_policy.dart';
import 'package:mobile/bloc/ConfigApp.dart';
import 'package:mobile/modules.dart';
import 'package:mobile/provider/api.dart';
import 'package:mobile/Products/payuniovo/config.dart' as payuniovoConfig;
import 'package:mobile/Products/payuniovo/layout/forgot-password/step_1.dart';
import 'package:mobile/Products/payuniovo/layout/otp.dart';
import 'package:nav/nav.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _form = GlobalKey();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  void _loadCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String phone = prefs.getString('phone') ?? '';
    String pin = prefs.getString('pin') ?? '';
    
    print('=== PAYUNIOVO LOAD CREDENTIALS ===');
    print('Saved phone: $phone');
    print('Saved PIN: $pin');
    print('==================================');
    
    setState(() {
      _phone.text = phone;
      _password.text = pin;
    });
  }

  @override
  void dispose() {
    _form.currentState?.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;

    try {
      setState(() {
        _loading = true;
      });

      String phoneNumber = _phone.text.trim();
      
      print('=== PAYUNIOVO LOGIN DEBUG ===');
      print('Phone number: $phoneNumber');
      print('PIN: ${_password.text.trim()}');
      print('API URL: ${payuniovoConfig.apiUrl}/user/login');
      print('Merchant Code: ${payuniovoConfig.sigVendor}');
      print('Remember Me: $rememberMe');
      print('Timestamp: ${DateTime.now()}');
      print('================================');

      // Gunakan config PayUniOvo untuk API call
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'merchantCode': payuniovoConfig.sigVendor,
      };
      
      Map<String, dynamic> requestBody = {
        'phone': phoneNumber,
        'pin': _password.text.trim(),
      };
      
      print('=== PAYUNIOVO REQUEST DETAILS ===');
      print('Headers: $headers');
      print('Request Body: $requestBody');
      print('==================================');
      
      http.Response response = await http.post(
        Uri.parse('${payuniovoConfig.apiUrl}/user/login'),
        headers: headers,
        body: json.encode(requestBody),
      );

      print('=== PAYUNIOVO API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body Length: ${response.body.length}');
      print('Response Body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
      print('===============================');
      
      // Validasi response body sebelum parsing JSON
      if (response.body.isEmpty) {
        throw Exception('Response body kosong dari server');
      }
      
      // Cek apakah response adalah JSON valid
      if (!response.body.trim().startsWith('{') && !response.body.trim().startsWith('[')) {
        print('=== PAYUNIOVO INVALID JSON RESPONSE ===');
        print('Response tidak valid JSON: ${response.body.substring(0, 200)}');
        print('========================================');
        
        // Coba decode dengan error handling yang lebih baik
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
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error Server'),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
        return;
      }
      
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData;
        try {
          responseData = json.decode(response.body);
        } catch (jsonError) {
          print('=== PAYUNIOVO JSON PARSE ERROR ===');
          print('JSON Parse Error: $jsonError');
          print('Response Body: ${response.body}');
          print('==================================');
          
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Error Parsing Response'),
                content: Text('Gagal memproses response dari server. Silakan coba lagi atau hubungi customer service.'),
                actions: [
                  TextButton(
                    child: Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          );
          return;
        }
        
        Map<String, dynamic> data = responseData['data'];
        
        print('=== PAYUNIOVO SUCCESS ===');
        print('Response Data: $data');
        print('Phone from API: ${data['phone']}');
        print('Validate ID: ${data['validate_id']}');
        print('========================');
        
        // Save phone and PIN if rememberMe is true, else remove it.
        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (rememberMe) {
          await prefs.setString('phone', phoneNumber);
          await prefs.setString('pin', _password.text.trim());
          print('=== PAYUNIOVO SAVE CREDENTIALS ===');
          print('Saved phone: $phoneNumber');
          print('Saved PIN: ${_password.text.trim()}');
          print('==================================');
        } else {
          await prefs.remove('phone');
          await prefs.remove('pin');
          print('=== PAYUNIOVO REMOVE CREDENTIALS ===');
          print('Credentials removed');
          print('====================================');
        }

        Nav.pushReplacement(OtpPage(data['phone'], data['validate_id']));
      } else {
        // Handle error response dengan validasi JSON yang lebih baik
        Map<String, dynamic> errorData;
        try {
          errorData = json.decode(response.body);
        } catch (jsonError) {
          print('=== PAYUNIOVO ERROR JSON PARSE FAILED ===');
          print('JSON Parse Error: $jsonError');
          print('Error Response Body: ${response.body}');
          print('==========================================');
          
          // Fallback error message
          errorData = {
            'status': response.statusCode,
            'message': 'Gagal memproses error response dari server'
          };
        }
        
        print('=== PAYUNIOVO ERROR ===');
        print('Error Status: ${errorData['status']}');
        print('Error Message: ${errorData['message']}');
        print('=======================');
        
        // Tampilkan pesan error yang informatif ke user
        String errorMessage = errorData['message'] ?? 'Terjadi kesalahan';
        
        // Pesan khusus untuk "nomor tidak ditemukan"
        String customMessage = '';
        if (errorMessage.toLowerCase().contains('tidak ditemukan') || 
            errorMessage.toLowerCase().contains('not found')) {
          customMessage = 'Nomor telepon yang Anda masukkan tidak terdaftar dalam sistem. Silakan periksa kembali nomor Anda atau daftar akun baru.';
        } else {
          customMessage = errorMessage;
        }
        
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Login Gagal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customMessage),
                  SizedBox(height: 16),
                  Text(
                    'Kemungkinan penyebab:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Nomor telepon belum terdaftar'),
                  Text('• Format nomor tidak sesuai'),
                  Text('• PIN yang dimasukkan salah'),
                  Text('• Akun belum aktif'),
                  SizedBox(height: 16),
                  Text(
                    'Tips:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Pastikan nomor sudah terdaftar'),
                  Text('• Gunakan format: 08xxxxxxxxxx'),
                  Text('• Periksa kembali PIN Anda'),
                  Text('• Hubungi customer service jika perlu'),
                ],
              ),
              actions: [
                if (errorMessage.toLowerCase().contains('tidak ditemukan') || 
                    errorMessage.toLowerCase().contains('not found'))
                  TextButton(
                    child: Text('Daftar Akun'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to register page
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PrivacyPolicyPage(),
                        ),
                      );
                    },
                  ),
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        
        throw errorData;
      }
    } catch (e) {
      print('=== PAYUNIOVO EXCEPTION ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception: $e');
      print('===========================');
      
      String msg;
      if (e is Map<String, dynamic>) {
        msg = e['message'] ?? 'Terjadi kesalahan';
      } else if (e is FormatException) {
        msg = 'Format response tidak valid: ${e.message}';
      } else if (e.toString().contains('unexpected character')) {
        msg = 'Response dari server tidak valid. Silakan coba lagi atau hubungi customer service.';
      } else {
        msg = e.toString();
      }
      showToast(context, msg);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Container(
                height: height / 2,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(60),
                      bottomLeft: Radius.circular(60),
                    )),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 70,
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://payuni.co.id/mobile/newLogoPutihRefisi.png',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Satu Genggaman untuk Semua Kebutuhan',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Roboto',
                          fontStyle: FontStyle.normal),
                    )
                  ],
                ),
              ),
              SingleChildScrollView(
                child: Form(
                  key: _form,
                  child: SizedBox(
                    height: height,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 20),
                          height: height / 1.9,
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Login Account',
                                style: TextStyle(
                                    fontSize: 23, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(
                                height: 22,
                              ),
                              SizedBox(
                                height: 40,
                                child: TextFormField(
                                  controller: _phone,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                      labelText: 'Nomor Telepon',
                                      labelStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(26),
                                          borderSide: BorderSide(
                                              color: Color(0XFFDADADA))),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(26)),
                                      ),
                                      suffixIcon: Icon(Icons.phone_android)),
                                  validator: (value) {
                                    String str = value ?? '';

                                    if (str.length == 0) {
                                      return 'Nomor handphone harus diisi';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 40,
                                child: TextFormField(
                                  controller: _password,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(
                                        configAppBloc
                                            .pinCount.valueWrapper?.value),
                                  ],
                                  obscureText: _hidePassword,
                                  decoration: InputDecoration(
                                      isDense: true,
                                      // filled: true,
                                      labelText: 'PIN',
                                      labelStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(26),
                                          borderSide: BorderSide(
                                              color: Color(0XFFDADADA))),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(26)),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(_hidePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility),
                                        onPressed: () {
                                          setState(() {
                                            _hidePassword = !_hidePassword;
                                          });
                                        },
                                      )),
                                  validator: (value) {
                                    String str = value ?? '';

                                    if (str.length == 0) {
                                      return 'PIN tidak boleh kosong';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SwitchListTile.adaptive(
                                activeColor: Theme.of(context).primaryColor,
                                value: rememberMe,
                                onChanged: ((bool value) async {
                                  // onChanged should be asynchronous
                                  setState(() {
                                    rememberMe = value;
                                  });
                                  if (rememberMe) {
                                    SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    prefs.setString('password',
                                        _password.text); // Save password
                                  } else {
                                    SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    prefs.remove(
                                        'password'); // Remove password if rememberMe is not checked
                                  }
                                }),
                                contentPadding: const EdgeInsets.all(0),
                                title: Text('Remember me',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0XFFDADADA))),
                              ),
                              MaterialButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(31)),
                                height: 40,
                                color: Theme.of(context).primaryColor,
                                onPressed: _loading
                                    ? null
                                    : _login, // disable button when loading
                                child: _loading
                                    ? SpinKitThreeBounce(
                                        color: Colors.white,
                                        size: 20.0,
                                      )
                                    : const Text(
                                        'LOG IN',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700),
                                      ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Divider(
                                      thickness: 1,
                                      height: 1,
                                      color: Color(0XFFDADADA),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Text('or',
                                      style: TextStyle(
                                          color: Color(0XFFDADADA),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Expanded(
                                    child: Divider(
                                      thickness: 1,
                                      height: 1,
                                      color: Color(0XFFDADADA),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              Container(
                                child: InkWell(
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => StepOneForgotPIN())),
                                  child: Text(
                                    'Forget password?',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0XFFDADADA)),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Don’t have an account?',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => PrivacyPolicyPage()));
                              },
                              child: Text(
                                'Sign up now',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w700),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 44,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class Input extends StatelessWidget {
  Input({
    Key? key,
    required this.hint,
    required this.icon,
  }) : super(key: key);

  String hint;
  IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
          labelText: hint,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(26),
              borderSide: BorderSide(color: Color(0XFFDADADA))),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
            borderRadius: const BorderRadius.all(Radius.circular(26)),
          ),
          suffixIcon: Icon(icon)),
    );
  }
}
