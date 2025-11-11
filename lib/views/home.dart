import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:solducci/models/expense_form.dart';
import 'package:solducci/views/expense_list.dart';
import 'package:solducci/views/new_homepage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainhomeScaffold();
  }
}

class MainhomeScaffold extends StatefulWidget {
  const MainhomeScaffold({super.key});

  @override
  State<MainhomeScaffold> createState() => _MainhomeScaffoldState();
}

class _MainhomeScaffoldState extends State<MainhomeScaffold> {
  int _selectedIndex = 0;
  static const List<Widget> _pages = <Widget>[
    NewHomepage(),
    ExpenseList(),
    SheetDataScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solducci'),
        leading: StreamBuilder(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(width: 10);
            }

            final session = snapshot.hasData ? snapshot.data!.session : null;

            if (session != null) {
              return IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("You are logged in!")));
                },
                icon: Icon(Icons.person),
              );
            } else {
              return IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/loginpage");
                },
                icon: Icon(Icons.login),
              );
            }
          },
        ),
      ),
      bottomNavigationBar: HomeBottomNavigator(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: _pages.elementAt(_selectedIndex),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt_outlined),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ciao Carlucci'),
              backgroundColor: Color.fromRGBO(216, 60, 110, 0.67),
              behavior: SnackBarBehavior.floating,
              width: 180,
              duration: Duration(milliseconds: 1300),
            ),
          );
        },
      ),
    );
  }
}

class SheetDataScreen extends StatelessWidget {
  const SheetDataScreen({super.key});

  Future<List<dynamic>> getData() async {
    final url =
        "https://script.google.com/macros/s/AKfycbwiWy-wT4A6UF3bEcNNLKlACqYydZLimCAzQPRjoECy2ooyDmwKKWnMMDLNZXE5ueSt/exec";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.cast<String>();
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: getData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No data available'));
        } else {
          final data = snapshot.data!;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(data[index].isEmpty ? "no name" : data[index]),
              );
            },
          );
        }
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int price = 0;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ExpenseForm.empty().getExpenseView(context),
    );
  }
}

class HomeBottomNavigator extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemTapped;
  const HomeBottomNavigator({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.find_in_page_sharp),
          label: 'Expense List',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.hourglass_empty),
          label: 'TODO',
        ),
      ],
      currentIndex: currentIndex,
      onTap: onItemTapped,
    );
  }
}
