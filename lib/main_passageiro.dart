import 'package:flutter/material.dart';

import 'package:project_x/arranque.dart';
import 'package:project_x/nucleo/tipo_aplicacao.dart';

Future<void> main() async {
  runApp(await arrancarApp(TipoAplicacao.passageiro));
}
