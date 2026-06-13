import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'pages/category_browser_page.dart';
import 'pages/config_page.dart';
import 'pages/ipn_generator_page.dart';
import 'pages/review_page.dart';
import 'pages/search_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  await apiService.loadConfig();
  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;
  const MyApp({required this.apiService, super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ApiService>.value(
      value: apiService,
      child: Consumer<ApiService>(
        builder: (_, api, __) => MaterialApp(
          title: 'Part-DB Scanner',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          locale: Locale(api.locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.orange,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 1,
            ),
          ),
          home: HomePage(apiService: apiService),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final ApiService apiService;
  const HomePage({required this.apiService, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final List<Widget> _tabs = [];
  int _lowStockCount = 0;

  @override
  void initState() {
    super.initState();
    _tabs.add(SearchPage(apiService: widget.apiService));
    _tabs.add(IpnGeneratorPage(apiService: widget.apiService));
    _tabs.add(CategoryBrowserPage(apiService: widget.apiService));
    _tabs.add(ReviewPage(apiService: widget.apiService));
    _tabs.add(ConfigPage(apiService: widget.apiService));
    _checkLowStock();
  }

  Future<void> _checkLowStock() async {
    if (widget.apiService.baseUrl.isEmpty || widget.apiService.token.isEmpty) return;
    try {
      final parts = await widget.apiService.fetchAllParts();
      final count = parts.where((p) => p.isLowStock).length;
      if (count > 0 && mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _lowStockCount = count);
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            leading: const Icon(Icons.warning_amber, color: Colors.orange),
            content: Text(l10n.lowStockBanner(count)),
            actions: [
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                  setState(() => _index = 0);
                },
                child: Text(l10n.show),
              ),
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                child: Text(l10n.dismiss),
              ),
            ],
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white70,
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _lowStockCount > 0,
              label: Text('$_lowStockCount'),
              backgroundColor: Colors.red,
              child: const Icon(Icons.search),
            ),
            label: l10n.navSearch,
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.label), label: l10n.navIpnGenerator),
          BottomNavigationBarItem(icon: const Icon(Icons.folder), label: l10n.navCategories),
          BottomNavigationBarItem(icon: const Icon(Icons.fact_check_outlined), label: l10n.navReview),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: l10n.navConfig),
        ],
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
