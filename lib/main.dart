import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/home_page.dart';
import 'pages/auth_page.dart';

const supabaseUrl = 'https://peaairfpitjqgkqalmje.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBlYWFpcmZwaXRqcWdrcWFsbWplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyMDQyMTgsImV4cCI6MjA2ODc4MDIxOH0.G_ANNYuLngoP31v9IRGCFz9baRseDwsOOBDUI5VE2sg';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authFlowType: AuthFlowType.pkce,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? user;
  @override
  void initState() {
    super.initState();
    user = Supabase.instance.client.auth.currentUser;
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() {
        user = data.session?.user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter ToDo Supabase',
      theme: ThemeData(useMaterial3: true),
      home: user == null
          ? AuthPage(onSignedIn: () {
              setState(() {});
            })
          : const HomePage(),
    );
  }
}
