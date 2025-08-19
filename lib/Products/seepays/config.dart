// @dart=2.9
//685a32de5fb4c98ea80e8734

import 'layout/main.dart';

String sigVendor = '685a32de5fb4c98ea80e8734';  

const namaApp = 'SEEPAYS BILLER';
const labelSaldo = 'Saldo';
const labelPoint = 'Point';
String packagename = 'com.seepaysbiller.app';
String brandId;
String copyRight = '';  
int templateCode = 2;
String gaId = '';
String apiUrl = 'https://app.payuni.co.id/api/v1';
String liveChat = 'https://tawk.to/chat/685a603cee661a190cce62c8/1iuggfro0';
int pinCount = 4;
int otpCount = 4;
bool autoReload = false;
bool limitPinLogin = false;
bool isKasir = false;
bool isMarketplace = false;
bool realtimePrepaid = false;
bool enableMultiChannel = false;
String apiUrlKasir = 'https://api-pos.payuni.co.id/api/v1';

Map<String, String> assetGambar = {
  'iconTransfer':
      'https://firebasestorage.googleapis.com/v0/b/wajib-online.appspot.com/o/icons%2Fsmartdigital%2Fapp.png?alt=media&token=4713fa12-4f25-4b40-a8e3-59f4523e4321',
  'iconProfile':
      'https://firebasestorage.googleapis.com/v0/b/wajib-online.appspot.com/o/icons%2Fsmartdigital%2Fshield.png?alt=media&token=24fa363a-0e3d-45ac-910c-509597784c5e'
};

Map<String, dynamic> layout = {
  'home': MainApp(),
};
