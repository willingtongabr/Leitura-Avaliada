import 'package:flutter/material.dart';
import 'package:leitura_avaliada/screens/EditReviewScreen.dart';
import 'screens/splash_screen.dart';
import 'screens/ReviewsListScreen.dart';
import 'screens/login_screen.dart';
import 'screens/CreateReviewScreen.dart'; 
import 'screens/SearchResultsScreen.dart';
import 'screens/MyReviews.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/src/messages/pt_br_messages.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  User? user = FirebaseAuth.instance.currentUser;

  timeago.setLocaleMessages('pt_BR', PtBrMessages());

  runApp(MyApp(initialUser: user));
}

class MyApp extends StatelessWidget {
  final User? initialUser;
  const MyApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'Leitura Avaliada',
  theme: ThemeData(primarySwatch: Colors.deepPurple),
  initialRoute: initialUser != null ? '/reviewsList' : '/login',
  routes: {
    '/login': (context) => LoginScreen(),
    '/myreviewsList': (context) => MyReviewsScreen(),
    '/reviewsList': (context) => ReviewsListScreen(),
    '/createReview': (context) => CreateReviewScreen(),
    '/searchResults': (context) => SearchResultsScreen(),
    '/splash': (context) => SplashScreen(),
  },
  onGenerateRoute: (settings) {
    if (settings.name == '/editReview') {
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => EditReviewScreen(
          docId: args['docId'],
          currentReview: args['currentReview'],
        ),
      );
    }

    return null; // unknown route fallback
  },
);
  }
}
