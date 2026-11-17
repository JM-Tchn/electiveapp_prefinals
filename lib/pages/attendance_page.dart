import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'student_form_page.dart';

const _attendanceStatuses = ['Present', 'Absent', 'Late', 'Excused'];

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view attendance.')),
      );
    }

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('attendance');

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AttendanceFormPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Record Attendance'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: collection.orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load attendance: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!.docs;
          if (records.isEmpty) {
            return const Center(
              child: Text('No attendance records yet. Tap Record Attendance.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final data = record.data();
              final dateValue = data['date'];
              final date = dateValue is Timestamp ? dateValue.toDate() : null;
              final dateText = date == null
                  ? 'Date unavailable'
                  : MaterialLocalizations.of(context).formatMediumDate(date);
              final remarks = data['remarks']?.toString().trim() ?? '';

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      data['status'] == 'Present'
                          ? Icons.check
                          : Icons.event_note,
                    ),
                  ),
                  title: Text(data['studentName']?.toString() ?? 'Student'),
                  subtitle: Text(
                    '${data['studentNumber'] ?? ''} • '
                    '${data['course'] ?? ''}\n'
                    '$dateText • ${data['status'] ?? 'Unknown'}'
                    '${remarks.isEmpty ? '' : '\n$remarks'}',
                  ),
                  isThreeLine: remarks.isNotEmpty,
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'edit') {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttendanceFormPage(
                              documentId: record.id,
                              initialData: data,
                            ),
                          ),
                        );
                      } else if (action == 'delete') {
                        await _deleteAttendance(context, collection, record);
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

class AttendanceFormPage extends StatefulWidget {
  const AttendanceFormPage({super.key, this.documentId, this.initialData});

  final String? documentId;
  final Map<String, dynamic>? initialData;

  @override
  State<AttendanceFormPage> createState() => _AttendanceFormPageState();
}

class _AttendanceFormPageState extends State<AttendanceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _remarks = TextEditingController();
  String? _studentId;
  late DateTime _date;
  String _status = _attendanceStatuses.first;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};
    _studentId = data['studentId']?.toString();
    final dateValue = data['date'];
    _date = dateValue is Timestamp ? dateValue.toDate() : DateTime.now();
    final status = data['status']?.toString();
    if (_attendanceStatuses.contains(status)) _status = status!;
    _remarks.text = data['remarks']?.toString() ?? '';
  }

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before saving attendance.')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a student first.')),
      );
      return;
    }

    setState(() => _saving = true);
    final studentData = selectedStudent.data();
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('attendance');
    final data = <String, dynamic>{
      'studentId': selectedStudent.id,
      'studentNumber': studentData['studentNumber']?.toString() ?? '',
      'studentName': studentData['fullName']?.toString() ?? '',
      'course': studentData['course']?.toString() ?? '',
      'date': Timestamp.fromDate(_date),
      'status': _status,
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
                  ? 'Attendance recorded.'
                  : 'Attendance record updated.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $error')));
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
        body: Center(child: Text('Please sign in to record attendance.')),
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
            appBar: AppBar(title: const Text('Record Attendance')),
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
            appBar: AppBar(title: const Text('Record Attendance')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Add a student before recording attendance.'),
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

        final selectedStudentId = studentDocs.any(
          (student) => student.id == _studentId,
        )
            ? _studentId
            : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.documentId == null
                  ? 'Record Attendance'
                  : 'Edit Attendance',
            ),
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
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      MaterialLocalizations.of(context).formatMediumDate(_date),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Attendance status',
                      border: OutlineInputBorder(),
                    ),
                    items: _attendanceStatuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
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
                    child: Text(_saving ? 'Saving...' : 'Save Attendance'),
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

Future<void> _deleteAttendance(
  BuildContext context,
  CollectionReference<Map<String, dynamic>> collection,
  QueryDocumentSnapshot<Map<String, dynamic>> record,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete attendance record?'),
      content: const Text('This attendance record will be permanently deleted.'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance record deleted.')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
  }
}
