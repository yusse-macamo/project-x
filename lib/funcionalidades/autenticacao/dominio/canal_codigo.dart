enum CanalCodigo {
  sms,
  whatsapp;

  String get nome => switch (this) {
    CanalCodigo.sms => 'SMS',
    CanalCodigo.whatsapp => 'WhatsApp',
  };
}
