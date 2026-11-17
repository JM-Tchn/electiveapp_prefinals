import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'student_form_page.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCourse = '';
  String _selectedYear = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteStudent(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> collection,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text(
          'Delete ${doc.data()['fullName'] ?? 'this student'}? '
          'This cannot be undone.',
        ),
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
      await collection.doc(doc.id).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Student record deleted.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view student records.')),
      );
    }

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students');

    return Scaffold(
      appBar: AppBar(title: const Text('Student Records')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentFormPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: collection.orderBy('fullName').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load students: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final courses =
              docs
                  .map((doc) => doc.data()['course']?.toString().trim() ?? '')
                  .where((course) => course.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          if (_selectedCourse.isNotEmpty &&
              !courses.contains(_selectedCourse)) {
            courses.add(_selectedCourse);
          }
          final years =
              docs
                  .map(
                    (doc) => doc.data()['yearLevel']?.toString().trim() ?? '',
                  )
                  .where((year) => year.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          if (_selectedYear.isNotEmpty && !years.contains(_selectedYear)) {
            years.add(_selectedYear);
          }
          final query = _searchQuery.trim().toLowerCase();
          final filteredDocs = docs.where((doc) {
            final data = doc.data();
            final searchableText = [
              data['fullName'],
              data['studentNumber'],
              data['course'],
              data['yearLevel'],
              data['email'],
            ].map((value) => value?.toString() ?? '').join(' ').toLowerCase();

            return searchableText.contains(query) &&
                (_selectedCourse.isEmpty ||
                    data['course']?.toString() == _selectedCourse) &&
                (_selectedYear.isEmpty ||
                    data['yearLevel']?.toString() == _selectedYear);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    labelText: 'Search students',
                    hintText: 'Name, student number, course, or email',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCourse,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Course',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('All courses'),
                          ),
                          ...courses.map(
                            (course) => DropdownMenuItem(
                              value: course,
                              child: Text(
                                course,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedCourse = value ?? ''),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedYear,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Year level',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('All years'),
                          ),
                          ...years.map(
                            (year) => DropdownMenuItem(
                              value: year,
                              child: Text(
                                year,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedYear = value ?? ''),
                      ),
                    ),
                  ],
                ),
              ),
              if (docs.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No student records yet. Tap Add Student.'),
                  ),
                )
              else if (filteredDocs.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No students match these search filters.'),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data();
                      final name = data['fullName']?.toString() ?? '';
                      final trimmedName = name.trimLeft();
                      final initial = trimmedName.isEmpty
                          ? '?'
                          : String.fromCharCode(trimmedName.runes.first)
                                .toUpperCase();

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text(initial)),
                          title: Text(name),
                          subtitle: Text(
                            '${data['studentNumber'] ?? ''} • '
                            '${data['course'] ?? ''} • '
                            '${data['yearLevel'] ?? ''}\n'
                            '${data['email'] ?? ''}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'edit') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentFormPage(
                                      documentId: doc.id,
                                      initialData: data,
                                    ),
                                  ),
                                );
                              } else if (action == 'delete') {
                                await _deleteStudent(context, collection, doc);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
