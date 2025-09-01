// @dart=2.9

import 'package:flutter/material.dart';
import 'package:mobile/bloc/Bloc.dart';
import 'package:mobile/bloc/ConfigApp.dart';
import 'package:mobile/models/payment-list.dart';
import 'package:mobile/provider/analitycs.dart';
import 'package:mobile/provider/api.dart';
import 'package:mobile/screen/profile/my_qris.dart';
import 'package:mobile/screen/topup/bank/bank.dart';
import 'package:mobile/screen/topup/channel/channel.dart';
import 'package:mobile/screen/topup/merchant/merchant.dart';
import 'package:mobile/screen/topup/qris/qris.dart';
import 'package:mobile/screen/topup/topup.dart';
import 'package:mobile/screen/topup/va/va.dart';

abstract class TopupController extends State<TopupPage> {
  bool loading = true;
  List<PaymentModel> listPayment = [];

  @override
  void initState() {
    super.initState();
    print('🔍 [TOPUP] initState called');
    print('🔍 [TOPUP] User ID: ${bloc.userId.valueWrapper?.value}');
    
    var analyticsData = {
      'userId': bloc.userId.valueWrapper?.value,
      'title': 'Topup Controller',
    };
    print('🔍 [TOPUP] Analytics payload: ${analyticsData.toString()}');
    analitycs.pageView('/topup/controller/', analyticsData);
    print('🔍 [TOPUP] Analytics page view sent');
    
    fetchData();
  }

  fetchData() async {
    print('🔍 [TOPUP] fetchData() called');
    print('🔍 [TOPUP] Loading payment methods from API');
    
    try {
      print('🔍 [TOPUP] Making API call to /deposit/methode');
      List<dynamic> datas = await api.get('/deposit/methode', cache: false);
      print('🔍 [TOPUP] API response received');
      print('🔍 [TOPUP] Raw API response data: ${datas.toString()}');
      print('🔍 [TOPUP] Number of payment methods received: ${datas.length}');
      
      listPayment = datas.map((e) {
        print('🔍 [TOPUP] Processing payment method: ${e.toString()}');
        return PaymentModel.fromJson(e);
      }).toList();
      
      print('🔍 [TOPUP] Payment methods processed: ${listPayment.length}');
      print('🔍 [TOPUP] Payment methods details:');
      listPayment.forEach((payment) {
        print('🔍 [TOPUP] - ID: ${payment.id}, Title: ${payment.title}, Type: ${payment.type}, Channel: ${payment.channel}');
      });

      print('🔍 [TOPUP] Checking QRIS static configuration');
      print('🔍 [TOPUP] QRIS static enabled: ${configAppBloc.qrisStaticOnTopup.valueWrapper?.value ?? false}');
      
      if (configAppBloc.qrisStaticOnTopup.valueWrapper?.value ?? false) {
        print('🔍 [TOPUP] Adding QRIS static payment method');
        PaymentModel qrisStatic = PaymentModel(
          id: '',
          title: 'QRIS',
          description: 'Transfer saldo menggunakan QRIS langsung ke akun ini',
          admin: {
            'nominal': 0,
            'satuan': 'rupiah',
          },
          channel: 'qris_static',
          icon:
              'https://firebasestorage.googleapis.com/v0/b/payuni-2019y.appspot.com/o/assets%2Ficons%2Fdeposit%2Fqris.png?alt=media&token=4cc8167c-22d9-4d3d-93fd-a6c2ddcdd649',
          type: 9,
        );

        listPayment.add(qrisStatic);
        print('🔍 [TOPUP] QRIS static added, total methods: ${listPayment.length}');
      }
    } catch (e) {
      print('🔍 [TOPUP] Error fetching payment methods: $e');
      listPayment = [];
    } finally {
      print('🔍 [TOPUP] Setting loading to false');
      setState(() {
        loading = false;
      });
      print('🔍 [TOPUP] State updated, loading completed');
    }
  }

  onTapMenu(PaymentModel payment) {
    print('🔍 [TOPUP] onTapMenu called');
    print('🔍 [TOPUP] Selected payment method:');
    print('🔍 [TOPUP] - ID: ${payment.id}');
    print('🔍 [TOPUP] - Title: ${payment.title}');
    print('🔍 [TOPUP] - Type: ${payment.type}');
    print('🔍 [TOPUP] - Channel: ${payment.channel}');
    print('🔍 [TOPUP] - Description: ${payment.description}');
    print('🔍 [TOPUP] - Admin: ${payment.admin}');
    
    if (payment.type == 1 || payment.type == 2) {
      print('🔍 [TOPUP] Navigating to TopupBank (Bank/E-wallet transfer)');
      return Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => TopupBank(payment)));
    } else if (payment.type == 5) {
      print('🔍 [TOPUP] Navigating to TopupVA (Virtual Account)');
      return Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => TopupVA()));
    } else if (payment.type == 4 || payment.type == 6) {
      print('🔍 [TOPUP] Navigating to TopupMerchant (Merchant/Agen)');
      return Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => TopupMerchant(payment)));
    } else if (payment.type == 7) {
      print('🔍 [TOPUP] Navigating to TopupChannel (Channel)');
      return Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => TopupChannel(payment)));
    } else if (payment.type == 8) {
      print('🔍 [TOPUP] Navigating to QrisTopup (QRIS)');
      return Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => QrisTopup()));
    } else if (payment.type == 9) {
      print('🔍 [TOPUP] Navigating to QRIS Static page');
      return Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              configAppBloc.layoutApp.valueWrapper?.value['qris-static'] ??
              MyQrisPage(),
        ),
      );
    } else {
      print('🔍 [TOPUP] Unknown payment type: ${payment.type}, no navigation');
    }
  }
}
