import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'package:project_x/funcionalidades/cadastro_motoqueiro/dominio/excecao_selector_imagem.dart';
import 'package:project_x/nucleo/configuracao/configuracao_supabase.dart';

abstract interface class SelectorImagem {
  /// Devolve `null` se o utilizador cancelar. Lança [ExcecaoSelectorImagem]
  /// se não houver acesso à câmara/galeria ou câmara disponível.
  Future<String?> tirarFotografia();
  Future<String?> escolherDaGaleria();
  Future<void> abrirDefinicoesApp();
}

class SelectorImagemDispositivo implements SelectorImagem {
  SelectorImagemDispositivo({ImagePicker? seletor})
    : _seletor = seletor ?? ImagePicker();

  // Reduz e recomprime para JPEG, para ficar abaixo do limite de 5 MB do
  // bucket `documentos` sem perder legibilidade do documento.
  static const double _larguraMaxima = 2048;
  static const int _qualidade = 85;

  final ImagePicker _seletor;

  @override
  Future<String?> tirarFotografia() => _escolher(ImageSource.camera);

  @override
  Future<String?> escolherDaGaleria() => _escolher(ImageSource.gallery);

  // O geolocator já é dependência e sabe abrir as definições da app.
  @override
  Future<void> abrirDefinicoesApp() => Geolocator.openAppSettings();

  Future<String?> _escolher(ImageSource origem) async {
    try {
      final XFile? ficheiro = await _seletor.pickImage(
        source: origem,
        maxWidth: _larguraMaxima,
        maxHeight: _larguraMaxima,
        imageQuality: _qualidade,
      );
      return ficheiro?.path;
    } on PlatformException catch (e) {
      throw ExcecaoSelectorImagem(switch (e.code) {
        'camera_access_denied' => MotivoFalhaImagem.semAcessoCamara,
        'photo_access_denied' => MotivoFalhaImagem.semAcessoGaleria,
        'no_available_camera' => MotivoFalhaImagem.semCamara,
        _ => MotivoFalhaImagem.desconhecido,
      });
    }
  }
}

class SelectorImagemSimulado implements SelectorImagem {
  static const Duration _atraso = Duration(milliseconds: 500);

  @override
  Future<String?> tirarFotografia() async {
    await Future<void>.delayed(_atraso);
    return 'camara-${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  @override
  Future<String?> escolherDaGaleria() async {
    await Future<void>.delayed(_atraso);
    return 'galeria-${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  @override
  Future<void> abrirDefinicoesApp() async {}
}

/// Com o Supabase ligado, usa a câmara/galeria a sério (o ficheiro tem de
/// existir para ser enviado ao Storage); sem ele, tudo fica simulado.
final Provider<SelectorImagem> selectorImagemProvider =
    Provider<SelectorImagem>(
      (Ref ref) => ConfiguracaoSupabase.configurado
          ? SelectorImagemDispositivo()
          : SelectorImagemSimulado(),
    );
