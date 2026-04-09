import 'dart:io';
import 'dart:typed_data';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:redebugger/model/question.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class FileParserService {
  /// Extracts raw text from either a PDF or DOCX file locally.
  static Future<String> extractText(File file) async {
    final String extension = file.path.split('.').last.toLowerCase();

    if (extension == 'pdf') {
      final List<int> bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } else if (extension == 'docx') {
      final List<int> bytes = await file.readAsBytes();
      final String text = docxToText(Uint8List.fromList(bytes));
      return text;
    } else {
      throw Exception("Unsupported file format: .$extension. Only PDF and DOCX are allowed.");
    }
  }

  /// Parses the extracted raw string into a list of structured Question objects based on the strict Template.
  static List<Question> parseQuestionsFromText(String rawText) {
    List<Question> questionsList = [];

    // The raw text might have inconsistent line breaks. Normalize them safely.
    // e.g., \r\n to \n
    final text = rawText.replaceAll('\r\n', '\n');

    // Split entire document into individual question blocks using "Q1.", "Q2.", etc.
    // The (?=Q\d+\.) regex splits right before the Q starts, preserving it.
    final List<String> blocks = text.split(RegExp(r'(?=\bQ\d+\.)'));

    for (var block in blocks) {
      final b = block.trim();
      if (b.isEmpty || !b.startsWith(RegExp(r'Q\d+\.'))) continue;

      try {
        // 1. Extract Question Text (Everything from QX. to A))
        final questionMatch = RegExp(r'Q\d+\.\s*(.*?)(?=\nA\))', dotAll: true).firstMatch(b);
        if (questionMatch == null) continue;
        final String questionText = questionMatch.group(1)?.trim() ?? '';

        // 2. Extract Options
        // We look for A) ..., B) ..., C) ..., D) ... 
        final String aText = _extractBetween(b, r'A\)', r'\nB\)');
        final String bText = _extractBetween(b, r'B\)', r'\nC\)');
        final String cText = _extractBetween(b, r'C\)', r'\nD\)');
        final String dText = _extractBetween(b, r'D\)', r'\nANS:');

        if (aText.isEmpty || bText.isEmpty || cText.isEmpty || dText.isEmpty) {
          continue; // Malformed options
        }

        final options = [aText, bText, cText, dText];

        // 3. Extract Answer Letter
        final ansMatch = RegExp(r'ANS:\s*([A-D])', caseSensitive: false).firstMatch(b);
        if (ansMatch == null) continue; // Malformed answer
        
        final String ansLetter = ansMatch.group(1)!.toUpperCase();
        int correctOptionIndex = 0;
        
        if (ansLetter == 'B') correctOptionIndex = 1;
        if (ansLetter == 'C') correctOptionIndex = 2;
        if (ansLetter == 'D') correctOptionIndex = 3;

        questionsList.add(
          Question(
            text: questionText,
            options: options,
            correctOptionIndex: correctOptionIndex,
          ),
        );
      } catch (e) {
        // Silently skip malformed blocks or log them depending on error reporting preferences
        continue;
      }
    }

    if (questionsList.isEmpty) {
      throw Exception("No valid questions found! Ensure your document strictly follows the template (Q1., A), B), C), D), ANS:).");
    }

    return questionsList;
  }

  static String _extractBetween(String source, String startPattern, String endPattern) {
    final exp = RegExp('$startPattern\\s*(.*?)(?=$endPattern)', dotAll: true);
    final match = exp.firstMatch(source);
    return match?.group(1)?.trim() ?? '';
  }
}
