import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/mock_data_store.dart';

final dataStoreProvider = Provider<MockDataStore>((ref) {
  return MockDataStore();
});
