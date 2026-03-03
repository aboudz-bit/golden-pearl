import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'providers/language_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'services/api_service.dart';
import 'screens/home_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/order_confirmation_screen.dart';
import 'screens/category_screen.dart';
import 'screens/notifications_screen.dart';
import 'utils/arabic_digits.dart';

const kGoldPrimary = Color(0xFFB89B5E);
const kGoldDark = Color(0xFF9C7F42);
const kCreamBg = Color(0xFFF4F4F4);
const kCardBg = Color(0xFFFFFFFF);
const kCharcoal = Color(0xFF1C1C1C);
const kSecondaryText = Color(0xFF6B6B6B);
const kDivider = Color(0xFFEAEAEA);

const _playfairFamily = 'PlayfairDisplay';

TextStyle playfairDisplay({double fontSize = 16, FontWeight fontWeight = FontWeight.w400, Color? color}) {
  return TextStyle(fontFamily: _playfairFamily, fontSize: fontSize, fontWeight: fontWeight, color: color);
}

final apiService = ApiService();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider(apiService)),
        ChangeNotifierProvider(create: (_) => FavoritesProvider(apiService)),
      ],
      child: const GoldenPearlApp(),
    ),
  );
}

class GoldenPearlApp extends StatelessWidget {
  const GoldenPearlApp({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      title: 'Golden Pearl',
      debugShowCheckedModeBanner: false,
      locale: langProvider.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kGoldPrimary,
          brightness: Brightness.light,
          primary: kGoldPrimary,
          secondary: kGoldDark,
          surface: kCardBg,
          onSurface: kCharcoal,
        ),
        scaffoldBackgroundColor: kCreamBg,
        appBarTheme: AppBarTheme(
          backgroundColor: kCreamBg,
          foregroundColor: kCharcoal,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: kCharcoal,
          ),
        ),
        textTheme: TextTheme(
          displayLarge: playfairDisplay(fontSize: 32, fontWeight: FontWeight.w700, color: kCharcoal),
          displayMedium: playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: kCharcoal),
          displaySmall: playfairDisplay(fontSize: 24, fontWeight: FontWeight.w600, color: kCharcoal),
          headlineMedium: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: kCharcoal),
          titleLarge: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: kCharcoal),
          titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kCharcoal),
          bodyLarge: const TextStyle(fontSize: 16, color: kSecondaryText),
          bodyMedium: const TextStyle(fontSize: 14, color: kSecondaryText),
          bodySmall: const TextStyle(fontSize: 12, color: kSecondaryText),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kGoldPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.0),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kCharcoal,
            side: const BorderSide(color: kDivider, width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.06),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: kCardBg,
        ),
        dividerColor: kDivider,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: kCardBg,
          selectedItemColor: kGoldPrimary,
          unselectedItemColor: kSecondaryText,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
      onGenerateRoute: (settings) {
        Widget? page;
        if (settings.name?.startsWith('/product/') ?? false) {
          final idStr = settings.name!.replaceFirst('/product/', '');
          final id = int.tryParse(idStr);
          if (id != null) page = ProductDetailScreen(productId: id);
        } else if (settings.name?.startsWith('/category/') ?? false) {
          final slug = settings.name!.replaceFirst('/category/', '');
          if (slug.isNotEmpty) page = CategoryScreen(slug: slug);
        } else if (settings.name == '/notifications') {
          page = const NotificationsScreen();
        } else if (settings.name == '/checkout') {
          page = const CheckoutScreen();
        } else if (settings.name == '/orders') {
          page = const OrdersScreen();
        } else if (settings.name == '/order-confirmation') {
          page = OrderConfirmationScreen(order: settings.arguments);
        }
        if (page != null) {
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => page!,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 280),
          );
        }
        return null;
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _unreadNotifications = 0;

  final _screens = const [
    HomeScreen(),
    ShopScreen(),
    CartScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).loadCart();
      Provider.of<FavoritesProvider>(context, listen: false).load();
      _loadUnreadCount();
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await apiService.getUnreadNotificationCount();
      if (mounted) setState(() => _unreadNotifications = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cartProvider = Provider.of<CartProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final lang = langProvider.languageCode;
    final cartBadge = ArabicDigits.convert(cartProvider.itemCount, lang);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: l10n.home),
          BottomNavigationBarItem(icon: const Icon(Icons.shopping_bag_outlined), activeIcon: const Icon(Icons.shopping_bag), label: l10n.shop),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: cartProvider.itemCount > 0,
              label: Text(cartBadge, style: const TextStyle(fontSize: 10)),
              backgroundColor: kGoldPrimary,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: cartProvider.itemCount > 0,
              label: Text(cartBadge, style: const TextStyle(fontSize: 10)),
              backgroundColor: kGoldPrimary,
              child: const Icon(Icons.shopping_cart),
            ),
            label: l10n.cart,
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.settings_outlined), activeIcon: const Icon(Icons.settings), label: l10n.settings),
        ],
      ),
    );
  }
}
