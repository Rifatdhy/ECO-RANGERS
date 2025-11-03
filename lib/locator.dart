import 'package:get_it/get_it.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';

// Membuat instance global dari GetIt
final GetIt locator = GetIt.instance;

// Fungsi untuk mendaftarkan service
void setupLocator() {
  // Daftarkan service sebagai "lazy singleton". 
  // Artinya, instance hanya akan dibuat sekali saat pertama kali dipanggil.
  locator.registerLazySingleton<AuthService>(() => AuthService.instance);
  locator.registerLazySingleton<ApiClient>(() => ApiClient());
}
