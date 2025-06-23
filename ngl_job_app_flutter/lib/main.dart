import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:app_links/app_links.dart';
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NGL Job Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: const JobTrackerScreen(),
    );
  }
}

class JobTrackerScreen extends StatefulWidget {
  const JobTrackerScreen({super.key});

  @override
  State<JobTrackerScreen> createState() => _JobTrackerScreenState();
}

class _JobTrackerScreenState extends State<JobTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _linkController = TextEditingController();
  String _selectedJobType = 'newgrad';
  bool _isLoading = false;
  static const platform = MethodChannel('com.example.ngljobtracker/shared_content');
  
  // URL scheme handling
  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;
  
  // Google Service Account credentials
  static const _serviceAccountCredentials = {
    "type": "service_account",
    "project_id": "ngl-job-board",
    "private_key_id": "7ac1189b1e1ac796e7255a9f4b7d87ddd4b5de35",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCXmW7fqWLDNpWK\ntWQcbGIQmx+akrqsyGVQSaDzynG8WvIVoL4zTLxLwRbZilLmgsCeWqq2OlHjBdWS\n4oWeLlg4uoWkFtoV4Gef5424Mr3Dl/xzdVSM3W/b7cM0lBM69XIh7T5rKIqEqmJ5\nUxA+zJelrc5ioY7O14Zk0MVNtBxyw0XX1fiuQS7aU6Lvvo1saa92awta7q45/4OH\n6O3sXIDWefyslU8jd/nKkBjkuTEBwTPk3zs2JOWGaUKxA+MrTLk9v+thcET9mBm9\n2dMeBNU10dck43kOeBm39iIdx+RV+DcONhxFKsa7sD4kZJhg9rslQ7Vpyyst5hP9\n75xOHMjTAgMBAAECggEACYARBa0sxkUGbBHf+zQDlTzTZzFox2kriDOFBaIbLI2a\nfCZ9pONbLXglQW68sTtibMoLxq2y8gIsly7g5r/KwYtW0qin9BUDCW9OX0u2vqoo\npOema8l4uBSXVhUte1VkWKHwdnCs9ZFj6Gx/KSBTJIvW0jGDrIyvHGRE6RCvc7WW\nTqGRIeBcrHCRTo4R9bvOsM6OX/ATQAaoq5k/TmAMtCwe9wgJW/7KVBcD1bAcSoBS\nKF1Wl+Bp6TFyNelLnTz4tTvHiyK8GGtHafGeFcKndqr17+T5PHNQpP/69xLMIpCV\nhO47i9jRFqqqS1mxpE4k3Oh6vtioV/fcRJqyneJfgQKBgQDRryrz8HzL73/0XqIn\nyHTS4mx9aokx1y97Ls0S6yHVuRr5oRr9+kZPfSeMRNcHMrxY3XDeleNsY+yGut7M\n20N4Zqjg7dlCeGbweFQV2oc/sr98dhxt+DVNJiiwpfi2JaY+5hTI0S0qQhB6EM/X\n8CkxDvF/S9jGJTdGpCx4mmsdQQKBgQC5FcoDN7iiMn6NJh/q+2xzklu6+YgBpZOW\nwxRRtajuC83knfWWKT87y0yBHI1Ud+b1CpRDPkS6S/p/Ck8hACbNYy7tmMj8duUA\nTh9TNlrJ2e/YunB0hvx7ZJKKhblp0Yeh6y8ySYUAbSxEG0+gFw6qnx6vFZG0eA73\ndWCz10ldEwKBgEbKque8s4VukHaCVKC1zqs8AoC9LSCEk+U0wcu3Uq8DVZYdzC0f\nCAniKS30N9yYRnqCGI8tb6Cyg7Jg+MOU60yE7FM0Oft1Btv84/aU1sCsqnVssuB1\nwhkP3wD0p+lnAJ+PskiyRltT/pgXgPRYgq+raeEeTEtpWSYiW1lEWRGBAoGAYhz3\n0o7WND0aMs6z+se/LOC3+bzPaTgRrcjJ26q120KsqXVGu4wv9g2GB6dQECfjaaBr\nCd5XZn5iUrfvTGodJ6FdPhxQ5uxL5saC+oSEyh3adAQZGtx3uR2ORRowOLUW9jGK\n+lhYxeoZnhzwL8gpQS9Kf7uqWoWOQYWadps4S7sCgYEAm3Z+pw7NN3wEKrGaeJeC\nmffxpApeoVnguOpFsdhaaOC0zBJA0QKgZV4QFOCEBBny3byYcs5Ac5gsMkkDvKEK\nw7Vok6oNOvAE31dSBWlwY/s5qoD1bBAcP2ivOSby03xyXMKfQ8lTmbYe2kD7A1zG\n6pydAedZRVaRWoPMtTDZ7lU=\n-----END PRIVATE KEY-----\n",
    "client_email": "ngl-job-tracker@ngl-job-board.iam.gserviceaccount.com",
    "client_id": "115806696593985962024",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/ngl-job-tracker%40ngl-job-board.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
  };

  @override
  void initState() {
    super.initState();
    _listenForSharedContent();
    _initUniLinks();
  }

  void _listenForSharedContent() {
    // Listen for shared content from platform channel (Android)
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onSharedContent') {
        final String sharedContent = call.arguments as String;
        _handleSharedContent(sharedContent);
      }
    });

    // Check for initial shared content when app starts
    _checkInitialSharedContent();
  }

  // Handle URL schemes for iOS Share Extension
  Future<void> _initUniLinks() async {
    // Check for initial link when app starts
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        _handleUrlScheme(initialLink.toString());
      }
    } catch (e) {
      print('Error getting initial link: $e');
    }

    // Listen for incoming links when app is running
    _linkSubscription = _appLinks.allStringLinkStream.listen((String? link) {
      if (link != null) {
        _handleUrlScheme(link);
      }
    }, onError: (err) {
      print('Error listening to app link stream: $err');
    });
  }

  void _handleUrlScheme(String url) {
    if (url.startsWith('ngljobtracker://')) {
      // Extract the shared URL from the custom scheme
      final uri = Uri.parse(url);
      final sharedUrl = uri.queryParameters['url'];
      if (sharedUrl != null) {
        _handleSharedContent(sharedUrl);
      }
    }
  }

  Future<void> _checkInitialSharedContent() async {
    try {
      final String? initialContent = await platform.invokeMethod('getInitialSharedContent');
      if (initialContent != null && initialContent.isNotEmpty) {
        _handleSharedContent(initialContent);
      }
    } on PlatformException catch (e) {
      print('Failed to get initial shared content: ${e.message}');
    }
  }

  void _handleSharedContent(String content) {
    setState(() {
      _linkController.text = content;
    });
  }

  @override
  void dispose() {
    _companyController.dispose();
    _linkController.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current date
      final now = DateTime.now();
      final date = '${now.month}/${now.day}/${now.year}';

      // Get random referrer and recruiter
      final referrer = await _getRandomReferrer(_companyController.text);
      final recruiter = await _getRandomRecruiter(_companyController.text);

      // Submit to Google Sheets
      await _insertJobToSheet(
        _companyController.text,
        _linkController.text,
        referrer,
        recruiter,
        date,
        _selectedJobType,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _companyController.clear();
        _linkController.clear();
        setState(() {
          _selectedJobType = 'newgrad';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _getRandomReferrer(String company) async {
    const databaseURL = 'https://ngl-job-board-d5bd8-default-rtdb.firebaseio.com';
    final url = '$databaseURL/companies/${Uri.encodeComponent(company)}/referrers.json';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch referrers');
      }
      
      final data = jsonDecode(response.body);
      if (data == null) return '';

      final values = data.values.toList();
      if (values.isEmpty) return '';
      
      final randomRef = values[DateTime.now().millisecondsSinceEpoch % values.length];
      return '${randomRef['name']} : ${randomRef['contact'] ?? 'No contact'}';
    } catch (err) {
      print('Error fetching random referrer: $err');
      return 'Referrer: John Doe (john@example.com)';
    }
  }

  Future<String> _getRandomRecruiter(String company) async {
    const databaseURL = 'https://ngl-job-board-d5bd8-default-rtdb.firebaseio.com';
    final url = '$databaseURL/companies/${Uri.encodeComponent(company)}/recruiters.json';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch recruiters');
      }
      
      final data = jsonDecode(response.body);
      if (data == null) return '';

      final values = data.values.toList();
      if (values.isEmpty) return '';
      
      final randomRec = values[DateTime.now().millisecondsSinceEpoch % values.length];
      return '${randomRec['name']} : ${randomRec['contact'] ?? 'No contact'}';
    } catch (err) {
      print('Error fetching random recruiter: $err');
      return 'Recruiter: Jane Smith (jane@example.com)';
    }
  }

  Future<void> _insertJobToSheet(
    String company,
    String link,
    String referrer,
    String recruiter,
    String date,
    String jobType,
  ) async {
    // Google Sheets configuration
    const spreadsheetId = '1wm5K1d9ScRhvLNYbSXhQuJjFnGr0jPrL0eJfn2bMYKM';
    
    // Determine sheet ID based on job type
    // sheetId 0 = first tab (New Grad), sheetId 2033324761 = second tab (Intern)
    final sheetId = jobType == 'intern' ? 2033324761 : 0;

    try {
      // Create service account credentials
      final credentials = ServiceAccountCredentials.fromJson(_serviceAccountCredentials);
      
      // Create authenticated HTTP client
      final client = await clientViaServiceAccount(credentials, [
        'https://www.googleapis.com/auth/spreadsheets',
      ]);

      // Create Google Sheets API client
      final sheetsApi = sheets.SheetsApi(client);

      // Prepare the request
      final request = sheets.BatchUpdateSpreadsheetRequest(
        requests: [
          sheets.Request(
            insertDimension: sheets.InsertDimensionRequest(
              range: sheets.DimensionRange(
                sheetId: sheetId,
                dimension: 'ROWS',
                startIndex: 1,
                endIndex: 2,
              ),
              inheritFromBefore: false,
            ),
          ),
          sheets.Request(
            updateCells: sheets.UpdateCellsRequest(
              start: sheets.GridCoordinate(
                sheetId: sheetId,
                rowIndex: 1,
                columnIndex: 0,
              ),
              rows: [
                sheets.RowData(
                  values: [
                    sheets.CellData(userEnteredValue: sheets.ExtendedValue(stringValue: company)),
                    sheets.CellData(userEnteredValue: sheets.ExtendedValue(stringValue: link)),
                    sheets.CellData(userEnteredValue: sheets.ExtendedValue(stringValue: referrer)),
                    sheets.CellData(userEnteredValue: sheets.ExtendedValue(stringValue: recruiter)),
                    sheets.CellData(userEnteredValue: sheets.ExtendedValue(stringValue: date)),
                    sheets.CellData(userEnteredValue: sheets.ExtendedValue(stringValue: 'No Action')),
                  ],
                ),
              ],
              fields: 'userEnteredValue',
            ),
          ),
        ],
      );

      // Execute the request
      await sheetsApi.spreadsheets.batchUpdate(request, spreadsheetId);
      
      print('Successfully added job to Google Sheets!');
      
    } catch (e) {
      print('Error updating Google Sheets: $e');
      throw Exception('Failed to update Google Sheets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NGL Job Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add Job Entry',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track your job applications',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Company Field
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(
                  labelText: 'Company',
                  hintText: 'Enter company name',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a company name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Link Field
              TextFormField(
                controller: _linkController,
                decoration: InputDecoration(
                  labelText: 'Job Link',
                  hintText: 'Paste job posting URL here',
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a job link';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Job Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedJobType,
                decoration: InputDecoration(
                  labelText: 'Job Type',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'newgrad',
                    child: Text('New Grad'),
                  ),
                  DropdownMenuItem(
                    value: 'intern',
                    child: Text('Intern'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedJobType = value!;
                  });
                },
              ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitJob,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Job',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Back Button
              OutlinedButton.icon(
                onPressed: () {
                  SystemNavigator.pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
