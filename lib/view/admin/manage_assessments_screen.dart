import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redebugger/model/school_class.dart';
import 'package:redebugger/model/assessment.dart';
import 'package:redebugger/theme/theme.dart';
import 'package:redebugger/view/admin/add_assessment_screen.dart';

class ManageAssessmentsScreen extends StatefulWidget {
  final String? classId;
  final String? className;

  const ManageAssessmentsScreen({super.key, this.classId, this.className});

  @override
  State<ManageAssessmentsScreen> createState() => _ManageAssessmentsScreenState();
}

class _ManageAssessmentsScreenState extends State<ManageAssessmentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? _selectedClassId;

  Map<String, SchoolClass> _classMap = {};

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.classId;
    _listenClasses();
  }

  void _listenClasses() {
    _firestore.collection('classes').snapshots().listen((snapshot) {
      final map = <String, SchoolClass>{};
      for (var doc in snapshot.docs) {
        final schoolClass = SchoolClass.fromMap(doc.data(), id: doc.id);
        map[schoolClass.id] = schoolClass;
      }
      if (mounted) {
        setState(() {
          _classMap = map;
        });
      }
    });
  }

  Stream<QuerySnapshot> _getAssessmentStream() {
    Query query = _firestore.collection("assessments");
    if (_selectedClassId != null) {
      query = query.where("classId", isEqualTo: _selectedClassId);
    }
    return query.snapshots();
  }

  Widget _builderTitle() {
    if (_selectedClassId == null) {
      return const Text('All Assessments', style: TextStyle(fontWeight: FontWeight.bold));
    }
    final sclClass = _classMap[_selectedClassId!];
    return Text(sclClass?.name ?? 'Loading...', style: const TextStyle(fontWeight: FontWeight.bold));
  }

  void _openAddAssessmentScreen({Assessment? assessment}) {
    final classId = _selectedClassId;
    final className = classId != null ? _classMap[classId]?.name ?? 'Unknown' : 'Unknown';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAssessmentScreen(
          classId: classId,
          className: className,
          assessment: assessment,
        ),
      ),
    ).then((value) {
      if (mounted) setState(() {});
    });
  }

  // Teacher Release Results Logic
  void _toggleResultReleaseMode(Assessment assessment) async {
    try {
      if (assessment.releaseMode == 'manual') {
        bool newReleaseStatus = !assessment.isResultReleased;
        await _firestore.collection("assessments").doc(assessment.id).update({
          'isResultReleased': newReleaseStatus
        });
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newReleaseStatus ? 'Results Released to Learners!' : 'Results Withheld.')));
      } else {
         if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This assessment uses Scheduled release. You cannot toggle it manually.')));
      }
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _builderTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () => _openAddAssessmentScreen(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Assessments',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 12, 40, 0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                border: OutlineInputBorder(),
                hintText: 'Select Class',
                prefixIcon: Icon(Icons.class_),
              ),
              initialValue: _selectedClassId,
              items: _classMap.values.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
              onChanged: (value) => setState(() => _selectedClassId = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getAssessmentStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error loading assessments'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final assessments = snapshot.data!.docs
                    .map((doc) => Assessment.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
                    .where((assmt) => _searchQuery.isEmpty || assmt.title.toLowerCase().contains(_searchQuery))
                    .toList();

                if (assessments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assignment_outlined, size: 70),
                        const SizedBox(height: 10),
                        const Text("No assessments found"),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _openAddAssessmentScreen(),
                          child: const Text('Add Assessment'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: assessments.length,
                  itemBuilder: (context, index) {
                    final assessment = assessments[index];
                    final className = _classMap[assessment.classId]?.name ?? 'Unknown';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.assignment_outlined, color: AppTheme.primaryColor),
                        ),
                        title: Text(assessment.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.class_, size: 16),
                                const SizedBox(width: 4),
                                Text(className),
                                const SizedBox(width: 16),
                                const Icon(Icons.timer_outlined, size: 16),
                                const SizedBox(width: 4),
                                Text("${assessment.durationMinutes} mins"),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: assessment.type == 'exam' ? Colors.red.shade100 : Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: Text(assessment.type.toUpperCase(), style: TextStyle(fontSize: 10, color: assessment.type == 'exam' ? Colors.red : Colors.blue, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(assessment.isResultReleased ? Icons.visibility : Icons.visibility_off, size: 16, color: assessment.isResultReleased ? Colors.green : Colors.grey),
                                const SizedBox(width: 4),
                                Text(assessment.releaseMode == 'scheduled' ? "Releases: ${assessment.releaseDate?.toLocal().toString().split(' ')[0] ?? '?'}" : (assessment.isResultReleased ? "Results Released" : "Results Hidden"), style: TextStyle(fontSize: 12, color: assessment.isResultReleased ? Colors.green : Colors.grey)),
                              ],
                            )
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.edit, color: AppTheme.primaryColor), title: Text('Edit'))),
                            if (assessment.releaseMode == 'manual')
                              PopupMenuItem(value: 'toggle_results', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(assessment.isResultReleased ? Icons.visibility_off : Icons.visibility, color: Colors.orange), title: Text(assessment.isResultReleased ? 'Hide Results' : 'Release Results'))),
                            const PopupMenuItem(value: 'delete', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete'))),
                          ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _openAddAssessmentScreen(assessment: assessment);
                            } else if (value == 'toggle_results') {
                              _toggleResultReleaseMode(assessment);
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text("Delete Assessment"), content: const Text("Delete this assessment?"), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red)))]));
                              if (confirm == true) await _firestore.collection("assessments").doc(assessment.id).delete();
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
