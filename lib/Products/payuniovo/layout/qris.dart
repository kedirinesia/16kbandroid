import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mobile/component/alert.dart';
import 'package:mobile/provider/api.dart';
import 'package:mobile/bloc/Bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/modules.dart';

// Import untuk KYC pages
import 'package:mobile/screen/kyc/waiting.dart';
import 'package:mobile/screen/kyc/reject.dart';
import 'package:mobile/screen/kyc/verification1.dart';

// Import untuk NavbarHome payuniovo
import 'navbar.dart';

// Import untuk domicile data
import 'package:mobile/models/lokasi.dart';
import 'package:mobile/screen/select_state/provinsi.dart';
import 'package:mobile/screen/select_state/kota.dart';
import 'package:mobile/screen/select_state/kecamatan.dart';

// Import untuk MCC selection
import 'package:mobile/models/mcc_code.dart';
import 'package:mobile/screen/select_state/mccid.dart';
import 'package:mobile/config.dart';
import 'package:mobile/bloc/Api.dart';

class MyQrisPage extends StatefulWidget {
  @override
  _MyQrisPageState createState() => _MyQrisPageState();
}

class QrisRequestFormPage extends StatefulWidget {
  @override
  _QrisRequestFormPageState createState() => _QrisRequestFormPageState();
}

class _QrisRequestFormPageState extends State<QrisRequestFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  final TextEditingController _namaLengkapController = TextEditingController();
  final TextEditingController _namaUsahaController = TextEditingController();
  final TextEditingController _noNpwpController = TextEditingController();
  final TextEditingController _mccIdController = TextEditingController();
  final TextEditingController _namaJalanController = TextEditingController();
  final TextEditingController _nomorJalanController = TextEditingController();
  final TextEditingController _rtController = TextEditingController();
  final TextEditingController _rwController = TextEditingController();
  final TextEditingController _kelurahanController = TextEditingController();
  final TextEditingController _kecamatanController = TextEditingController();
  final TextEditingController _kabupatenController = TextEditingController();
  final TextEditingController _kodePosController = TextEditingController();
  final TextEditingController _tokoFisikController = TextEditingController();
  final TextEditingController _pendapatanController = TextEditingController();
  
  // Controllers for domicile fields (Provinsi, Kabupaten, Kecamatan, Kelurahan)
  final TextEditingController _provinsiDropdownController = TextEditingController();
  final TextEditingController _kabupatenDropdownController = TextEditingController();
  final TextEditingController _kecamatanDropdownController = TextEditingController();
  final TextEditingController _kelurahanDropdownController = TextEditingController();
  
  // Controllers for display fields (read-only)
  final TextEditingController _noKtpController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();
  final TextEditingController _alamatEmailController = TextEditingController();
  
  // State variables for domicile selection
  Lokasi? _selectedProvinsi;
  Lokasi? _selectedKabupaten;
  Lokasi? _selectedKecamatan;
  Lokasi? _selectedKelurahan;
  
  // State variable for MCC selection
  MccCode? _selectedMcc;
  
  bool _isLoading = false;
  
  // Dropdown options for pendapatan per tahun (will be loaded from API)
  List<String> _pendapatanOptions = [];
  
  // Dropdown options for toko fisik
  final List<String> _tokoFisikOptions = [
    'ya',
    'tidak'
  ];
  
  String? _selectedPendapatan;
  String? _selectedTokoFisik;
  
  // Variable untuk foto usaha
  File? _fotoUsaha;

  @override
  void initState() {
    super.initState();
    _loadPendapatanOptions();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    try {
      final token = bloc.token.valueWrapper?.value;
      final url = Uri.parse('https://payuni-app.findig.id/api/v1/qris/submission');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': token ?? '',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200 && data['data'] != null) {
          final submissionData = data['data'];
          
          setState(() {
            _namaLengkapController.text = submissionData['nama_lengkap'] ?? '';
            _namaUsahaController.text = submissionData['nama_usaha'] ?? '';
            _noNpwpController.text = submissionData['no_npwp'] ?? '';
            
            // Load display fields from API
            _noKtpController.text = submissionData['no_ktp'] ?? '';
            _noHpController.text = submissionData['no_hp'] ?? '';
            _alamatEmailController.text = submissionData['alamat_email'] ?? '';
            
            // Handle MCC ID - fetch MCC details to display name instead of ID
            if (submissionData['mcc_id'] != null) {
              _loadMccDetails(submissionData['mcc_id']);
            }
            
            // Handle nested alamat_usaha object
            final alamatUsaha = submissionData['alamat_usaha'];
            if (alamatUsaha != null && alamatUsaha is Map) {
              _namaJalanController.text = alamatUsaha['nama_jalan'] ?? '';
              _nomorJalanController.text = alamatUsaha['nomor_jalan'] ?? '';
              _rtController.text = alamatUsaha['rt'] ?? '';
              _rwController.text = alamatUsaha['rw'] ?? '';
              _kelurahanController.text = alamatUsaha['kelurahan'] ?? '';
              // Kecamatan not auto-fetched - user must select manually
            } else {
              // Fallback to root level if alamat_usaha doesn't exist
              _namaJalanController.text = submissionData['nama_jalan'] ?? '';
              _nomorJalanController.text = submissionData['nomor_jalan'] ?? '';
              _rtController.text = submissionData['rt'] ?? '';
              _rwController.text = submissionData['rw'] ?? '';
              _kelurahanController.text = submissionData['kelurahan'] ?? '';
              // Kecamatan not auto-fetched - user must select manually
            }
            
            _kabupatenController.text = submissionData['kabupaten'] ?? '';
            _kodePosController.text = submissionData['kode_pos'] ?? '';
            _tokoFisikController.text = submissionData['toko_fisik'] ?? '';
            _pendapatanController.text = submissionData['pendapatan_per_tahun'] ?? '';
            
            // Handle domicile dropdown fields if they exist in the data
            if (submissionData['provinsi_id'] != null) {
              _provinsiDropdownController.text = submissionData['provinsi'] ?? '';
            }
            if (submissionData['kabupaten_id'] != null) {
              _kabupatenDropdownController.text = submissionData['kabupaten'] ?? '';
            }
            if (submissionData['kecamatan_id'] != null) {
              _kecamatanDropdownController.text = submissionData['kecamatan'] ?? '';
            }
            // Also populate the regular kecamatan controller for the dropdown field
            if (submissionData['kecamatan'] != null) {
              _kecamatanController.text = submissionData['kecamatan'] ?? '';
            }
            if (submissionData['kelurahan_id'] != null) {
              _kelurahanDropdownController.text = submissionData['kelurahan'] ?? '';
            }
            // Also populate the regular kelurahan controller for the text field
            if (submissionData['kelurahan'] != null) {
              _kelurahanController.text = submissionData['kelurahan'] ?? '';
            }
            
            // Handle dropdown value - only set if it exists in options
            final existingPendapatan = submissionData['pendapatan_per_tahun'];
            if (existingPendapatan != null && _pendapatanOptions.contains(existingPendapatan)) {
              _selectedPendapatan = existingPendapatan;
            } else if (existingPendapatan != null && existingPendapatan.contains('UMI - Penjualan/Tahun < 300 Juta')) {
              // Handle case where API returns UMI without "( Default)" suffix
              if (_pendapatanOptions.contains('UMI - Penjualan/Tahun < 300 Juta ( Default)')) {
                _selectedPendapatan = 'UMI - Penjualan/Tahun < 300 Juta ( Default)';
              } else if (_pendapatanOptions.contains('UMI - Penjualan/Tahun < 300 Juta')) {
                _selectedPendapatan = 'UMI - Penjualan/Tahun < 300 Juta';
              }
            }
            // If no existing data, keep the default UMI value that was set in _loadPendapatanOptions
            
            // Handle toko fisik dropdown value
            final existingTokoFisik = submissionData['toko_fisik'];
            if (existingTokoFisik != null && _tokoFisikOptions.contains(existingTokoFisik)) {
              _selectedTokoFisik = existingTokoFisik;
            } else {
              _selectedTokoFisik = null;
            }
          });
        }
      }
    } catch (e) {
      print('[DEBUG] Payuniovo: Error loading existing data: $e');
    }
  }

    Future<void> _loadMccDetails(String mccId) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/mcc/list'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          List<dynamic> mccList = data['data'];
          
       
            for (var mccData in mccList) {
              if (mccData['_id'] == mccId) {
                final mcc = MccCode.fromJson(mccData);
                setState(() {
                  _selectedMcc = mcc;
                  _mccIdController.text = '${mcc.kode} - ${mcc.nama}';
                });
                break;
              }
            }
          }
        }
      } catch (e) {
        print('[DEBUG] Payuniovo: Error loading MCC details: $e');
      
        setState(() {
          _mccIdController.text = mccId;
        });
      }
    }

  Future<void> _loadPendapatanOptions() async {
    try {
      print('[DEBUG] Payuniovo: Loading pendapatan options from API...');
      final response = await http.get(Uri.parse('https://payuni-app.findig.id/api/v1/qris/kategori-usaha'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[DEBUG] Payuniovo: Pendapatan API response: $data');
        
        if (data['status'] == 200 && data['data'] != null) {
          List<dynamic> pendapatanList = data['data'];
          setState(() {
            _pendapatanOptions = pendapatanList.cast<String>();
            // Set default value to UMI if available
            if (_pendapatanOptions.contains('UMI - Penjualan/Tahun < 300 Juta ( Default)')) {
              _selectedPendapatan = 'UMI - Penjualan/Tahun < 300 Juta ( Default)';
            } else if (_pendapatanOptions.contains('UMI - Penjualan/Tahun < 300 Juta')) {
              _selectedPendapatan = 'UMI - Penjualan/Tahun < 300 Juta';
            }
          });
          print('[DEBUG] Payuniovo: Loaded ${_pendapatanOptions.length} pendapatan options');
        } else {
          print('[DEBUG] Payuniovo: API returned error status: ${data['status']}');
        }
      } else {
        print('[DEBUG] Payuniovo: HTTP error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('[DEBUG] Payuniovo: Error loading pendapatan options: $e');
      // Fallback to default options if API fails
      setState(() {
        _pendapatanOptions = [
          'UMI - Penjualan/Tahun < 300 Juta ( Default)',
          'UKE - Penjualan/Tahun > 300 Juta - 2,5 Milyar',
          'UME - Penjualan/Tahun > 2,5 Milyar - 50 Milyar',
          'UBE - Penjualan/Tahun > 50Milyar',
          'URE - Penjualan/Tahun Donasi, Sosial, Non Profit & dll',
          'PSO - Penjualan/Tahun Pelayanan Pemerintahan dll'
        ];
        // Set default value to UMI
        _selectedPendapatan = 'UMI - Penjualan/Tahun < 300 Juta ( Default)';
      });
    }
  }
  
  // Method untuk mengambil foto usaha
  Future<void> _getFotoUsaha() async {
    try {
      File image = await getPhoto();
      if (image != null) {
        setState(() {
          _fotoUsaha = image;
        });
      }
    } catch (e) {
      print('[DEBUG] Payuniovo: Error taking foto usaha: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      print('[DEBUG] Payuniovo: Form validation failed');
      return;
    }

    print('[DEBUG] Payuniovo: ===== SUBMIT FORM START =====');
    print('[DEBUG] Payuniovo: Form validation passed');

    // Additional validation to ensure no empty fields
    final fields = {
      'nama_lengkap': _namaLengkapController.text.trim(),
      'nama_usaha': _namaUsahaController.text.trim(),
      'no_npwp': _noNpwpController.text.trim(),
      'mcc_id': _selectedMcc?.id ?? _mccIdController.text.trim(),
      'nama_jalan': _namaJalanController.text.trim(),
      'nomor_jalan': _nomorJalanController.text.trim(),
      'rt': _rtController.text.trim(),
      'rw': _rwController.text.trim(),
      'kelurahan': _kelurahanController.text.trim(),
      'kecamatan': _kecamatanController.text.trim(),
      'kabupaten': _kabupatenDropdownController.text.trim(),
      'kode_pos': _kodePosController.text.trim(),
      'toko_fisik': _selectedTokoFisik ?? _tokoFisikController.text.trim(),
      'pendapatan_per_tahun': (_selectedPendapatan ?? _pendapatanController.text).trim(),
      'keterangan': 'submitted',
      // Add domicile data if selected
      if (_selectedProvinsi != null) 'provinsi_id': _selectedProvinsi!.id,
      if (_selectedKecamatan != null) 'kecamatan_id': _selectedKecamatan!.id,
      if (_selectedKelurahan != null) 'kelurahan_id': _selectedKelurahan!.id,
    };

    print('[DEBUG]  : Raw form data:');
    print('[DEBUG]  : - nama_lengkap: "${_namaLengkapController.text.trim()}"');
    print('[DEBUG]  : - nama_usaha: "${_namaUsahaController.text.trim()}"');
    print('[DEBUG]  : - no_npwp: "${_noNpwpController.text.trim()}"');
    print('[DEBUG]  : - mcc_id: "${_selectedMcc?.id ?? _mccIdController.text.trim()}"');
    print('[DEBUG]  : - nama_jalan: "${_namaJalanController.text.trim()}"');
    print('[DEBUG]  : - nomor_jalan: "${_nomorJalanController.text.trim()}"');
    print('[DEBUG]  : - rt: "${_rtController.text.trim()}"');
    print('[DEBUG]  : - rw: "${_rwController.text.trim()}"');
    print('[DEBUG]  : - kelurahan: "${_kelurahanController.text.trim()}"');
    print('[DEBUG]  : - kecamatan: "${_kecamatanController.text.trim()}"');
    print('[DEBUG]  : - kabupaten: "${_kabupatenDropdownController.text.trim()}"');
    print('[DEBUG]  : - kode_pos: "${_kodePosController.text.trim()}"');
    print('[DEBUG]  : - toko_fisik: "${_selectedTokoFisik ?? _tokoFisikController.text.trim()}"');
    print('[DEBUG]  : - pendapatan_per_tahun: "${(_selectedPendapatan ?? _pendapatanController.text).trim()}"');
    print('[DEBUG]  : - keterangan: "submitted"');
    
    if (_selectedProvinsi != null) {
      print('[DEBUG]  : - provinsi_id: "${_selectedProvinsi!.id}"');
    }
    if (_selectedKecamatan != null) {
      print('[DEBUG]  : - kecamatan_id: "${_selectedKecamatan!.id}"');
    }
    if (_selectedKelurahan != null) {
      print('[DEBUG]  : - kelurahan_id: "${_selectedKelurahan!.id}"');
    }

    print('[DEBUG]  : Final fields object: $fields');

    // Check for empty fields (excluding optional fields)
    print('[DEBUG]  : Checking for empty fields...');
    for (String fieldName in fields.keys) {
      // Skip validation for optional fields
      if (fieldName == 'no_npwp') {
        print('[DEBUG] Payuniovo: ✅ Skipping validation for optional field: $fieldName');
        continue;
      }
      
      if (fields[fieldName]!.isEmpty) {
        print('[DEBUG]   ❌ Empty field found: $fieldName');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Field $fieldName tidak boleh kosong'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      } else {
        print('[DEBUG] Payuniovo: ✅ Field $fieldName is filled: "${fields[fieldName]}"');
      }
    }
    print('[DEBUG] Payuniovo: ✅ All required fields are filled');
    
    // Validate foto usaha
    if (_fotoUsaha == null) {
      print('[DEBUG] Payuniovo: ❌ Foto usaha is required');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Foto usaha wajib diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    print('[DEBUG] Payuniovo: ✅ Foto usaha is provided');

    setState(() {
      _isLoading = true;
    });

    try {
      final token = bloc.token.valueWrapper?.value;
      final url = Uri.parse('https://payuni-app.findig.id/api/v1/qris/submission/update');
      
      print('[DEBUG] Payuniovo: ===== SENDING REQUEST =====');
      print('[DEBUG] Payuniovo: URL: $url');
      print('[DEBUG] Payuniovo: Token: ${token != null ? "Available" : "Not available"}');
      
      // Create MultipartRequest for file upload
      http.MultipartRequest request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = token ?? '';
      
      // Add form fields
      request.fields.addAll(fields);
      
      // Add foto usaha if available
      if (_fotoUsaha != null) {
        print('[DEBUG] Payuniovo: Adding foto usaha to request');
        request.files.add(await http.MultipartFile.fromPath('foto_usaha', _fotoUsaha!.path));
      } else {
        print('[DEBUG] Payuniovo: No foto usaha provided');
      }
      
      print('[DEBUG] Payuniovo: Request fields: ${request.fields}');
      print('[DEBUG] Payuniovo: Request files: ${request.files.map((f) => f.field).toList()}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('[DEBUG] Payuniovo: ===== RESPONSE RECEIVED =====');
      print('[DEBUG] Payuniovo: Response status code: ${response.statusCode}');
      print('[DEBUG] Payuniovo: Response headers: ${response.headers}');
      print('[DEBUG] Payuniovo: Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('[DEBUG] Payuniovo: ✅ Request successful');
        // Navigate back to QRIS page with success result
        Navigator.pop(context, true);
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data berhasil disimpan. QRIS sedang diproses.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('[DEBUG] Payuniovo: ❌ Request failed with status: ${response.statusCode}');
        throw Exception('Failed to submit form');
      }
    } catch (e) {
      print('[DEBUG] Payuniovo: ❌ Exception occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('[DEBUG] Payuniovo: ===== SUBMIT FORM END =====');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Form Request QRIS Static'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? Center(child: SpinKitFadingCircle(color: Theme.of(context).primaryColor))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     
                    SizedBox(height: 10),
                    
                    // Nama Lengkap
                    TextFormField(
                      controller: _namaLengkapController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama lengkap harus diisi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Nama Usaha
                    TextFormField(
                      controller: _namaUsahaController,
                      decoration: InputDecoration(
                        labelText: 'Nama Usaha *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama usaha harus diisi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // No KTP (Read-only display)
                    TextFormField(
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'No KTP',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      controller: _noKtpController,
                    ),
                    SizedBox(height: 16),
                    
                    // No HP (Read-only display)
                    TextFormField(
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'No HP',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      controller: _noHpController,
                    ),
                    SizedBox(height: 16),
                    
                    // Alamat Email (Read-only display)
                    TextFormField(
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Alamat Email',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      controller: _alamatEmailController,
                    ),
                    SizedBox(height: 16),
                    
                    // No NPWP
                    TextFormField(
                      controller: _noNpwpController,
                      decoration: InputDecoration(
                        labelText: 'No NPWP (Opsional)',
                        border: OutlineInputBorder(),
                        hintText: 'No NPWP (Opsional)',
                      ),
                      validator: (value) {
                        // NPWP is optional, so no validation needed
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // MCC ID (Dropdown)
                    TextFormField(
                      controller: _mccIdController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Jenis usaha *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      onTap: () async {
                        MccCode? mcc = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectMccCodePage(),
                          ),
                        );

                        if (mcc != null) {
                          setState(() {
                            _selectedMcc = mcc;
                            _mccIdController.text = '${mcc.kode} - ${mcc.nama}';
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'MCC ID harus dipilih';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Provinsi (Dropdown)
                    TextFormField(
                      controller: _provinsiDropdownController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Provinsi *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      onTap: () async {
                        Lokasi? provinsi = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectProvinsiPage(),
                          ),
                        );

                        if (provinsi != null) {
                          setState(() {
                            _selectedProvinsi = provinsi;
                            _selectedKabupaten = null;
                            _selectedKecamatan = null;
                            _selectedKelurahan = null;
                            _provinsiDropdownController.text = provinsi.nama;
                            _kabupatenDropdownController.clear();
                            _kecamatanController.clear();
                            _kelurahanDropdownController.clear();
                            _kelurahanController.clear();
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Provinsi harus dipilih';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Kabupaten (Dropdown) - Only for selecting Kecamatan
                    TextFormField(
                      controller: _kabupatenDropdownController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Kabupaten',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      onTap: () async {
                        if (_selectedProvinsi == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Pilih Provinsi terlebih dahulu')),
                          );
                          return;
                        }

                        Lokasi? kabupaten = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectKotaPage(_selectedProvinsi!),
                          ),
                        );

                        if (kabupaten != null) {
                          print('[DEBUG] Payuniovo: Selected Kabupaten: ${kabupaten.nama}');
                          setState(() {
                            _selectedKabupaten = kabupaten;
                            _selectedKecamatan = null;
                            _selectedKelurahan = null;
                            _kabupatenDropdownController.text = kabupaten.nama;
                            _kecamatanController.clear();
                            _kelurahanDropdownController.clear();
                            _kelurahanController.clear();
                          });
                          print('[DEBUG] Payuniovo: Kabupaten controller text: ${_kabupatenDropdownController.text}');
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Kecamatan (Dropdown)
                    TextFormField(
                      controller: _kecamatanController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Kecamatan *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      onTap: () async {
                        if (_selectedKabupaten == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Pilih Kabupaten terlebih dahulu')),
                          );
                          return;
                        }

                        Lokasi? kecamatan = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectKecamatanPage(_selectedKabupaten!),
                          ),
                        );

                        if (kecamatan != null) {
                          setState(() {
                            _selectedKecamatan = kecamatan;
                            _selectedKelurahan = null;
                            _kecamatanController.text = kecamatan.nama;
                            _kelurahanDropdownController.clear();
                            _kelurahanController.clear();
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kecamatan harus dipilih';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Kelurahan (Text Field)
                    TextFormField(
                      controller: _kelurahanController,
                      decoration: InputDecoration(
                        labelText: 'Kelurahan *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kelurahan harus diisi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Nama Jalan
                    TextFormField(
                      controller: _namaJalanController,
                      decoration: InputDecoration(
                        labelText: 'Nama Jalan *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama jalan harus diisi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Nomor Jalan
                    TextFormField(
                      controller: _nomorJalanController,
                      decoration: InputDecoration(
                        labelText: 'Nomor Jalan *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nomor jalan harus diisi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // RT
                    TextFormField(
                      controller: _rtController,
                      decoration: InputDecoration(
                        labelText: 'RT *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'RT harus diisi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // RW
                    TextFormField(
                      controller: _rwController,
                      decoration: InputDecoration(
                        labelText: 'RW *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'RW harus diisi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Kode Pos
                    TextFormField(
                      controller: _kodePosController,
                      decoration: InputDecoration(
                        labelText: 'Kode Pos *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kode pos harus diisi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Toko Fisik
                    DropdownButtonFormField<String>(
                      value: _selectedTokoFisik,
                      decoration: InputDecoration(
                        labelText: 'Toko Fisik *',
                        border: OutlineInputBorder(),
                      ),
                      items: _tokoFisikOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedTokoFisik = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Toko fisik harus dipilih';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Pendapatan Per Tahun
                    DropdownButtonFormField<String>(
                      value: _selectedPendapatan != null && _pendapatanOptions.contains(_selectedPendapatan) 
                          ? _selectedPendapatan 
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Kategori Usaha *',
                        border: OutlineInputBorder(),
                      ),
                      items: _pendapatanOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value.contains('UMI - Penjualan/Tahun < 300 Juta') 
                                ? '$value (Default)'
                                : value,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPendapatan = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pendapatan per tahun harus dipilih';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 8),
                    
                    // Keterangan UMI
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'UMI ( Scan Qris static di bawah 500K Free Admin )',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Foto Usaha
                    Text(
                      'Foto Usaha *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: _getFotoUsaha,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _fotoUsaha != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _fotoUsaha!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap untuk mengambil foto usaha',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    if (_fotoUsaha == null)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Foto usaha wajib diisi',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Submit Request QRIS',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _namaUsahaController.dispose();
    _noNpwpController.dispose();
    _mccIdController.dispose();
    _namaJalanController.dispose();
    _nomorJalanController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _kelurahanController.dispose();
    _kecamatanController.dispose();
    _kabupatenController.dispose();
    _kodePosController.dispose();
    _tokoFisikController.dispose();
    _pendapatanController.dispose();
    _provinsiDropdownController.dispose();
    _kabupatenDropdownController.dispose();
    _kecamatanDropdownController.dispose();
    _kelurahanDropdownController.dispose();
    _noKtpController.dispose();
    _noHpController.dispose();
    _alamatEmailController.dispose();
    super.dispose();
  }
}

class _MyQrisPageState extends State<MyQrisPage> {
  ScreenshotController _screenshotController = ScreenshotController();
  File? image;
  int _refreshKey = 0;

  bool _checkAllRequiredFields(Map<String, dynamic> submissionData) {
    print('[DEBUG] Payuniovo: Checking keterangan field...');
    print('[DEBUG] Payuniovo: Submission data keys: ${submissionData.keys.toList()}');
    
    // Check keterangan field
    final keterangan = submissionData['keterangan'];
    print('[DEBUG] Payuniovo: Raw keterangan value: $keterangan');
    print('[DEBUG] Payuniovo: Keterangan type: ${keterangan.runtimeType}');
    print('[DEBUG] Payuniovo: Keterangan toString: ${keterangan.toString()}');
    final keteranganEmpty = keterangan == null || keterangan.toString().trim().isEmpty;
    print('[DEBUG] Payuniovo: Root field keterangan = $keterangan (isEmpty: $keteranganEmpty)');
    
    if (keteranganEmpty) {
      print('[DEBUG] Payuniovo: Missing or empty root field: keterangan');
      return false;
    }
    
    print('[DEBUG] Payuniovo: Keterangan field is filled');
    print('[DEBUG] Payuniovo: Validation completed successfully');
    return true;
  }

  Future<Map<String, dynamic>> _checkQrisStatus() async {
    try {
      print('=== CHECK QRIS STATUS START ===');
      final token = bloc.token.valueWrapper?.value;
      final url = Uri.parse('https://payuni-app.findig.id/api/v1/qris/submission');

      print('[DEBUG] Payuniovo: Checking QRIS status with URL: $url');
      print('[DEBUG] Payuniovo: Token: ${token != null ? "Available" : "Not available"}');

      final response = await http.get(
        url,
        headers: {
          'Authorization': token ?? '',
          'Content-Type': 'application/json',
        },
      );

      print('[DEBUG] Payuniovo: HTTP status: ${response.statusCode}');
      print('[DEBUG] Payuniovo: Raw response body: ${response.body}');
      
      final data = json.decode(response.body);
      print('[DEBUG] Payuniovo: API JSON: $data');

      if (response.statusCode == 200 && data['status'] == 200) {
        final submissionData = data['data'];
        final qrisImage = submissionData['qris_image'];
        
        print('[DEBUG] Payuniovo: QRIS Image: $qrisImage');
        print('[DEBUG] Payuniovo: Full submission data: $submissionData');
        
        // Condition 1: Belum KYC (tidak ada data submission)
        if (submissionData == null) {
          print('=== QRIS STATUS: BELUM KYC ===');
          return {'status': 'not_kyc'};
        }
        
        // NEW LOGIC: If qris_image is not null and not empty string, show QRIS immediately regardless of status_qris
        if (qrisImage != null && 
            qrisImage.toString().trim().isNotEmpty && 
            qrisImage.toString().trim() != "") {
          print('=== QRIS STATUS: QRIS IMAGE AVAILABLE - SHOW IMMEDIATELY ===');
          return {
            'status': 'qris_available',
            'image': qrisImage,
          };
        }
        
        // Check status_qris status from API (only if no qris_image)
        final statusQris = submissionData['status_qris'];
        print('[DEBUG] Payuniovo: Status QRIS from API: $statusQris');
        
        if (statusQris == null || statusQris == '' || statusQris == 'not-process') {
          print('=== QRIS STATUS: NOT PROCESS - BELUM SUBMIT ===');
          return {'status': 'kyc_completed_no_qris'};
        }
        
        if (statusQris == 'submitted') {
          print('=== QRIS STATUS: SUBMITTED - SUDAH SUBMIT ===');
          return {'status': 'submitted_success', 'message': 'Data berhasil disimpan. QRIS sedang diproses.'};
        }
        
        if (statusQris == 'pending') {
          print('=== QRIS STATUS: PENDING - SEDANG DIPROSES ===');
          return {'status': 'processing_qris', 'message': 'QRIS Static anda sedang di proses, silahkan tunggu beberapa hari'};
        }
        
        if (statusQris == 'approve') {
          print('=== QRIS STATUS: APPROVE - QRIS TAMPIL ===');
          return {
            'status': 'qris_available',
            'image': qrisImage,
          };
        }
        
        if (statusQris == 'reject') {
          print('=== QRIS STATUS: REJECT ===');
          final rejectionReason = submissionData['keterangan'] ?? 'Data tidak lengkap atau tidak sesuai dengan persyaratan yang ditentukan. Silakan perbaiki data Anda dan daftar ulang.';
          return {'status': 'qris_rejected', 'reason': rejectionReason};
        }
        
        // Default fallback
        print('=== QRIS STATUS: UNKNOWN STATUS ===');
        return {'status': 'unknown'};
      } else {
        print('[DEBUG] Payuniovo: API error - Status: ${data['status']}, Message: ${data['message']}');
        return {'status': 'error', 'message': data['message'] ?? 'Unknown error'};
      }
    } catch (err) {
      print('[DEBUG] Payuniovo: Exception ketika check QRIS status: $err');
      return {'status': 'error', 'error': err.toString()};
    }
  }

  Future<Map<String, dynamic>> _getQr() async {
    try {
      print('=== GENERATE QRIS START ===');
      print('[DEBUG] Payuniovo: Requesting QRIS...');
      final token = bloc.token.valueWrapper?.value;
      final url = Uri.parse('https://payuni-app.findig.id/api/v1/qris/generate');

      print('[DEBUG] Payuniovo: Using URL: $url');
      print('[DEBUG] Payuniovo: Token: ${token != null ? "Available" : "Not available"}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': token ?? '',
        },
      );

      print('[DEBUG] Payuniovo: HTTP status: ${response.statusCode}');
      print('[DEBUG] Payuniovo: Raw response body: ${response.body}');
      print('[DEBUG] Payuniovo: Response headers: ${response.headers}');
      
      final data = json.decode(response.body);
      print('[DEBUG] Payuniovo: API JSON: $data');
      print('[DEBUG] Payuniovo: Response type: ${data.runtimeType}');
      print('[DEBUG] Payuniovo: Response keys: ${data.keys.toList()}');

      if (data != null && data['status'] == 500) {
        print('[DEBUG] Payuniovo: Status 500 terdeteksi dari API JSON');
        print('=== GENERATE QRIS END - STATUS: 500 ===');
        return {'status': 500, 'message': data['message'] ?? ''};
      }

      if (data != null &&
          data['image'] != null &&
          data['image'].toString().trim().isNotEmpty) {
        print('[DEBUG] Payuniovo: Berhasil dapat image URL: ${data['image']}');
        print('=== GENERATE QRIS END - STATUS: 200 WITH IMAGE ===');
        return {
          'status': 200,
          'image': data['image'],
        };
      } else if (data != null &&
          data['status'] == 200 &&
          (data['image'] == null || data['image'].toString().trim().isEmpty)) {
        // status 200 tapi image kosong
        print('[DEBUG] Payuniovo: Status 200 tapi image kosong');
        print('=== GENERATE QRIS END - STATUS: 200 NO IMAGE ===');
        return {'status': 200, 'image': ''};
      } else {
        print('[DEBUG] Payuniovo: Image kosong/tidak ada!');
        print('=== GENERATE QRIS END - STATUS: -2 ===');
        return {'status': -2};
      }
    } catch (err) {
      print('[DEBUG] Payuniovo: Exception ketika get QR: $err');
      print('=== GENERATE QRIS END - ERROR ===');
      return {'status': -1, 'error': err.toString()};
    }
  }

  Future<void> _takeScreenshot() async {
    print('[DEBUG] Payuniovo: Taking screenshot...');
    Directory temp = await getTemporaryDirectory();
    image = await File('${temp.path}/qris.png').create();
    Uint8List? bytes = await _screenshotController.capture(
      pixelRatio: 2.5,
      delay: Duration(milliseconds: 100),
    );
    await image?.writeAsBytes(bytes!);
    if (image == null) return;
    await Share.file(
      'QRIS Saya',
      'qris.png',
      image!.readAsBytesSync(),
      'image/png',
    );
    print('[DEBUG] Payuniovo: Screenshot saved and shared');
  }

  Widget _notKycPage() {
    print('[DEBUG] Payuniovo: Showing not KYC page');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(
              "Belum KYC",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Untuk pendaftaran qris akun anda harus melakukan verifikasi kyc terlebih dahulu pada menu profile -> profile detail -> verifikasi",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => NavbarHome()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  "KYC Sekarang",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kycCompletedNoQrisPage() {
    print('[DEBUG] Payuniovo: Showing KYC completed but no QRIS page');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code, color: Colors.blue, size: 48),
            const SizedBox(height: 16),
            Text(
              "KYC Selesai",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Akun Anda sudah terverifikasi\nSekarang Anda dapat request QRIS",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QrisRequestFormPage()),
                  );
                  
                  // If form was submitted successfully, refresh the page
                  if (result == true) {
                    setState(() {
                      _refreshKey++; // This will force FutureBuilder to rebuild
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  "Request QRIS",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _processingQrisPage([String? customMessage]) {
    print('[DEBUG] Payuniovo: Showing processing QRIS page');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: 'http://static.vecteezy.com/system/resources/thumbnails/022/892/180/small_2x/work-process-3d-rendering-transparent-backgorund-design-and-development-png.png',
              width: 120,
              height: 120,
              placeholder: (context, url) => SpinKitFadingCircle(
                color: Theme.of(context).primaryColor,
                size: 48,
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.work,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "QRIS Sedang Diproses",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              customMessage ?? "Mohon tunggu QRIS anda akan tersedia dalam beberapa hari",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => NavbarHome()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  "Kembali ke HOME",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waitingBankVerificationPage() {
    print('[DEBUG] Payuniovo: Showing waiting bank verification page');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Checklist hijau
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 8),
            // Selamat (bold)
            Text(
              "Selamat",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Deskripsi bawah Selamat
            Text(
              "Akun Anda Berhasil Di Verifikasi\nsekarang anda dapat akses lebih di Payuni",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),

             
 
            // Teks status QRIS
             
            const SizedBox(height: 32),
            // Tombol Back to Home
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => NavbarHome()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  "Back to Home",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getQrisWidget(Map<String, dynamic> result) {
    print('[DEBUG] Payuniovo: Masuk _getQrisWidget dengan result: $result');
    if (result == null) {
      print('[DEBUG] Payuniovo: Result null, showing error');
      return Center(child: Text('Terjadi kesalahan tak terduga'));
    }
    
    String status = result['status'];
    print('[DEBUG] Payuniovo: Status: $status');

    switch (status) {
      case 'not_kyc':
        return _notKycPage();
      case 'kyc_completed_no_qris':
        return _kycCompletedNoQrisPage();
      case 'processing_qris':
        return _processingQrisPage(result['message']);
      case 'qris_available':
        String imageUrl = result['image'];
        print('[DEBUG] Payuniovo: QRIS available with image: $imageUrl');
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  progressIndicatorBuilder: (_, __, ___) => SpinKitFadingCircle(
                    color: Theme.of(context).primaryColor,
                  ),
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ],
        );
      case 'submitted_success':
        print('[DEBUG] Payuniovo: QRIS submitted successfully');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 16),
                Text(
                  "Berhasil Submit",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Data Anda berhasil disimpan\n Data anda sedang diproses, silahkan tunggu beberapa hari",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => NavbarHome()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      "Kembali ke Home",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case 'qris_rejected':
        print('[DEBUG] Payuniovo: QRIS rejected');
        final rejectionReason = result['reason'] ?? 'Data tidak lengkap atau tidak sesuai dengan persyaratan yang ditentukan. Silakan perbaiki data Anda dan daftar ulang.';
       //  final rejectionReason =  'Data tidak lengkap atau tidak sesuai dengan persyaratan yang ditentukan. Silakan perbaiki data Anda dan daftar ulang.';
     
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  "QRIS Ditolak",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Pengajuan QRIS Anda ditolak\nSilakan hubungi customer service untuk informasi lebih lanjut",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Alasan Penolakan:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rejectionReason,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => QrisRequestFormPage()),
                      );
                      
                      // If form was submitted successfully, refresh the page
                      if (result == true) {
                        setState(() {
                          _refreshKey++; // This will force FutureBuilder to rebuild
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      "Daftar Ulang",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => NavbarHome()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      "Kembali ke Home",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case 'error':
        print('[DEBUG] Payuniovo: Error detected: ${result['message'] ?? result['error']}');
        return Center(child: Text('Error: ${result['message'] ?? result['error']}'));
      default:
        print('[DEBUG] Payuniovo: Unknown status: $status');
        return Center(
          child: Text('QRIS tidak tersedia saat ini.'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[DEBUG] Payuniovo: Building QRIS page');
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey(_refreshKey),
      future: _checkQrisStatus(),
      builder: (context, snapshot) {
        bool showFab = false;
        if (snapshot.hasData) {
          var result = snapshot.data!;
          if (result['status'] == 'qris_available' &&
              result['image'] != null &&
              result['image'].toString().trim().isNotEmpty) {
            showFab = true;
            print('[DEBUG] Payuniovo: Showing FAB for download');
          }
        }
        
        print('[DEBUG] Payuniovo: Connection state: ${snapshot.connectionState}');
        print('[DEBUG] Payuniovo: Has error: ${snapshot.hasError}');
        print('[DEBUG] Payuniovo: Has data: ${snapshot.hasData}');
        
        return Scaffold(
          floatingActionButton: showFab
              ? FloatingActionButton.extended(
                  onPressed: _takeScreenshot,
                  label: Row(
                    children: [
                      Icon(Icons.download, size: 18),
                      SizedBox(width: 5),
                      Text("Unduh QRIS"),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(50.0)),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                )
              : null,
          body: snapshot.connectionState == ConnectionState.waiting
              ? SpinKitFadingCircle(
                  color: Theme.of(context).primaryColor,
                )
              : snapshot.hasError
                  ? Center(child: Text('Error: ${snapshot.error}'))
                  : snapshot.hasData
                      ? _getQrisWidget(snapshot.data!)
                      : Center(child: Text('QRIS tidak tersedia')),
        );
      },
    );
  }
}
