Task Manager App
A simple Flutter-based task management app that allows users to create, view, and delete tasks. The app uses Supabase as the backend to store tasks, with features like user authentication, task creation, and task status tracking (done/not done).
Features

User Authentication: Log in to manage your tasks securely.
Task Management:
Add new tasks with a title.
View all your tasks in a list.
Mark tasks as done (read-only display for now).
Delete tasks.


Supabase Integration: Tasks are stored in a Supabase database with Row-Level Security (RLS) to ensure users only access their own tasks.

Prerequisites
Before you begin, ensure you have the following installed:

Flutter SDK (version 3.0.0 or later)
Dart (comes with Flutter)
A Supabase account and project
A code editor (e.g., VS Code with Flutter/Dart extensions)

Setup Instructions
1. Clone the Repository
git clone https://github.com/sumanm202/to_do-using-Flutter.git
cd to_do-using-Flutter

2. Install Dependencies
Run the following command to install the required Flutter packages:
flutter pub get

3. Configure Supabase

Create a Supabase Project:

Go to Supabase Dashboard and create a new project.
Note down your Supabase URL and Anon Key from the project settings (Settings > API).


Set Up the tasks Table:

In the Supabase SQL Editor, run the following to create the tasks table:CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  is_done BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);


Enable Row-Level Security (RLS) and add policies:ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own tasks" ON tasks
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own tasks" ON tasks
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tasks" ON tasks
FOR DELETE
USING (auth.uid() = user_id);




Configure Supabase in the App:

Open lib/main.dart and update the Supabase client initialization with your Supabase URL and Anon Key:await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);


Replace YOUR_SUPABASE_URL and YOUR_SUPABASE_ANON_KEY with the values from your Supabase project.



4. Run the App
Run the app on an emulator or physical device:
flutter run

Project Structure

lib/main.dart: Entry point of the app, initializes Supabase.
lib/auth/login_screen.dart: Handles user login (you may need to implement this if not already present).
lib/dashboard/dashboard_screen.dart: Main screen showing the task list.
lib/dashboard/task_model.dart: Data model for tasks.
lib/dashboard/task_tile.dart: Widget for displaying individual tasks.
lib/services/supabase_service.dart: Handles Supabase API calls for task operations.

Usage

Log In: Use your credentials to log in (or sign up if LoginScreen supports it).
View Tasks: Your tasks will be displayed in a list, showing the title and done status.
Add a Task:
Click the floating + button.
Enter a task title and press "Add".


Delete a Task:
Click the delete icon next to a task to remove it.


Sign Out:
Click the logout icon in the app bar to sign out.
