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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
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
  
  Future<Map<String, dynamic>> _getServiceAccountCredentials() async {
    final jsonString = await rootBundle.loadString('assets/secrets.json');
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

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
      final credentialsJson = await _getServiceAccountCredentials();
      final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
      
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
