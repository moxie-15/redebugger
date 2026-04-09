import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:redebugger/model/question.dart';
import 'package:redebugger/model/quiz.dart';

class AlocQuizService {
  static const String baseUrl = 'https://questions.aloc.com.ng/api/v2';
  
  // Supported Nigerian Curriculum Subjects by ALOC
  static const List<String> subjects = [
    'english', 'mathematics', 'physics', 'chemistry', 'biology', 
    'economics', 'civiceducation', 'government', 'commerce', 'accounting'
  ];

  /// Core fetch: pulls random mock questions and caches them for offline usage.
  /// If device is offline, it reads from the cache.
  static Future<Quiz> fetchQuiz(String subject, {int count = 10}) async {
    final sanitizedSubject = subject.toLowerCase().replaceAll(' ', '');
    final String actualSubject = subjects.contains(sanitizedSubject) ? sanitizedSubject : 'english';
    
    List<Question> questions = [];
    bool isOfflineMode = false;

    try {
      // Free ALOC endpoints: We loop the /m (mock) endpoint or try /q/count
      // Using /m concurrently avoids rate limits or missing token errors often found on /q
      final futures = List.generate(count, (_) => http.get(Uri.parse('$baseUrl/m?subject=$actualSubject')));
      // Fast parallel execution (since free tier is unrestricted for /m)
      final responses = await Future.wait(futures);
      
      for (var response in responses) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 200 && data['data'] != null) {
            questions.add(_parseQuestion(data['data']));
          }
        }
      }

      if (questions.isNotEmpty) {
        // Cache this new set for offline usage
        await _cacheQuestions(actualSubject, questions);
      } else {
        throw Exception("Failed to parse APi payload");
      }
    } catch (e) {
      // IF OFFLINE OR HTTP FAILS, LOAD FROM CACHE
      isOfflineMode = true;
      questions = await _loadCachedQuestions(actualSubject);
      if (questions.isEmpty) {
        throw Exception("No offline cache available for $actualSubject. Please connect to internet once.");
      }
    }

    return Quiz(
      id: 'aloc_${actualSubject}_${DateTime.now().millisecondsSinceEpoch}',
      title: '${actualSubject.toUpperCase()} (Online/Offline National Exam)' + (isOfflineMode ? ' [OFFLINE CACHE]' : ''),
      categoryId: 'aloc_national',
      categoryName: 'National Standardized Exams',
      timeLimit: count * 1, // 1 min per question approx
      questions: questions,
      shuffleQuestions: true,
      showResultsToStudent: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static Question _parseQuestion(Map<String, dynamic> raw) {
    // raw['question'] is the text. raw['option'] is {"a":"..", "b":"..", ...} 
    // raw['answer'] is 'a','b','c','d'
    final String text = raw['question']?.toString() ?? "Missing question text";
    final Map<String, dynamic> optionsMap = raw['option'] ?? {};
    
    List<String> validOptions = [];
    int correctIndex = 0;
    
    final answerChar = raw['answer']?.toString().toLowerCase() ?? 'a';
    final keys = ['a', 'b', 'c', 'd', 'e'];
    
    for (int i = 0; i < keys.length; i++) {
        if (optionsMap.containsKey(keys[i])) {
            validOptions.add(optionsMap[keys[i]].toString());
            if (keys[i] == answerChar) {
                correctIndex = validOptions.length - 1;
            }
        }
    }

    // Fallback if parsing fails
    if (validOptions.isEmpty) {
      validOptions = ["A", "B", "C", "D"];
      correctIndex = 0;
    }

    // Note: ALOC sometimes includes HTML tags in questions e.g. <p>...</p>. 
    // We clean them quickly.
    String cleanText = text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();

    return Question(
      text: cleanText,
      options: validOptions,
      correctOptionIndex: correctIndex,
    );
  }

  // ====== OFFLINE CACHE MANAGEMENT ======
  static Future<File> _getCacheFile(String subject) async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/RedebuggerQuizzesCache');
    if (!await appDir.exists()) await appDir.create(recursive: true);
    return File('${appDir.path}/$subject.json');
  }

  static Future<void> _cacheQuestions(String subject, List<Question> questions) async {
    try {
      final file = await _getCacheFile(subject);
      final jsonList = questions.map((q) => q.toMap()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      // Ignore cache failure
    }
  }

  static Future<List<Question>> _loadCachedQuestions(String subject) async {
    try {
      final file = await _getCacheFile(subject);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        return jsonList.map((q) => Question.fromMap(q)).toList();
      }
    } catch (e) {
      // Offline fallback failed
    }
    return [];
  }
}
