import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_screen.dart';
import '../services/supabase_service.dart';
import '../utils/image_utils.dart';
import 'task_tile.dart';
import '/task_model.dart';
import 'edit_task_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseService _taskService = SupabaseService();
  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _isListView = true;
  String? _userName;
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    print('Logged in user: $user');
    if (user == null) {
      print('No user logged in, redirecting to LoginScreen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      _loadTasks();
      _loadUserProfile();
    }
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      print('Calling fetchTasks...');
      final fetchedTasks = await _taskService.fetchTasks();
      print('Fetched tasks count: ${fetchedTasks.length}');
      print('Fetched tasks: ${fetchedTasks.map((t) => {"id": t.id, "title": t.title, "description": t.description, "isDone": t.isDone}).toList()}');
      setState(() {
        _tasks = fetchedTasks;
        _isLoading = false;
      });
      if (fetchedTasks.isEmpty) {
        print('No tasks fetched. Check Supabase table or RLS policies.');
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tasks: $e')),
      );
    }
  }

  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profileData = await _taskService.fetchProfile(user.id);
        if (profileData != null) {
          setState(() {
            _userName = profileData['name'];
            _profilePictureUrl = profileData['profile_picture_url'];
            print('Loaded profile picture URL in Dashboard: $_profilePictureUrl');
            // Clear image cache
            imageCache.clear();
            imageCache.clearLiveImages();
          });
        }
      } catch (e) {
        print('Error loading profile: $e');
      }
    }
  }

  Future<void> _addTask(String title, {String? description}) async {
    try {
      print('Adding task: $title, description: $description');
      await _taskService.addTask(title, description: description);
      print('Task added, reloading tasks...');
      await _loadTasks();
    } catch (e) {
      print('Error adding task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add task: $e')),
      );
    }
  }

  Future<void> _toggleTask(String id, bool isDone) async {
    try {
      print('Toggling task with id: $id, isDone: $isDone');
      await _taskService.updateTask(id, isDone);
      print('Task toggled, reloading tasks...');
      await _loadTasks();
    } catch (e) {
      print('Error toggling task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle task: $e')),
      );
    }
  }

  Future<void> _deleteTask(String id) async {
    try {
      print('Deleting task with id: $id');
      await _taskService.deleteTask(id);
      print('Task deleted, reloading tasks...');
      await _loadTasks();
    } catch (e) {
      print('Error deleting task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete task: $e')),
      );
    }
  }

  void _showAddTaskSheet() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 5,
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Task',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Task Description',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                  style: const TextStyle(fontSize: 16),
                  maxLines: 3,
                  minLines: 2,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final description = descriptionController.text.trim();
                      if (title.isNotEmpty) {
                        Navigator.pop(context);
                        _addTask(title, description: description.isNotEmpty ? description : null);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a task title')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Add Task',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building DashboardScreen, tasks count: ${_tasks.length}, isLoading: $_isLoading, isListView: $_isListView');
    print('Rebuilding DashboardScreen with profile picture URL: $_profilePictureUrl');
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo[300]!, Colors.indigo[800]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _userName != null ? 'Hello, $_userName!' : 'My Tasks',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          'List View',
                          style: TextStyle(color: Colors.white),
                        ),
                        Switch(
                          value: _isListView,
                          onChanged: (value) {
                            setState(() {
                              _isListView = value;
                            });
                          },
                          activeColor: Colors.blueAccent,
                          activeTrackColor: Colors.blue[100],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfileScreen()),
                        ).then((updated) {
                          if (updated == true) {
                            _loadUserProfile();
                          }
                        });
                      },
                      child: CircleAvatar(
                        // Removed: backgroundColor: Colors.white,
                        child: (_profilePictureUrl == null || _profilePictureUrl!.isEmpty)
                            ? const Icon(Icons.person, color: Colors.indigo)
                            : null,
                        foregroundImage: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                            ? FadeInImage(
                          placeholder: MemoryImage(kTransparentImage),
                          image: NetworkImage(_profilePictureUrl!),
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) {
                            print('Image load error in DashboardScreen: $error');
                            return const Icon(
                              Icons.error,
                              color: Colors.red,
                            );
                          },
                        ).image
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
                      : _tasks.isEmpty
                      ? const Center(
                    child: Text(
                      'No tasks yet. Add some!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                      : _isListView
                      ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      print('Rendering task $index: id=${task.id}, title=${task.title}, description=${task.description}, isDone=${task.isDone}');
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditTaskScreen(task: task),
                            ),
                          ).then((updatedTask) {
                            if (updatedTask != null) {
                              setState(() {
                                final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
                                if (index != -1) {
                                  _tasks[index] = updatedTask;
                                }
                              });
                            }
                          });
                        },
                        child: TaskTile(
                          task: task,
                          onDelete: () => _deleteTask(task.id),
                          onToggle: (newValue) => _toggleTask(task.id, newValue),
                        ),
                      );
                    },
                  )
                      : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditTaskScreen(task: task),
                            ),
                          ).then((updatedTask) {
                            if (updatedTask != null) {
                              setState(() {
                                final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
                                if (index != -1) {
                                  _tasks[index] = updatedTask;
                                }
                              });
                            }
                          });
                        },
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: task.isDone
                                    ? [Colors.green[100]!, Colors.green[400]!]
                                    : [Colors.blue[100]!, Colors.blue[400]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: task.isDone,
                                    onChanged: (newValue) {
                                      if (newValue != null) {
                                        _toggleTask(task.id, newValue);
                                      }
                                    },
                                    activeColor: Colors.white,
                                    checkColor: task.isDone ? Colors.green[900] : Colors.blue[900],
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title.isEmpty ? 'Untitled Task' : task.title,
                                          style: TextStyle( // Fixed: Removed 'const', changed Weight to FontWeight
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                          softWrap: true,
                                        ),
                                        if (task.description != null && task.description!.isNotEmpty)
                                          Text(
                                            task.description!,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.black54,
                                            ),
                                            softWrap: true,
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                    onPressed: () => _deleteTask(task.id),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        elevation: 8,
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}