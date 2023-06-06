import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

void main() {
  runApp(GradingApp());
}

// ----------------------------------- basics -------------------------------------------

class GradingApp extends StatefulWidget {
  @override
  _GradingAppState createState() => _GradingAppState();
}

class _GradingAppState extends State<GradingApp> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    StudentListPage(),
    LeaderboardPage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/details': (context) => StudentDetailsPage(),
        '/leaderboard': (context) => LeaderboardPage(),
        '/students': (context) => StudentListPage(),
        '/grade': (context) => GradePage(),
        '/snack': (context) => FavoriteSnackPage(),
        '/impression': (context) => ImpressionPage(),
      },
      debugShowCheckedModeBanner: false,
      title: 'Grading App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        accentColor: Colors.deepOrange, 
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Students',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard),
              label: 'Leaderboard',
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------- StudentList Page -------------------------------------------

class StudentListPage extends StatefulWidget {
  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  List<Student> students = [];
  List<Student> filteredStudents = [];

  @override
  void initState() {
    super.initState();
    getStudents();
  }

  void filterStudents(String query) {
    setState(() {
      filteredStudents = students
          .where((student) =>
              student.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> getStudents() async {
    var settings = new ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: '',
      password: '',
      db: '',
    );

    var conn = await MySqlConnection.connect(settings);

    var results = await conn.query("SELECT * FROM students");

    students = results
        .map((row) => Student(
              row['name'].toString(),
              row['grade'].toString(),
              row['favsnack'].toString(),
              row['impression']?.toString(),
            ))
        .toList();

    setState(() {
      filteredStudents.addAll(students);
    });

    await conn.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Students',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              onChanged: filterStudents,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2.0,
                  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    leading: Icon(Icons.person),
                    title: Text(
                      filteredStudents[index].name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/details',
                          arguments: filteredStudents[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------- StudentDetails Page -------------------------------------------

class StudentDetailsPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  Future<void> sendEmail(String recipientEmail) async {
    final smtpServer = SmtpServer(
      '',
      port: 587,
      username: '',
      password: '',
    );

    final message = Message()
      ..from = Address('', '')
      ..recipients.add(recipientEmail)
      ..subject = 'Subject of the email'
      ..text = 'Hello,\n\nThis is the body of the email.';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error occurred while sending email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Student? student =
        ModalRoute.of(context)?.settings.arguments as Student?;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              student?.name ?? 'Unknown Student',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text(
              'Send Email',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            onTap: () {
              if (student != null) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Send Email'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: 'Recipient Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        FancyButton(
                          onPressed: () {
                            String recipientEmail = emailController.text;
                            sendEmail(recipientEmail);
                            Navigator.of(context).pop();
                          },
                          label: 'Send',
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.rate_review),
            title: Text(
              'Grading Final Project',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            onTap: () {
              if (student != null) {
                Navigator.pushNamed(context, '/grade', arguments: student);
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.fastfood),
            title: Text(
              'Favorite Snack',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            onTap: () {
              if (student != null) {
                Navigator.pushNamed(context, '/snack', arguments: student);
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.sentiment_satisfied),
            title: Text(
              'Impression',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            onTap: () {
              if (student != null) {
                Navigator.pushNamed(context, '/impression', arguments: student);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ----------------------------------- Grade Page -------------------------------------------

class GradePage extends StatefulWidget {
  @override
  State<GradePage> createState() => _GradePageState();
}

class _GradePageState extends State<GradePage> {
  final TextEditingController gradeController = TextEditingController();

  void updateGrade(Student student, String newGrade) async {
    try {
      var settings = new ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: '',
        password: '',
        db: '',
      );

      var conn = await MySqlConnection.connect(settings);

      await conn.query(
        'UPDATE students SET grade = ? WHERE name = ?',
        [newGrade, student.name],
      );

      await conn.close();

      setState(() {
        student.grade = newGrade;
      });
    } catch (e) {
      print('Error occurred while updating grade: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Student student =
        ModalRoute.of(context)?.settings.arguments as Student;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Grade Page',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student: ${student?.name ?? "Unknown Student"}',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Current Grade: ${student?.grade ?? "N/A"}',
              style: TextStyle(
                fontSize: 18.0,
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: gradeController,
              decoration: InputDecoration(
                labelText: 'New Grade',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                if (student != null) {
                  String newGrade = gradeController.text;
                  updateGrade(student, newGrade);
                }
              },
              child: Text('Update Grade'),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------- Leaderboard Page -------------------------------------------

class LeaderboardPage extends StatefulWidget {
  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<LeaderboardEntry> leaderboardData = [];

  @override
  void initState() {
    super.initState();
    fetchLeaderboardData();
  }

  Future<void> fetchLeaderboardData() async {
    try {
      var settings = new ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: '',
        password: '',
        db: '',
      );

      var conn = await MySqlConnection.connect(settings);

      var results = await conn.query(
        'SELECT name, grade FROM students ORDER BY grade DESC',
      );

      leaderboardData = results
          .map(
            (row) => LeaderboardEntry(
              row['name'].toString(),
              row['grade'].toString(),
            ),
          )
          .toList();

      await conn.close();

      setState(() {
        leaderboardData = leaderboardData;
      });
    } catch (e) {
      print('Error occurred while fetching leaderboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Leaderboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Text(
                  'Grade',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.0),
          Divider(height: 1.0, color: Colors.black),
          SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: leaderboardData.length,
              itemBuilder: (context, index) {
                final entry = leaderboardData[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                      Text(
                        entry.grade,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------- FavoriteSnack Page -------------------------------------------

class FavoriteSnackPage extends StatefulWidget {
  @override
  _FavoriteSnackPageState createState() => _FavoriteSnackPageState();
}

class _FavoriteSnackPageState extends State<FavoriteSnackPage> {
  TextEditingController _textFieldController = TextEditingController();
  String _favoriteSnack = '';

  @override
  void initState() {
    super.initState();
    _textFieldController = TextEditingController();
  }

  final TextEditingController snackController = TextEditingController();

  void updateSnack(Student student, String newSnack) async {
    try {
      var settings = new ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: '',
        password: '',
        db: '',
      );

      var conn = await MySqlConnection.connect(settings);

      await conn.query(
        'UPDATE students SET favsnack = ? WHERE name = ?',
        [newSnack, student.name],
      );

      await conn.close();

      setState(() {
        student.favsnack = newSnack;
      });
    } catch (e) {
      print('Error occurred while updating grade: $e');
    }
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Student student =
        ModalRoute.of(context)?.settings.arguments as Student;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FavSnack Page',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student: ${student?.name ?? "Unknown Student"}',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Current Snack: ${student?.favsnack ?? "N/A"}',
              style: TextStyle(
                fontSize: 18.0,
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: snackController,
              decoration: InputDecoration(
                labelText: 'New Snack',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                if (student != null) {
                  String newGrade = snackController.text;
                  updateSnack(student, newGrade);
                }
              },
              child: Text('Update Snack'),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------- Impression Page -------------------------------------------

class ImpressionPage extends StatefulWidget {
  @override
  _ImpressionPageState createState() => _ImpressionPageState();
}

class _ImpressionPageState extends State<ImpressionPage> {
  String _selectedImpression = '';
  TextEditingController _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textFieldController = TextEditingController();
  }

  final TextEditingController ImpressionController = TextEditingController();

  void updateImpression(Student student, String newImpression) async {
    try {
      var settings = new ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: '',
        password: '',
        db: '',
      );

      var conn = await MySqlConnection.connect(settings);

      await conn.query(
        'UPDATE students SET Impression = ? WHERE name = ?',
        [newImpression, student.name],
      );

      await conn.close();

      setState(() {
        student.impression = newImpression;
      });
    } catch (e) {
      print('Error occurred while updating grade: $e');
    }
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Student student =
        ModalRoute.of(context)?.settings.arguments as Student;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose Impression',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student: ${student?.name ?? "Unknown Student"}',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Current Impression: ${student?.impression ?? "N/A"}',
              style: TextStyle(
                fontSize: 18.0,
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImpression = 'Very Good';
                    });
                  },
                  child: Icon(
                    Icons.sentiment_very_satisfied,
                    color: _selectedImpression == 'Very Good'
                        ? Colors.green
                        : Colors.grey,
                    size: 48.0,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImpression = 'Good';
                    });
                  },
                  child: Icon(
                    Icons.sentiment_satisfied,
                    color: _selectedImpression == 'Good'
                        ? Colors.green[900]
                        : Colors.grey,
                    size: 48.0,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImpression = 'Normal';
                    });
                  },
                  child: Icon(
                    Icons.sentiment_neutral,
                    color: _selectedImpression == 'Normal'
                        ? Colors.yellow
                        : Colors.grey,
                    size: 48.0,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImpression = 'Bad';
                    });
                  },
                  child: Icon(
                    Icons.sentiment_very_dissatisfied,
                    color:
                        _selectedImpression == 'Bad' ? Colors.red : Colors.grey,
                    size: 48.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                saveImpression(_selectedImpression);
                updateImpression(student, _selectedImpression);
              },
              child: Text('Save Impression'),
            ),
          ],
        ),
      ),
    );
  }

  void saveImpression(String impression) {
    print('Selected Impression: $impression');
  }
}

// ----------------------------------- Classes -------------------------------------------

class LeaderboardEntry {
  final String name;
  final String grade;

  LeaderboardEntry(this.name, this.grade);
}

class Student {
  final String name;
  String grade;
  String favsnack;
  String? impression;

  Student(this.name, this.grade, this.favsnack, this.impression);
}

class FancyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const FancyButton({
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);

    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(
          onPressed != null
              ? appTheme.primaryColor
              : Colors.teal,
        ),
        foregroundColor:
            MaterialStateProperty.all(appTheme.colorScheme.onPrimary),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }
}
