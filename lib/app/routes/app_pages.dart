import 'package:get/get.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/register_view.dart';
import '../modules/auth/views/forgot_password_view.dart';
import '../modules/note_editor/bindings/note_editor_binding.dart';
import '../modules/note_editor/views/note_editor_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/book/bindings/book_binding.dart';
import '../modules/book/views/book_view.dart';
import '../modules/book/bindings/book_list_binding.dart';
import '../modules/book/views/book_list_view.dart';
import '../modules/book/bindings/public_library_binding.dart';
import '../modules/book/views/public_library_view.dart';
import '../modules/book/bindings/public_book_reader_binding.dart';
import '../modules/book/views/public_book_reader_view.dart';
import '../modules/book/bindings/book_search_binding.dart';
import '../modules/book/views/book_search_view.dart';
import '../modules/book/bindings/book_comments_binding.dart';
import '../modules/book/views/book_comments_view.dart';
import '../modules/book/bindings/readlist_binding.dart';
import '../modules/book/views/readlist_view.dart';
import '../modules/book/bindings/inbox_binding.dart';
import '../modules/book/views/inbox_view.dart';
import '../modules/book/bindings/category_binding.dart';
import '../modules/trash/bindings/trash_binding.dart';
import '../modules/trash/views/trash_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.AUTH,
      page: () => const AuthView(),
      binding: AuthBinding(),
      children: [
        GetPage(
          name: _Paths.LOGIN,
          page: () => const LoginView(),
        ),
        GetPage(
          name: _Paths.REGISTER,
          page: () => const RegisterView(),
        ),
        GetPage(
          name: _Paths.FORGOT_PASSWORD,
          page: () => const ForgotPasswordView(),
        ),
      ],
    ),
    GetPage(
      name: _Paths.NOTE_EDITOR,
      page: () => const NoteEditorView(),
      binding: NoteEditorBinding(),
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.BOOK,
      page: () => const BookView(),
      binding: BookBinding(),
      bindings: [CategoryBinding()],
    ),
    GetPage(
      name: _Paths.BOOK_LIST,
      page: () => const BookListView(),
      binding: BookListBinding(),
      bindings: [CategoryBinding()],
    ),
    GetPage(
      name: _Paths.PUBLIC_LIBRARY,
      page: () => const PublicLibraryView(),
      binding: PublicLibraryBinding(),
      bindings: [CategoryBinding()],
    ),
    GetPage(
      name: _Paths.PUBLIC_BOOK_READER,
      page: () => const PublicBookReaderView(),
      binding: PublicBookReaderBinding(),
    ),
    GetPage(
      name: _Paths.BOOK_SEARCH,
      page: () => const BookSearchView(),
      binding: BookSearchBinding(),
    ),
    GetPage(
      name: _Paths.BOOK_COMMENTS,
      page: () => const BookCommentsView(),
      binding: BookCommentsBinding(),
    ),
    GetPage(
      name: _Paths.READLIST,
      page: () => const ReadlistView(),
      binding: ReadlistBinding(),
    ),
    GetPage(
      name: _Paths.INBOX,
      page: () => const InboxView(),
      binding: InboxBinding(),
    ),
    GetPage(
      name: _Paths.TRASH,
      page: () => const TrashView(),
      binding: TrashBinding(),
    ),
  ];
}
