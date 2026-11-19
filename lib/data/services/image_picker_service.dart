import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/result.dart';

/// Contrato para captura de fotos dos check-ins.
abstract class PhotoService {
  /// Retorna o caminho local da foto ou `null` se o usuário cancelar.
  Future<Result<String?>> pick({required bool fromCamera});
}

class ImagePickerPhotoService implements PhotoService {
  ImagePickerPhotoService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Result<String?>> pick({required bool fromCamera}) async {
    try {
      final file = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1440,
        imageQuality: 82,
      );
      return Result.ok(file?.path);
    } on PlatformException catch (e) {
      return Result.error(
        AppException(e.message ?? 'Não foi possível acessar a câmera'),
      );
    }
  }
}
