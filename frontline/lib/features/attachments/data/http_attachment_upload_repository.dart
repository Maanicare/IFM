import 'package:dio/dio.dart';

import 'attachment_upload_repository.dart';

class HttpAttachmentUploadRepository implements AttachmentUploadRepository {
  HttpAttachmentUploadRepository(this._dio);

  final Dio _dio;

  @override
  Future<String> upload({
    required String localPath,
    required String entityType,
    required String entityId,
    required String fileType,
  }) async {
    final form = FormData.fromMap({
      'entity_type': entityType,
      'entity_id': entityId,
      'file_type': fileType,
      'file': await MultipartFile.fromFile(localPath),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/attachments',
      data: form,
    );
    final url = response.data?['url'] as String?;
    if (url == null) {
      throw StateError('Upload succeeded but server did not return a URL.');
    }
    return url;
  }
}
