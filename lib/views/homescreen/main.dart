import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:solducci/models/expense.dart';


class Homepage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MainhomeScaffold();
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
    HomeScreen(),
    SheetDataScreen(),
    Icon(Icons.topic_rounded,size: 150)
  ];

  void _onItemTapped(int index){
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solducci'),
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
      )
    );
  }
  
}


class SheetDataScreen extends StatelessWidget {
  const SheetDataScreen({Key? key}) : super(key: key);

  Future<List<dynamic>> getData() async {
    final url  = "https://script.google.com/macros/s/AKfycbwiWy-wT4A6UF3bEcNNLKlACqYydZLimCAzQPRjoECy2ooyDmwKKWnMMDLNZXE5ueSt/exec";
    final response = await http.get(Uri.parse(url));
    print(response.body);

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
                  title: Text(data[index].isEmpty ? "no name" : data[index] ),
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
      child: Expense().getExpenseView()
    );
  }
}

class HomeBottomNavigator extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemTapped;
  const HomeBottomNavigator({
    Key? key,
    required this.currentIndex,
    required this.onItemTapped,
  }) : super(key:key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
    items: const <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.find_in_page_sharp),
        label: 'Sheet',
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