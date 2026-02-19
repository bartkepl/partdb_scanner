import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'pages/scanner_page.dart';
import 'pages/config_page.dart';
import 'pages/search_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return Provider<ApiService>(
      create: (_) => apiService,
      child: MaterialApp(
        title: 'Part-DB Scanner',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
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
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: HomePage(apiService: apiService),
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

  @override
  void initState() {
    super.initState();
    _tabs.add(ScannerPage(apiService: widget.apiService));
    _tabs.add(SearchPage(apiService: widget.apiService));
    _tabs.add(ConfigPage(apiService: widget.apiService));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: 'Skaner'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), label: 'Wyszukaj'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Konfiguracja'),
        ],
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

