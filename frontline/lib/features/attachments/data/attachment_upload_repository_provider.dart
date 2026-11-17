import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import 'attachment_upload_repository.dart';
import 'http_attachment_upload_repository.dart';
import 'mock_attachment_upload_repository.dart';

part 'attachment_upload_repository_provider.g.dart';

@Riverpod(keepAlive: true)
AttachmentUploadRepository attachmentUploadRepository(Ref ref) {
  if (AppConfig.useMock) return MockAttachmentUploadRepository();
  return HttpAttachmentUploadRepository(ref.watch(dioClientProvider));
}
