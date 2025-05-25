import 'package:get/get.dart';
import '../controllers/readlist_controller.dart';
import '../../../data/repositories/readlist_repository.dart';

class ReadlistBinding extends Bindings {
  @override
  void dependencies() {
    // Lazily register the readlist repository if not already registered
    if (!Get.isRegistered<ReadlistRepository>()) {
      Get.lazyPut<ReadlistRepository>(() => ReadlistRepository());
    }
    
    // Lazily initialize the controller
    Get.lazyPut<ReadlistController>(() => ReadlistController());
  }
} 