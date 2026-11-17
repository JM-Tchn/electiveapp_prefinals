import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'student_form_page.dart';

class GradesPage extends StatelessWidget {
  const GradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view grades.')),
      );
    }

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('grades');

    return Scaffold(
      appBar: AppBar(title: const Text('Grades')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GradeFormPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Grade'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: collection.orderBy('updatedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load grades: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!.docs;
          if (records.isEmpty) {
            return const Center(
              child: Text('No grade records yet. Tap Add Grade.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final data = record.data();
              final remarks = data['remarks']?.toString().trim() ?? '';

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(data['grade']?.toString() ?? '-'),
                  ),
                  title: Text(
                    '${data['subject'] ?? 'Subject'}'
                    ' • ${data['studentName'] ?? 'Student'}',
                  ),
                  subtitle: Text(
                    '${data['studentNumber'] ?? ''} • '
                    '${data['course'] ?? ''}\n'
                    '${data['term'] ?? 'Term not set'}'
                    '${remarks.isEmpty ? '' : '\n$remarks'}',
                  ),
                  isThreeLine: remarks.isNotEmpty,
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'edit') {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GradeFormPage(
                              documentId: record.id,
                              initialData: data,
                            ),
                          ),
                        );
                      } else if (action == 'delete') {
                        await _deleteGrade(context, collection, record);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class GradeFormPage extends StatefulWidget {
  const GradeFormPage({super.key, this.documentId, this.initialData});

  final String? documentId;
  final Map<String, dynamic>? initialData;

  @override
  State<GradeFormPage> createState() => _GradeFormPageState();
}

class _GradeFormPageState extends State<GradeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _term = TextEditingController();
  final _grade = TextEditingController();
  final _remarks = TextEditingController();
  String? _studentId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};
    _studentId = data['studentId']?.toString();
    _subject.text = data['subject']?.toString() ?? '';
    _term.text = data['term']?.toString() ?? '';
    _grade.text = data['grade']?.toString() ?? '';
    _remarks.text = data['remarks']?.toString() ?? '';
  }

  @override
  void dispose() {
    _subject.dispose();
    _term.dispose();
    _grade.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _save(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before saving grades.')),
      );
      return;
    }

    QueryDocumentSnapshot<Map<String, dynamic>>? selectedStudent;
    for (final student in students) {
      if (student.id == _studentId) {
        selectedStudent = student;
        break;
      }
    }
    if (selectedStudent == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose a student first.')));
      return;
    }

    setState(() => _saving = true);
    final studentData = selectedStudent.data();
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('grades');
    final data = <String, dynamic>{
      'studentId': selectedStudent.id,
      'studentNumber': studentData['studentNumber']?.toString() ?? '',
      'studentName': studentData['fullName']?.toString() ?? '',
      'course': studentData['course']?.toString() ?? '',
      'subject': _subject.text.trim(),
      'term': _term.text.trim(),
      'grade': double.parse(_grade.text.trim()),
      'remarks': _remarks.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.documentId == null) {
        await collection.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await collection.doc(widget.documentId).update(data);
      }
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.documentId == null
                  ? 'Grade recorded successfully.'
                  : 'Grade record updated.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to manage grades.')),
      );
    }

    final students = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: students.orderBy('fullName').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Grade')),
            body: Center(
              child: Text('Unable to load students: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final studentDocs = snapshot.data!.docs;
        if (studentDocs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Grade')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Add a student before entering grades.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentFormPage(),
                        ),
                      ),
                      child: const Text('Add Student'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final selectedStudentId =
            studentDocs.any((student) => student.id == _studentId)
            ? _studentId
            : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.documentId == null ? 'Add Grade' : 'Edit Grade'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(selectedStudentId),
                    initialValue: selectedStudentId,
                    decoration: const InputDecoration(
                      labelText: 'Student',
                      border: OutlineInputBorder(),
                    ),
                    items: studentDocs
                        .map(
                          (student) => DropdownMenuItem(
                            value: student.id,
                            child: Text(
                              student.data()['fullName']?.toString() ??
                                  'Unnamed student',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _studentId = value),
                    validator: (value) =>
                        value == null ? 'Choose a student' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _subject,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a subject'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _term,
                    decoration: const InputDecoration(
                      labelText: 'Term / semester',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a term or semester'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _grade,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Grade (0-100)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final grade = double.tryParse(value?.trim() ?? '');
                      if (grade == null || grade < 0 || grade > 100) {
                        return 'Enter a grade from 0 to 100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _remarks,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Remarks (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : () => _save(studentDocs),
                    child: Text(_saving ? 'Saving...' : 'Save Grade'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _deleteGrade(
  BuildContext context,
  CollectionReference<Map<String, dynamic>> collection,
  QueryDocumentSnapshot<Map<String, dynamic>> record,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete grade record?'),
      content: const Text('This grade record will be permanently deleted.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await collection.doc(record.id).delete();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Grade record deleted.')));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Delete failed: $error')));
  }
}
