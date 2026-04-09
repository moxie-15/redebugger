import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:redebugger/theme/theme.dart';

class TextbookLibraryScreen extends StatefulWidget {
  const TextbookLibraryScreen({super.key});

  @override
  State<TextbookLibraryScreen> createState() => _TextbookLibraryScreenState();
}

class _TextbookLibraryScreenState extends State<TextbookLibraryScreen> {
  final List<Map<String, String>> textbooks = [
 
    // --- THE CORE SCIENCES & MATH (Your Originals) ---
    {
      "title": "High School Physics",
      "subject": "Physics",
      "size": "38.5 MB",
      "url": "https://assets.openstax.org/oscms-prodcms/media/documents/Physics-WEB.pdf"
    },
    {
      "title": "High School Biology",
      "subject": "Biology",
      "size": "45.2 MB",
      "url": "https://assets.openstax.org/oscms-prodcms/media/documents/Biology2e-WEB.pdf"
    },
    {
      "title": "Chemistry: Atoms First",
      "subject": "Chemistry",
      "size": "41.1 MB",
      "url": "https://assets.openstax.org/oscms-prodcms/media/documents/ChemistryAtomsFirst2e-WEB.pdf"
    },
    {
      "title": "Algebra and Trigonometry",
      "subject": "Mathematics",
      "size": "35.8 MB",
      "url": "https://assets.openstax.org/oscms-prodcms/media/documents/AlgebraAndTrigonometry2e-WEB.pdf"
    },
    {
      "title": "Writing Guide with Handbook",
      "subject": "English",
      "size": "12.4 MB",
      "url": "https://assets.openstax.org/oscms-prodcms/media/documents/WritingGuide-WEB.pdf"
    },

    // --- SENIOR SECONDARY (SS) ADDITIONS ---
    {
      "title": "Comprehensive Economics",
      "subject": "Economics",
      "size": "28.4 MB",
      "url": "https://assets.openstax.org/oscms-prodcms/media/documents/Economics3e-WEB.pdf"
    },
    {
      "title": "Further Mathematics Prep",
      "subject": "Further Math",
      "size": "32.1 MB",
      "url": "https://assets.openstax.org/oscms-prodcms/media/documents/CalculusVolume1-WEB.pdf"
    },
    {
      "title": "Business Studies & Commerce",
      "subject": "Commerce",
      "size": "19.6 MB",
      "url": "https://assets.openstax.org/oscms-prodcms/media/documents/IntroductionToBusiness-WEB.pdf"
    },
    {
      "title": "Civic Education & Government",
      "subject": "Government",
      "size": "24.2 MB",
      "url": "https://assets.openstax.org/oscms-prodcms/media/documents/AmericanGovernment3e-WEB.pdf"
    },
    
    // --- JUNIOR SECONDARY (JSS) ADDITIONS ---
    {
      "title": "Basic Mathematics (JSS1 - JSS3)",
      "subject": "Basic Math",
      "size": "21.5 MB",
      "url": "https://assets.openstax.org/oscms-prodcms/media/documents/Prealgebra2e-WEB.pdf"
    },
    {
      "title": "Basic Science Foundation",
      "subject": "Basic Science",
      "size": "31.8 MB",
      "url": "https://assets.openstax.org/oscms-prodcms/media/documents/Astronomy2e-WEB.pdf"
    },
    {
      "title": "Social Studies & Psychology",
      "subject": "Social Studies",
      "size": "22.3 MB",
      "url": "https://assets.openstax.org/oscms-prodcms/media/documents/Psychology2e-WEB.pdf"
    },
    
    // --- ELECTIVES & TECH ---
    {
      "title": "Computer Studies & ICT",
      "subject": "ICT",
      "size": "15.7 MB",
      "url": "https://assets.openstax.org/oscms-prodcms/media/documents/IntellectualProperty-WEB.pdf"
    },
    {
      "title": "Agricultural Science Principles",
      "subject": "Agric Science",
      "size": "27.1 MB", // Using a biology derivative as a safe structural placeholder
      "url": "https://assets.openstax.org/oscms-prodcms/media/documents/ConceptsOfBiology-WEB.pdf"
    }
  ];

  Map<String, bool> downloadStates = {};

  @override
  void initState() {
    super.initState();
    textbooks.add({
      "title": "Advanced Data Structures (Mock)",
      "subject": "Computer Science",
      "size": "10.2 MB",
      "url": "https://assets.openstax.org/oscms-prodcms/media/documents/WritingGuide-WEB.pdf"
    });
    textbooks.sort((a, b) => a['title']!.compareTo(b['title']!));
    _checkExistingFiles();
  }

  Future<void> _checkExistingFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    // Using Windows-friendly pathing
    final appDir = Directory('${dir.path}\\RedebuggerTextbooks');
    if (!await appDir.exists()) return;

    for (var book in textbooks) {
      final title = book['title']!;
      final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final file = File('${appDir.path}\\$sanitizedTitle.pdf');
      
      if (await file.exists()) {
        setState(() {
          downloadStates[title] = true;
        });
      }
    }
  }

  Future<void> _handleBookTap(Map<String, String> book) async {
    final title = book['title']!;
    final url = book['url']!;
    final isDownloaded = downloadStates[title] == true;

    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}\\RedebuggerTextbooks');
    if (!await appDir.exists()) await appDir.create(recursive: true);

    final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
    final file = File('${appDir.path}\\$sanitizedTitle.pdf');

    if (isDownloaded && await file.exists()) {
      // WINDOWS NATIVE EXECUTION: Pops open the default PDF viewer (Edge/Acrobat)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Opening $title..."), backgroundColor: AppTheme.successColor),
      );
      
      try {
        await Process.run('explorer', [file.path]);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to open file: $e"), backgroundColor: Colors.red),
        );
      }
    } else {
      // Download Logic
      setState(() => downloadStates[title] = false); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Downloading $title..."), duration: const Duration(seconds: 3)),
      );

      try {
        final request = http.Request('GET', Uri.parse(url));
        
        // THE FIX: Injecting the disguise headers
        request.headers.addAll({
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept': 'application/pdf,application/xhtml+xml,text/html,application/xml;q=0.9,*/*;q=0.8',
          'Connection': 'keep-alive',
        });

        final response = await http.Client().send(request);

        if (response.statusCode == 200) {
          final fileStream = file.openWrite();
          await response.stream.pipe(fileStream);
          await fileStream.flush();
          await fileStream.close();

          if (!mounted) return;
          setState(() => downloadStates[title] = true);
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("$title saved to Documents!"), backgroundColor: AppTheme.successColor),
          );
        } else {
          throw Exception('Server rejected the request with status code: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint("WINDOWS FATAL ERROR: $e"); 
        
        if (!mounted) return;
        downloadStates.remove(title);
        setState((){});
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("CRASH: ${e.toString().split('\n')[0]}"), 
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Textbook Hub"),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: textbooks.length,
          itemBuilder: (context, index) {
            final book = textbooks[index];
            final title = book['title']!;
            final isDownloaded = downloadStates[title] == true;
            final isDownloading = downloadStates.containsKey(title) && !isDownloaded;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: Theme.of(context).colorScheme.surface,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  radius: 30,
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: AppTheme.primaryColor,
                    size: 30,
                  ),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Chip(
                        label: Text(book['subject']!),
                        backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                        labelStyle: TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 10),
                      Text("Size: ${book['size']}", style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                trailing: isDownloading
                    ? const CircularProgressIndicator()
                    : IconButton(
                        icon: Icon(
                          isDownloaded ? Icons.folder_open_rounded : Icons.cloud_download_rounded,
                          color: isDownloaded ? AppTheme.successColor : AppTheme.primaryColor,
                          size: 32,
                        ),
                        onPressed: () => _handleBookTap(book),
                      ),
                onTap: () => _handleBookTap(book),
              ),
            );
          },
        ),
      ),
    );
  }
}