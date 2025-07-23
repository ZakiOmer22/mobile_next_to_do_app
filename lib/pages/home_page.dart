import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:reorderables/reorderables.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/task.dart';
import 'add_task_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  late final User user;
  List<Task> tasks = [];
  bool darkMode = false;

  String searchFilter = '';
  String sortKey = 'date';

  @override
  void initState() {
    super.initState();
    user = supabase.auth.currentUser!;
    fetchTasks();

    supabase
        .channel('public:tasks')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(event: '*', schema: 'public', table: 'tasks'),
          (payload, [ref]) {
            if (mounted) fetchTasks();
          },
        )
        .subscribe();
  }

  Future<void> fetchTasks() async {
    final response = await supabase
        .from('tasks')
        .select()
        .eq('user_id', user.id)
        .order('order', ascending: true)
        .execute();

    if (response.error == null) {
      setState(() {
        tasks = (response.data as List)
            .map((e) => Task.fromMap(e as Map<String, dynamic>))
            .toList();
      });
    }
  }

  Future<void> addTask() async {
    final newTask = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (context) => const AddTaskPage()),
    );
    if (newTask != null) {
      final response = await supabase.from('tasks').insert({
        'title': newTask.title,
        'description': newTask.description,
        'date': newTask.date?.toIso8601String(),
        'tags': newTask.tags,
        'priority': newTask.priority,
        'order': tasks.length,
        'user_id': user.id,
      }).execute();

      if (response.error == null) {
        fetchTasks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding task: ${response.error!.message}')),
        );
      }
    }
  }

  void signOut() async {
    await supabase.auth.signOut();
  }

  void toggleDarkMode() {
    setState(() {
      darkMode = !darkMode;
    });
  }

  List<Task> get filteredTasks {
    var filtered = tasks.where((t) {
      final lower = searchFilter.toLowerCase();
      return t.title.toLowerCase().contains(lower) ||
          (t.description?.toLowerCase().contains(lower) ?? false);
    }).toList();

    if (sortKey == 'date') {
      filtered.sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return a.date!.compareTo(b.date!);
      });
    } else if (sortKey == 'priority') {
      final order = {'High': 0, 'Medium': 1, 'Low': 2};
      filtered.sort((a, b) => order[a.priority]!.compareTo(order[b.priority]!));
    }

    return filtered;
  }

  Future<void> exportCsv() async {
    List<List<dynamic>> rows = [
      ['Title', 'Description', 'Date', 'Tags', 'Priority'],
      ...filteredTasks.map((t) => [
            t.title,
            t.description ?? '',
            t.date != null ? DateFormat.yMd().format(t.date!) : '',
            t.tags?.join(', ') ?? '',
            t.priority,
          ]),
    ];

    String csv = const ListToCsvConverter().convert(rows);

    await Printing.sharePdf(bytes: Uint8List.fromList(csv.codeUnits), filename: 'tasks.csv');
  }

  Future<void> exportPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Table.fromTextArray(
            headers: ['Title', 'Description', 'Date', 'Tags', 'Priority'],
            data: filteredTasks.map((t) {
              return [
                t.title,
                t.description ?? '',
                t.date != null ? DateFormat.yMd().format(t.date!) : '',
                t.tags?.join(', ') ?? '',
                t.priority,
              ];
            }).toList(),
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'tasks.pdf');
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    final list = List<Task>.from(filteredTasks);
    final task = list.removeAt(oldIndex);
    list.insert(newIndex, task);

    // Update order in DB for all reordered tasks
    for (int i = 0; i < list.length; i++) {
      await supabase
          .from('tasks')
          .update({'order': i})
          .eq('id', list[i].id)
          .execute();
    }
    fetchTasks();
  }

  Color priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red.shade400;
      case 'Medium':
        return Colors.orange.shade400;
      case 'Low':
      default:
        return Colors.green.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Task List'),
          actions: [
            IconButton(
              icon: Icon(darkMode ? Icons.sunny : Icons.nightlight_round),
              onPressed: toggleDarkMode,
              tooltip: 'Toggle Dark Mode',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: signOut,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => searchFilter = v),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: sortKey,
                items: const [
                  DropdownMenuItem(value: 'date', child: Text('Sort by Date')),
                  DropdownMenuItem(value: 'priority', child: Text('Sort by Priority')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => sortKey = v);
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                    onPressed: exportPdf,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.file_copy),
                    label: const Text('Export CSV'),
                    onPressed: exportCsv,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ReorderableColumn(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  onReorder: reorderTasks,
                  children: filteredTasks.map((task) {
                    return Card(
                      key: ValueKey(task.id),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(task.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task.description != null) Text(task.description!),
                            if (task.date != null)
                              Text('Date: ${DateFormat.yMd().format(task.date!)}'),
                            Wrap(
                              spacing: 6,
                              children: task.tags
                                      ?.map((t) => Chip(label: Text(t)))
                                      .toList() ??
                                  [],
                            ),
                            Text(
                              'Priority: ${task.priority}',
                              style: TextStyle(color: priorityColor(task.priority)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: addTask,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
