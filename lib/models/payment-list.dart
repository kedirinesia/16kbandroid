// @dart=2.9

class PaymentModel {
  String id;
  int type;
  String title;
  String cover;
  String icon;
  String description;
  String channel;
  Map<String, dynamic> admin;
  Map<String, dynamic> admin_trx;

  PaymentModel(
      {this.title,
      this.cover,
      this.id,
      this.type,
      this.icon,
      this.description,
      this.channel,
      this.admin}) {
    print('🔍 [PAYMENT MODEL] PaymentModel constructor called');
    print('🔍 [PAYMENT MODEL] Title: $title, Type: $type, Channel: $channel');
    print('🔍 [PAYMENT MODEL] ID: $id, Icon: $icon');
    print('🔍 [PAYMENT MODEL] Description: $description');
    print('🔍 [PAYMENT MODEL] Admin: $admin');
  }

  PaymentModel.fromJson(Map<String, dynamic> json) {
    print('🔍 [PAYMENT MODEL] fromJson called with FULL JSON PAYLOAD:');
    print('🔍 [PAYMENT MODEL] ${json.toString()}');
    
    title = json['title'];
    id = json['_id'];
    cover = json['cover'] ?? '';
    icon = json['icon'] ?? '';
    description = json['description'] ?? ' ';
    channel = json['channel'] ?? '';
    type = json['type'] ?? 0;
    admin = json['admin'];
    admin_trx = json['admin_trx'] ?? null;
    
    print('🔍 [PAYMENT MODEL] Parsed values:');
    print('🔍 [PAYMENT MODEL] - Title: $title');
    print('🔍 [PAYMENT MODEL] - ID: $id');
    print('🔍 [PAYMENT MODEL] - Type: $type');
    print('🔍 [PAYMENT MODEL] - Channel: $channel');
    print('🔍 [PAYMENT MODEL] - Icon: $icon');
    print('🔍 [PAYMENT MODEL] - Description: $description');
    print('🔍 [PAYMENT MODEL] - Admin: $admin');
    print('🔍 [PAYMENT MODEL] - Admin TRX: $admin_trx');
  }
}
