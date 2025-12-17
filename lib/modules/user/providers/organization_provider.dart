import 'package:booksmart/models/organization_model.dart';
import 'package:booksmart/modules/common/providers/auth_provider.dart';

import '../../../services/crud_service.dart';
import '../../../supabase/tables.dart';

Future<List<OrganizationModel>> getOrganizations({String? userId}) async {
  final String? id = userId ?? getCurrentLoggedUserId;
  if (id == null) {
    return [];
  }

  return SupabaseCrudService.read(
    table: SupabaseTable.organization,
    filters: {'owner_id': id},
  ).then((res) {
    return (res as List).map((e) => OrganizationModel.fromJson(e)).toList();
  });
}
