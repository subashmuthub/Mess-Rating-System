import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'mess_cloud_service.dart';
import 'mess_models.dart';
import 'mess_repository.dart';
import 'mess_workflows.dart';

class MessMenuApp extends StatefulWidget {
  const MessMenuApp({super.key});

  @override
  State<MessMenuApp> createState() => _MessMenuAppState();
}

class _MessMenuAppState extends State<MessMenuApp> {
  final MessRepository _repository = MessRepository.instance;
  final MessCloudService _cloud = MessCloudService.instance;
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _loading = true;
  MessUser? _user;
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _repository.init();
    final current = await _repository.currentUser();
    MessUser? cloudCurrent;
    try {
      cloudCurrent = await _cloud.currentMessUser();
    } catch (e) {
      debugPrint('Cloud bootstrap skipped: $e');
    }
    if (!mounted) return;
    setState(() {
      _user = cloudCurrent ?? current;
      _loading = false;
    });
  }

  Future<void> _handleAuth(MessUser user) async {
    if (!mounted) return;
    setState(() => _user = user);
  }

  Future<void> _logout() async {
    await _repository.logout();
    await _cloud.signOut();
    if (!mounted) return;
    setState(() => _user = null);
  }

  Future<void> _loginWithGoogle() async {
    try {
      final cloudUser = await _cloud.signInWithGoogle();
      if (!mounted) return;
      setState(() => _user = cloudUser);
    } catch (e) {
      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    }
  }

  void _toggleThemeMode() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mess Menu + Rating',
      scaffoldMessengerKey: _messengerKey,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0C4A6E),
          primary: const Color(0xFF0C4A6E),
          secondary: const Color(0xFF0EA5E9),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          labelStyle: const TextStyle(color: Color(0xFF475569)),
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF0C4A6E), width: 1.4),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0EA5E9),
          brightness: Brightness.dark,
        ),
      ),
      home: _loading
          ? const _LoadingScreen()
          : (_user == null
              ? LoginRegisterScreen(
                  onAuthenticated: _handleAuth,
                  onGoogleAuthenticated: _loginWithGoogle,
                )
              : HomeRouter(
                  user: _user!,
                  onLogout: _logout,
                  onToggleTheme: _toggleThemeMode,
                  isDarkMode: _themeMode == ThemeMode.dark,
                )),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(strokeWidth: 4),
        ),
      ),
    );
  }
}

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({
    super.key,
    required this.onAuthenticated,
    required this.onGoogleAuthenticated,
  });

  final ValueChanged<MessUser> onAuthenticated;
  final Future<void> Function() onGoogleAuthenticated;

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _blockCtrl = TextEditingController();

  bool _registerMode = false;
  bool _busy = false;
  UserRole _role = UserRole.student;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _departmentCtrl.dispose();
    _yearCtrl.dispose();
    _roomCtrl.dispose();
    _blockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      MessUser? user;
      if (_registerMode) {
        user = await MessRepository.instance.register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _role,
          department: _departmentCtrl.text.trim().isEmpty ? null : _departmentCtrl.text.trim(),
          year: _yearCtrl.text.trim().isEmpty ? null : _yearCtrl.text.trim(),
          roomNumber: _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
          hostelBlock: _blockCtrl.text.trim().isEmpty ? null : _blockCtrl.text.trim(),
        );
      } else {
        user = await MessRepository.instance.login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
      }

      if (!mounted) return;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _registerMode
                  ? 'Registration failed. Email already exists.'
                  : 'Invalid email or password.',
            ),
          ),
        );
        return;
      }
      widget.onAuthenticated(user);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F7FB), Color(0xFFEAF2F9)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                        blurRadius: 34,
                        offset: const Offset(0, 22),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 900;
                        final hero = _AuthHero(isWide: wide);
                        final form = _AuthForm(
                          formKey: _formKey,
                          registerMode: _registerMode,
                          role: _role,
                          busy: _busy,
                          nameCtrl: _nameCtrl,
                          emailCtrl: _emailCtrl,
                          passwordCtrl: _passwordCtrl,
                          departmentCtrl: _departmentCtrl,
                          yearCtrl: _yearCtrl,
                          roomCtrl: _roomCtrl,
                          blockCtrl: _blockCtrl,
                          onToggleMode: () => setState(() => _registerMode = !_registerMode),
                          onRoleChanged: (value) => setState(() => _role = value),
                          onSubmit: _submit,
                          onGoogleSignIn: widget.onGoogleAuthenticated,
                        );

                        if (!wide) {
                          return Column(
                            children: [hero, form],
                          );
                        }

                        return IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(flex: 5, child: hero),
                              Expanded(flex: 6, child: form),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isWide ? 32 : 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2545), Color(0xFF113B63), Color(0xFF0EA5E9)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: const Text(
                  'Campus Hostel Control',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Mess operations\nwith a proper product UI.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Students see menu quality, crowd intent, and ratings. Admins and wardens get a live control room for complaints, suggestions, and meal planning.',
                style: TextStyle(color: Colors.white70, height: 1.45, fontSize: 15.5),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _HeroMetric(icon: Icons.restaurant, label: 'Live menu tracking'),
              _HeroMetric(icon: Icons.rate_review, label: 'Food ratings'),
              _HeroMetric(icon: Icons.how_to_vote, label: 'Suggestion voting'),
              _HeroMetric(icon: Icons.verified_outlined, label: 'Complaint SLA'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.formKey,
    required this.registerMode,
    required this.role,
    required this.busy,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.departmentCtrl,
    required this.yearCtrl,
    required this.roomCtrl,
    required this.blockCtrl,
    required this.onToggleMode,
    required this.onRoleChanged,
    required this.onSubmit,
    required this.onGoogleSignIn,
  });

  final GlobalKey<FormState> formKey;
  final bool registerMode;
  final UserRole role;
  final bool busy;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController departmentCtrl;
  final TextEditingController yearCtrl;
  final TextEditingController roomCtrl;
  final TextEditingController blockCtrl;
  final VoidCallback onToggleMode;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onSubmit;
  final Future<void> Function() onGoogleSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      color: Colors.white,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Mess Menu + Rating',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                registerMode
                    ? 'Create a demo role account or join as a new student.'
                    : 'Sign in to access your menu, complaints, and analytics.',
                style: const TextStyle(color: Color(0xFF64748B), height: 1.45),
              ),
              const SizedBox(height: 22),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(value: false, label: Text('Login')),
                  ButtonSegment<bool>(value: true, label: Text('Register')),
                ],
                selected: {registerMode},
                onSelectionChanged: (_) => onToggleMode(),
              ),
              const SizedBox(height: 20),
              if (registerMode) ...[
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'College Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => onSubmit(),
                validator: (value) => value == null || value.length < 6 ? 'Minimum 6 characters' : null,
              ),
              if (registerMode) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: UserRole.values
                      .map(
                        (value) => DropdownMenuItem<UserRole>(
                          value: value,
                          child: Text(value.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onRoleChanged(value);
                  },
                ),
                if (role == UserRole.student) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: departmentCtrl,
                    decoration: const InputDecoration(labelText: 'Department'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: yearCtrl,
                    decoration: const InputDecoration(labelText: 'Year'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: roomCtrl,
                    decoration: const InputDecoration(labelText: 'Room Number'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: blockCtrl,
                    decoration: const InputDecoration(labelText: 'Hostel Block'),
                  ),
                ],
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: busy ? null : onSubmit,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(registerMode ? Icons.app_registration : Icons.login),
                label: Text(registerMode ? 'Create Account' : 'Sign In'),
              ),
              const SizedBox(height: 10),
              Semantics(
                button: true,
                label: 'Continue With Gmail',
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => onGoogleSignIn(),
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Continue With Gmail'),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'Demo accounts: admin@college.edu / admin123, warden@college.edu / warden123, student@college.edu / student123',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeRouter extends StatelessWidget {
  const HomeRouter({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  final MessUser user;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case UserRole.student:
        return StudentHomeScreen(
          user: user,
          onLogout: onLogout,
          onToggleTheme: onToggleTheme,
          isDarkMode: isDarkMode,
        );
      case UserRole.admin:
        return AdminHomeScreen(
          user: user,
          onLogout: onLogout,
          onToggleTheme: onToggleTheme,
          isDarkMode: isDarkMode,
        );
      case UserRole.warden:
        return WardenHomeScreen(
          user: user,
          onLogout: onLogout,
          onToggleTheme: onToggleTheme,
          isDarkMode: isDarkMode,
        );
    }
  }
}

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  final MessUser user;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  bool _loading = true;
  DailyMenu? _todayMenu;
  Map<String, double> _dishAverages = {};
  Map<MealType, MealIntent?> _mealIntents = {};
  List<Suggestion> _suggestions = [];
  List<Complaint> _complaints = [];
  double _weeklyAverage = 0;
  Map<MealType, double> _crowdForecast = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final repo = MessRepository.instance;
    final dateKey = todayKey();
    final results = await Future.wait([
      repo.getMenuForDate(dateKey),
      repo.dishAverages(),
      repo.suggestions(),
      repo.complaintsByUser(widget.user.id),
      repo.weeklyAverage(),
      repo.mealIntentByUser(userId: widget.user.id, dateKey: dateKey, meal: MealType.breakfast),
      repo.mealIntentByUser(userId: widget.user.id, dateKey: dateKey, meal: MealType.lunch),
      repo.mealIntentByUser(userId: widget.user.id, dateKey: dateKey, meal: MealType.dinner),
      repo.crowdForecastRatio(dateKey: dateKey, meal: MealType.breakfast),
      repo.crowdForecastRatio(dateKey: dateKey, meal: MealType.lunch),
      repo.crowdForecastRatio(dateKey: dateKey, meal: MealType.dinner),
    ]);

    if (!mounted) return;
    setState(() {
      _todayMenu = results[0] as DailyMenu;
      _dishAverages = results[1] as Map<String, double>;
      _suggestions = results[2] as List<Suggestion>;
      _complaints = results[3] as List<Complaint>;
      _weeklyAverage = results[4] as double;
      _mealIntents = {
        MealType.breakfast: results[5] as MealIntent?,
        MealType.lunch: results[6] as MealIntent?,
        MealType.dinner: results[7] as MealIntent?,
      };
      _crowdForecast = {
        MealType.breakfast: results[8] as double,
        MealType.lunch: results[9] as double,
        MealType.dinner: results[10] as double,
      };
      _loading = false;
    });
  }

  Future<void> _toggleIntent(MealType meal) async {
    final existing = _mealIntents[meal];
    final result = await showDialog<_IntentChoice>(
      context: context,
      builder: (context) {
        bool willEat = existing?.willEat ?? true;
        final reasonCtrl = TextEditingController(text: existing?.noShowReason ?? '');
        return AlertDialog(
          title: Text('Meal intent for ${mealLabel(meal)}'),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('I will eat this meal'),
                    value: willEat,
                    onChanged: (value) => setLocal(() => willEat = value),
                  ),
                  if (!willEat)
                    TextField(
                      controller: reasonCtrl,
                      decoration: const InputDecoration(labelText: 'Reason / no-show note'),
                      maxLines: 2,
                    ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                _IntentChoice(willEat: willEat, reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim()),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    await MessRepository.instance.upsertMealIntent(
      userId: widget.user.id,
      dateKey: todayKey(),
      meal: meal,
      willEat: result.willEat,
      noShowReason: result.reason,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated ${mealLabel(meal)} intent')),
    );
    await _refresh();
  }

  Future<void> _rateDish(MealType meal, Dish dish) async {
    int stars = 4;
    final reviewCtrl = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Rate ${dish.name}'),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mealLabel(meal)),
                  const SizedBox(height: 12),
                  Slider(
                    value: stars.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$stars stars',
                    onChanged: (value) => setLocal(() => stars = value.round()),
                  ),
                  TextField(
                    controller: reviewCtrl,
                    decoration: const InputDecoration(labelText: 'Short review (optional)'),
                    maxLines: 2,
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
          ],
        );
      },
    );

    if (accepted != true) return;
    final rating = DishRating(
      id: 'r_${DateTime.now().microsecondsSinceEpoch}',
      userId: widget.user.id,
      dateKey: todayKey(),
      meal: meal,
      dishId: dish.id,
      stars: stars,
      review: reviewCtrl.text.trim().isEmpty ? null : reviewCtrl.text.trim(),
      tags: dish.tags,
      createdAt: DateTime.now(),
    );
    final ok = await MessRepository.instance.submitRating(rating);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Thanks for the rating' : 'You already rated this dish')),
    );
    await _refresh();
  }

  Future<void> _addComplaint() async {
    final categoryCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final dishCtrl = TextEditingController();
    ComplaintSeverity severity = ComplaintSeverity.medium;
    MealType? meal;
    bool anonymous = false;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Raise complaint'),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<MealType?>(
                      initialValue: meal,
                      decoration: const InputDecoration(labelText: 'Meal (optional)'),
                      items: [
                        const DropdownMenuItem<MealType?>(value: null, child: Text('Any meal')),
                        ...MealType.values.map(
                          (value) => DropdownMenuItem<MealType?>(value: value, child: Text(mealLabel(value))),
                        ),
                      ],
                      onChanged: (value) => setLocal(() => meal = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: dishCtrl, decoration: const InputDecoration(labelText: 'Dish (optional)')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ComplaintSeverity>(
                      initialValue: severity,
                      decoration: const InputDecoration(labelText: 'Severity'),
                      items: ComplaintSeverity.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setLocal(() => severity = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 4,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Anonymous'),
                      value: anonymous,
                      onChanged: (value) => setLocal(() => anonymous = value),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
          ],
        );
      },
    );

    if (accepted != true) return;
    if (categoryCtrl.text.trim().isEmpty || descriptionCtrl.text.trim().isEmpty) return;

    await MessRepository.instance.addComplaint(
      Complaint(
        id: 'c_${DateTime.now().microsecondsSinceEpoch}',
        userId: widget.user.id,
        dateKey: todayKey(),
        meal: meal,
        dishName: dishCtrl.text.trim().isEmpty ? null : dishCtrl.text.trim(),
        category: categoryCtrl.text.trim(),
        description: descriptionCtrl.text.trim(),
        status: 'Open',
        severity: severity,
        anonymous: anonymous,
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Complaint submitted')),
    );
    await _refresh();
  }

  Future<void> _addSuggestion() async {
    final nameCtrl = TextEditingController();
    MealType? meal = MealType.dinner;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Suggest a dish'),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Dish name')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<MealType?>(
                    initialValue: meal,
                    decoration: const InputDecoration(labelText: 'Preferred meal'),
                    items: MealType.values
                        .map(
                          (value) => DropdownMenuItem<MealType?>(
                            value: value,
                            child: Text(mealLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setLocal(() => meal = value),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
          ],
        );
      },
    );

    if (accepted != true || nameCtrl.text.trim().isEmpty) return;
    await MessRepository.instance.addSuggestion(
      Suggestion(
        id: 's_${DateTime.now().microsecondsSinceEpoch}',
        userId: widget.user.id,
        dishName: nameCtrl.text.trim(),
        votes: 1,
        createdAt: DateTime.now(),
        voterUserIds: [widget.user.id],
        preferredMeal: meal,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suggestion added')),
    );
    await _refresh();
  }

  Future<void> _voteSuggestion(Suggestion suggestion) async {
    final ok = await MessRepository.instance.upvoteSuggestion(
      suggestion.id,
      voterUserId: widget.user.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Vote recorded' : 'You already voted')),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final menu = _todayMenu;
    final forecast = _crowdForecast;
    final menuSummary = menu == null
        ? 'Loading today\'s menu'
        : menu.isHoliday
            ? 'Holiday menu'
            : 'Serving today';

    return _DashboardScaffold(
      user: widget.user,
      onLogout: widget.onLogout,
      onToggleTheme: widget.onToggleTheme,
      isDarkMode: widget.isDarkMode,
      title: 'Student dashboard',
      subtitle: 'Plan your meals, rate dishes, and track crowd intent in one place.',
      topStatCards: [
        _StatCard(label: 'Weekly avg', value: _weeklyAverage == 0 ? '--' : _weeklyAverage.toStringAsFixed(1), icon: Icons.star_rounded),
        _StatCard(label: 'Complaints', value: '${_complaints.length}', icon: Icons.report_problem_rounded),
        _StatCard(label: 'Suggestions', value: '${_suggestions.length}', icon: Icons.lightbulb_rounded),
        _StatCard(label: 'Intent updated', value: _mealIntents.values.any((value) => value != null) ? 'Yes' : 'No', icon: Icons.check_circle_rounded),
      ],
      body: _loading || menu == null
          ? const _SectionLoading()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BannerCard(
                  title: DateFormat('EEEE, dd MMM').format(DateTime.parse(todayKey())),
                  subtitle: menuSummary,
                  chips: [
                    _InfoChip(label: crowdLabel(forecast[MealType.breakfast] ?? 0), value: '${((forecast[MealType.breakfast] ?? 0) * 100).round()}% breakfast'),
                    _InfoChip(label: crowdLabel(forecast[MealType.lunch] ?? 0), value: '${((forecast[MealType.lunch] ?? 0) * 100).round()}% lunch'),
                    _InfoChip(label: crowdLabel(forecast[MealType.dinner] ?? 0), value: '${((forecast[MealType.dinner] ?? 0) * 100).round()}% dinner'),
                  ],
                  actions: [
                    FilledButton.icon(
                      onPressed: _addSuggestion,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Suggest dish'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _addComplaint,
                      icon: const Icon(Icons.report_problem_outlined),
                      label: const Text('Raise complaint'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Quick cloud actions',
                  subtitle: 'Request additional food, check your bills, and send messages.',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => StudentExtraFoodPage(user: widget.user)),
                          );
                        },
                        icon: const Icon(Icons.fastfood_outlined),
                        label: const Text('Additional Food Form'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => StudentBillsPage(user: widget.user)),
                          );
                        },
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Monthly Bills'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => StudentMessagesPage(user: widget.user)),
                          );
                        },
                        icon: const Icon(Icons.mark_email_read_outlined),
                        label: const Text('Messages & Mail'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Today\'s menu',
                  subtitle: 'Tap any dish to rate it. Submit meal intent so the kitchen can forecast crowd load.',
                  child: Column(
                    children: MealType.values.map((meal) {
                      final dishes = menu.dishesFor(meal);
                      final intent = _mealIntents[meal];
                      return Padding(
                        padding: EdgeInsets.only(bottom: meal == MealType.dinner ? 0 : 16),
                        child: _MealBlock(
                          meal: meal,
                          dishes: dishes,
                          intent: intent,
                          avgRatings: _dishAverages,
                          onRateDish: (dish) => _rateDish(meal, dish),
                          onSetIntent: () => _toggleIntent(meal),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    final left = _SectionCard(
                      title: 'Your current intent',
                      subtitle: 'What the kitchen sees for crowd planning today.',
                      child: Column(
                        children: MealType.values.map((meal) {
                          final intent = _mealIntents[meal];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _IntentSummaryTile(meal: meal, intent: intent, onTap: () => _toggleIntent(meal)),
                          );
                        }).toList(),
                      ),
                    );

                    final right = _SectionCard(
                      title: 'Suggestions board',
                      subtitle: 'Upvote dishes you want the mess team to consider.',
                      child: Column(
                        children: _suggestions.isEmpty
                            ? [const _EmptyState(message: 'No suggestions yet. Add the first one.')] 
                            : _suggestions
                                .map(
                                  (suggestion) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _SuggestionTile(
                                      suggestion: suggestion,
                                      canVote: !suggestion.voterUserIds.contains(widget.user.id),
                                      onVote: () => _voteSuggestion(suggestion),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    );

                    if (!wide) {
                      return Column(
                        children: [left, const SizedBox(height: 18), right],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 18),
                        Expanded(child: right),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  final MessUser user;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _loading = true;
  DailyMenu? _todayMenu;
  Map<String, double> _dishAverages = {};
  List<Complaint> _complaints = [];
  List<Suggestion> _suggestions = [];
  List<MapEntry<String, double>> _timeline = const [];
  double _weeklyAverage = 0;
  Map<String, int> _complaintCounts = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final repo = MessRepository.instance;
    final dateKey = todayKey();
    final results = await Future.wait([
      repo.getMenuForDate(dateKey),
      repo.dishAverages(),
      repo.complaints(),
      repo.suggestions(),
      repo.weeklyAverage(),
      repo.dailyAverageTimeline(),
      repo.topComplaintCategories(),
    ]);

    if (!mounted) return;
    setState(() {
      _todayMenu = results[0] as DailyMenu;
      _dishAverages = results[1] as Map<String, double>;
      _complaints = results[2] as List<Complaint>;
      _suggestions = results[3] as List<Suggestion>;
      _weeklyAverage = results[4] as double;
      _timeline = results[5] as List<MapEntry<String, double>>;
      _complaintCounts = results[6] as Map<String, int>;
      _loading = false;
    });
  }

  Future<void> _openMenuEditor() async {
    final menu = _todayMenu ?? await MessRepository.instance.getMenuForDate(todayKey());
    if (!mounted) return;
    final breakfastCtrl = TextEditingController(text: menu.breakfast.map((d) => d.name).join('\n'));
    final lunchCtrl = TextEditingController(text: menu.lunch.map((d) => d.name).join('\n'));
    final dinnerCtrl = TextEditingController(text: menu.dinner.map((d) => d.name).join('\n'));
    final holiday = ValueNotifier<bool>(menu.isHoliday);

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit today\'s menu'),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Holiday menu'),
                      value: holiday.value,
                      onChanged: (value) => setLocal(() => holiday.value = value),
                    ),
                    TextField(
                      controller: breakfastCtrl,
                      decoration: const InputDecoration(labelText: 'Breakfast items', hintText: 'One item per line'),
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lunchCtrl,
                      decoration: const InputDecoration(labelText: 'Lunch items', hintText: 'One item per line'),
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dinnerCtrl,
                      decoration: const InputDecoration(labelText: 'Dinner items', hintText: 'One item per line'),
                      minLines: 3,
                      maxLines: 5,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        );
      },
    );

    if (accepted != true) return;
    final today = todayKey();
    await MessRepository.instance.saveMenu(
      DailyMenu(
        dateKey: today,
        breakfast: _parseDishList(breakfastCtrl.text),
        lunch: _parseDishList(lunchCtrl.text),
        dinner: _parseDishList(dinnerCtrl.text),
        isHoliday: holiday.value,
        updatedAt: DateTime.now(),
        publishedBy: widget.user.id,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu saved')));
    await _refresh();
  }

  Future<void> _copyPrevious() async {
    final ok = await MessRepository.instance.copyPreviousDayMenu(todayKey(), widget.user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Previous menu copied' : 'No previous menu found')),
    );
    await _refresh();
  }

  Future<void> _updateComplaintStatus(Complaint complaint, String status) async {
    await MessRepository.instance.updateComplaintStatus(
      complaint.id,
      status,
      assignedTo: widget.user.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Complaint marked $status')));
    await _refresh();
  }

  Future<void> _acceptSuggestion(Suggestion suggestion) async {
    await MessRepository.instance.acceptSuggestion(suggestion.id, adminUserId: widget.user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suggestion accepted')));
    await _refresh();
  }

  Future<void> _scheduleSuggestion(Suggestion suggestion) async {
    final controller = TextEditingController(text: todayKey());
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Schedule ${suggestion.dishName}'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Date key (YYYY-MM-DD)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Schedule')),
          ],
        );
      },
    );

    if (selected == null || selected.isEmpty) return;
    await MessRepository.instance.scheduleSuggestion(
      suggestion.id,
      selected,
      adminUserId: widget.user.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suggestion scheduled')));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final menu = _todayMenu;
    return _DashboardScaffold(
      user: widget.user,
      onLogout: widget.onLogout,
      onToggleTheme: widget.onToggleTheme,
      isDarkMode: widget.isDarkMode,
      title: 'Admin control room',
      subtitle: 'Publish the menu, handle complaints, and decide what gets cooked next.',
      topStatCards: [
        _StatCard(label: 'Weekly avg', value: _weeklyAverage == 0 ? '--' : _weeklyAverage.toStringAsFixed(1), icon: Icons.insights_rounded),
        _StatCard(label: 'Complaints', value: '${_complaints.length}', icon: Icons.report_gmailerrorred_rounded),
        _StatCard(label: 'Suggestions', value: '${_suggestions.length}', icon: Icons.lightbulb_rounded),
        _StatCard(label: 'Open queues', value: '${_complaints.where((item) => item.status != 'Resolved').length}', icon: Icons.pending_actions_rounded),
      ],
      body: _loading || menu == null
          ? const _SectionLoading()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BannerCard(
                  title: 'Today\'s publishing desk',
                  subtitle: 'Versioned menu updates, complaint SLAs, and suggestion decisions in one dashboard.',
                  chips: [
                    _InfoChip(label: 'Average taste ${_weeklyAverage == 0 ? '--' : _weeklyAverage.toStringAsFixed(1)}', value: 'weekly'),
                    _InfoChip(label: 'Breakfast ${menu.breakfast.length} items', value: 'live'),
                    _InfoChip(label: 'Lunch ${menu.lunch.length} items', value: 'live'),
                    _InfoChip(label: 'Dinner ${menu.dinner.length} items', value: 'live'),
                  ],
                  actions: [
                    FilledButton.icon(
                      onPressed: _openMenuEditor,
                      icon: const Icon(Icons.edit_calendar_outlined),
                      label: const Text('Edit menu'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _copyPrevious,
                      icon: const Icon(Icons.copy_all_outlined),
                      label: const Text('Copy previous day'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Cloud workflow center',
                  subtitle: 'Approve requests, control billing, configure deadlines, and send announcements.',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AdminApprovalsPage(user: widget.user)),
                          );
                        },
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Approve Requests'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminBillingPage()),
                          );
                        },
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Billing Center'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminDeadlinesPage()),
                          );
                        },
                        icon: const Icon(Icons.schedule_outlined),
                        label: const Text('Deadline Settings'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AdminMessagingPage(user: widget.user)),
                          );
                        },
                        icon: const Icon(Icons.campaign_outlined),
                        label: const Text('Messaging & Mail'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final left = _SectionCard(
                      title: 'Menu snapshot',
                      subtitle: 'Current dishes and live dish averages.',
                      child: Column(
                        children: MealType.values.map((meal) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: meal == MealType.dinner ? 0 : 12),
                            child: _MealBlock(
                              meal: meal,
                              dishes: menu.dishesFor(meal),
                              intent: null,
                              avgRatings: _dishAverages,
                              onRateDish: (_) {},
                              onSetIntent: null,
                              showActions: false,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                    final right = _SectionCard(
                      title: 'Complaint queue',
                      subtitle: 'Resolve issues fast and keep track of aging tickets.',
                      child: Column(
                        children: _complaints.isEmpty
                            ? [const _EmptyState(message: 'No complaints logged yet.')] 
                            : _complaints
                                .map(
                                  (complaint) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _ComplaintTile(
                                      complaint: complaint,
                                      onStatusChange: (status) => _updateComplaintStatus(complaint, status),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    );

                    if (!wide) {
                      return Column(
                        children: [left, const SizedBox(height: 18), right],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 18),
                        Expanded(child: right),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final suggestionsCard = _SectionCard(
                      title: 'Suggestions board',
                      subtitle: 'Votes and scheduling requests from students.',
                      child: Column(
                        children: _suggestions.isEmpty
                            ? [const _EmptyState(message: 'No suggestions yet.')] 
                            : _suggestions
                                .map(
                                  (suggestion) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _AdminSuggestionTile(
                                      suggestion: suggestion,
                                      onAccept: () => _acceptSuggestion(suggestion),
                                      onSchedule: () => _scheduleSuggestion(suggestion),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    );
                    final analyticsCard = _SectionCard(
                      title: 'Operational analytics',
                      subtitle: 'Recent trend and issue categories.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 180,
                            child: CustomPaint(
                              painter: _TrendPainter(_timeline),
                              child: const SizedBox.expand(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _complaintCounts.isEmpty
                                ? [const _EmptyState(message: 'No complaint categories yet.')] 
                                : _complaintCounts.entries
                                    .map(
                                      (entry) => Chip(
                                        label: Text('${entry.key}: ${entry.value}'),
                                        backgroundColor: const Color(0xFFEFF6FF),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    );

                    if (!wide) {
                      return Column(
                        children: [suggestionsCard, const SizedBox(height: 18), analyticsCard],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: suggestionsCard),
                        const SizedBox(width: 18),
                        Expanded(child: analyticsCard),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class WardenHomeScreen extends StatefulWidget {
  const WardenHomeScreen({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  final MessUser user;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  @override
  State<WardenHomeScreen> createState() => _WardenHomeScreenState();
}

class _WardenHomeScreenState extends State<WardenHomeScreen> {
  bool _loading = true;
  DailyMenu? _todayMenu;
  List<Complaint> _complaints = [];
  List<Complaint> _overdue = [];
  Map<String, int> _complaintCounts = {};
  Map<MealType, double> _crowdForecast = {};
  double _weeklyAverage = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final repo = MessRepository.instance;
    final dateKey = todayKey();
    final results = await Future.wait([
      repo.getMenuForDate(dateKey),
      repo.complaints(),
      repo.overdueComplaints(),
      repo.topComplaintCategories(),
      repo.crowdForecastRatio(dateKey: dateKey, meal: MealType.breakfast),
      repo.crowdForecastRatio(dateKey: dateKey, meal: MealType.lunch),
      repo.crowdForecastRatio(dateKey: dateKey, meal: MealType.dinner),
      repo.weeklyAverage(),
    ]);

    if (!mounted) return;
    setState(() {
      _todayMenu = results[0] as DailyMenu;
      _complaints = results[1] as List<Complaint>;
      _overdue = results[2] as List<Complaint>;
      _complaintCounts = results[3] as Map<String, int>;
      _crowdForecast = {
        MealType.breakfast: results[4] as double,
        MealType.lunch: results[5] as double,
        MealType.dinner: results[6] as double,
      };
      _weeklyAverage = results[7] as double;
      _loading = false;
    });
  }

  Future<void> _markResolved(Complaint complaint) async {
    await MessRepository.instance.updateComplaintStatus(
      complaint.id,
      'Resolved',
      assignedTo: widget.user.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint resolved')));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final menu = _todayMenu;
    return _DashboardScaffold(
      user: widget.user,
      onLogout: widget.onLogout,
      onToggleTheme: widget.onToggleTheme,
      isDarkMode: widget.isDarkMode,
      title: 'Warden oversight',
      subtitle: 'Track crowd pressure, complaint age, and food quality from a single operations view.',
      topStatCards: [
        _StatCard(label: 'Weekly avg', value: _weeklyAverage == 0 ? '--' : _weeklyAverage.toStringAsFixed(1), icon: Icons.star_rounded),
        _StatCard(label: 'Total complaints', value: '${_complaints.length}', icon: Icons.inbox_rounded),
        _StatCard(label: 'Overdue', value: '${_overdue.length}', icon: Icons.timer_off_rounded),
        _StatCard(label: 'High pressure', value: '${_crowdForecast.values.where((value) => value >= 0.7).length}', icon: Icons.local_fire_department_rounded),
      ],
      body: _loading || menu == null
          ? const _SectionLoading()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BannerCard(
                  title: 'Operational overview',
                  subtitle: 'Complaint queue, crowd forecast, and menu readiness at a glance.',
                  chips: [
                    _InfoChip(label: crowdLabel(_crowdForecast[MealType.breakfast] ?? 0), value: 'breakfast'),
                    _InfoChip(label: crowdLabel(_crowdForecast[MealType.lunch] ?? 0), value: 'lunch'),
                    _InfoChip(label: crowdLabel(_crowdForecast[MealType.dinner] ?? 0), value: 'dinner'),
                  ],
                  actions: [
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final left = _SectionCard(
                      title: 'Crowd forecast',
                      subtitle: 'This is derived from student meal intent responses.',
                      child: Column(
                        children: MealType.values
                            .map(
                              (meal) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ForecastTile(
                                  meal: meal,
                                  ratio: _crowdForecast[meal] ?? 0,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    );
                    final right = _SectionCard(
                      title: 'Complaint triage',
                      subtitle: 'Resolve aging issues first.',
                      child: Column(
                        children: _overdue.isEmpty
                            ? [const _EmptyState(message: 'No overdue complaints.')] 
                            : _overdue
                                .map(
                                  (complaint) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _ComplaintTile(
                                      complaint: complaint,
                                      emphasizeOverdue: true,
                                      onStatusChange: complaint.status == 'Resolved' ? null : (_) => _markResolved(complaint),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    );
                    if (!wide) {
                      return Column(
                        children: [left, const SizedBox(height: 18), right],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 18),
                        Expanded(child: right),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final complaintsCard = _SectionCard(
                      title: 'Complaint categories',
                      subtitle: 'What is causing friction most often.',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _complaintCounts.isEmpty
                            ? [const _EmptyState(message: 'No categories recorded yet.')] 
                            : _complaintCounts.entries
                                .map(
                                  (entry) => Chip(
                                    label: Text('${entry.key}: ${entry.value}'),
                                    backgroundColor: const Color(0xFFFFF7ED),
                                  ),
                                )
                                .toList(),
                      ),
                    );
                    final menuCard = _SectionCard(
                      title: 'Today\'s menu readiness',
                      subtitle: 'Current published dishes and average dish ratings.',
                      child: Column(
                        children: MealType.values
                            .map(
                              (meal) => Padding(
                                padding: EdgeInsets.only(bottom: meal == MealType.dinner ? 0 : 12),
                                child: _MealBlock(
                                  meal: meal,
                                  dishes: menu.dishesFor(meal),
                                  intent: null,
                                  avgRatings: const {},
                                  onRateDish: (_) {},
                                  onSetIntent: null,
                                  showActions: false,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    );

                    if (!wide) {
                      return Column(
                        children: [complaintsCard, const SizedBox(height: 18), menuCard],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: complaintsCard),
                        const SizedBox(width: 18),
                        Expanded(child: menuCard),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _DashboardScaffold extends StatelessWidget {
  const _DashboardScaffold({
    required this.user,
    required this.onLogout,
    required this.onToggleTheme,
    required this.isDarkMode,
    required this.title,
    required this.subtitle,
    required this.topStatCards,
    required this.body,
  });

  final MessUser user;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final String title;
  final String subtitle;
  final List<_StatCard> topStatCards;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F7FB), Color(0xFFE8F1F8)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _HeaderBar(
                user: user,
                title: title,
                subtitle: subtitle,
                onLogout: onLogout,
                onToggleTheme: onToggleTheme,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 860;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: topStatCards
                        .map(
                          (card) => SizedBox(
                            width: wide ? (constraints.maxWidth - 42) / 4 : (constraints.maxWidth - 14) / 2,
                            child: card,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.user,
    required this.title,
    required this.subtitle,
    required this.onLogout,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  final MessUser user;
  final String title;
  final String subtitle;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 860;
          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  user.role.name.toUpperCase(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF64748B), height: 1.45),
              ),
            ],
          );

          final right = Column(
            crossAxisAlignment: wide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                user.email,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onToggleTheme,
                icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                label: Text(isDarkMode ? 'Light mode' : 'Dark mode'),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [left, const SizedBox(height: 18), right],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 18),
              right,
            ],
          );
        },
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final List<Widget> chips;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2545), Color(0xFF123B63)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 860;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.restaurant_menu, color: Colors.white, size: 44),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 18),
              Wrap(spacing: 10, runSpacing: 10, children: chips),
              const SizedBox(height: 18),
              Wrap(spacing: 12, runSpacing: 12, children: actions),
            ],
          );

          if (!wide) {
            return content;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: content),
              const SizedBox(width: 18),
              const SizedBox(
                width: 180,
                child: _HeroSideCard(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroSideCard extends StatelessWidget {
  const _HeroSideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live control', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Fast updates, clear queues, and role-based actions.', style: TextStyle(color: Colors.white70, height: 1.45)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF0C4A6E)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), height: 1.45)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MealBlock extends StatelessWidget {
  const _MealBlock({
    required this.meal,
    required this.dishes,
    required this.intent,
    required this.avgRatings,
    required this.onRateDish,
    required this.onSetIntent,
    this.showActions = true,
  });

  final MealType meal;
  final List<Dish> dishes;
  final MealIntent? intent;
  final Map<String, double> avgRatings;
  final ValueChanged<Dish> onRateDish;
  final VoidCallback? onSetIntent;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final currentIntent = intent;
    final forecastValue = currentIntent == null ? null : (currentIntent.willEat ? 'Planning to eat' : 'No-show note');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _mealColor(meal).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_mealIcon(meal), color: _mealColor(meal)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mealLabel(meal), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    if (forecastValue != null)
                      Text(
                        forecastValue,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                      ),
                  ],
                ),
              ),
              if (showActions && onSetIntent != null)
                TextButton.icon(
                  onPressed: onSetIntent,
                  icon: const Icon(Icons.checklist, size: 18),
                  label: const Text('Intent'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (dishes.isEmpty)
            const _EmptyState(message: 'No items published for this meal.')
          else
            Column(
              children: dishes.map((dish) {
                final average = avgRatings[dish.id];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: showActions ? () => onRateDish(dish) : null,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  dish.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                                ),
                              ),
                              if (average != null && average > 0)
                                _MiniBadge(label: average.toStringAsFixed(1)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (dish.isVeg) const _MiniBadge(label: 'Veg'),
                              if (dish.containsEgg) const _MiniBadge(label: 'Egg'),
                              if (dish.containsNuts) const _MiniBadge(label: 'Nuts'),
                              if (dish.calories != null) _MiniBadge(label: '${dish.calories} kcal'),
                              if (dish.prepTimeMinutes != null) _MiniBadge(label: '${dish.prepTimeMinutes} min'),
                              if (dish.spiceLevel > 1) _MiniBadge(label: 'Spice ${dish.spiceLevel}'),
                            ],
                          ),
                          if (showActions) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.tonalIcon(
                                onPressed: () => onRateDish(dish),
                                icon: const Icon(Icons.star_outline, size: 18),
                                label: const Text('Rate'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _IntentSummaryTile extends StatelessWidget {
  const _IntentSummaryTile({required this.meal, required this.intent, required this.onTap});

  final MealType meal;
  final MealIntent? intent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final planned = intent?.willEat == true;
    final label = intent == null ? 'Not set' : planned ? 'Will eat' : 'Will skip';
    final color = intent == null
        ? const Color(0xFF94A3B8)
        : planned
            ? const Color(0xFF15803D)
            : const Color(0xFFB45309);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: const Color(0xFFF8FAFC),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(_mealIcon(meal), color: color),
      ),
      title: Text(mealLabel(meal), style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(intent?.noShowReason ?? 'Tap to update meal intent'),
      trailing: _MiniBadge(label: label),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion, required this.canVote, required this.onVote});

  final Suggestion suggestion;
  final bool canVote;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEAF2FF),
            child: Text('${suggestion.votes}'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suggestion.dishName, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  suggestion.preferredMeal == null ? 'Any meal' : 'Preferred: ${mealLabel(suggestion.preferredMeal!)}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: canVote ? onVote : null,
            icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
            label: const Text('Vote'),
          ),
        ],
      ),
    );
  }
}

class _AdminSuggestionTile extends StatelessWidget {
  const _AdminSuggestionTile({required this.suggestion, required this.onAccept, required this.onSchedule});

  final Suggestion suggestion;
  final VoidCallback onAccept;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: suggestion.accepted ? const Color(0xFFDCFCE7) : const Color(0xFFEAF2FF),
            child: Text('${suggestion.votes}'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suggestion.dishName, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  suggestion.status.name.toUpperCase(),
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(onPressed: onSchedule, child: const Text('Schedule')),
              FilledButton(onPressed: onAccept, child: const Text('Accept')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComplaintTile extends StatelessWidget {
  const _ComplaintTile({
    required this.complaint,
    required this.onStatusChange,
    this.emphasizeOverdue = false,
  });

  final Complaint complaint;
  final ValueChanged<String>? onStatusChange;
  final bool emphasizeOverdue;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(complaint.status);
    final severityColor = _severityColor(complaint.severity);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: emphasizeOverdue ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.report_problem_outlined, color: severityColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(complaint.category, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(complaint.description, style: const TextStyle(color: Color(0xFF475569), height: 1.4)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: onStatusChange,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'Open', child: Text('Open')),
                  PopupMenuItem(value: 'In Progress', child: Text('In Progress')),
                  PopupMenuItem(value: 'Resolved', child: Text('Resolved')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(label: complaint.severity.name.toUpperCase(), color: severityColor),
              _MiniBadge(label: complaint.status, color: statusColor),
              if (complaint.meal != null) _MiniBadge(label: mealLabel(complaint.meal!)),
              if (complaint.dishName != null) _MiniBadge(label: complaint.dishName!),
              if (complaint.anonymous) const _MiniBadge(label: 'Anonymous'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForecastTile extends StatelessWidget {
  const _ForecastTile({required this.meal, required this.ratio});

  final MealType meal;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final percent = (ratio * 100).clamp(0, 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _mealColor(meal).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_mealIcon(meal), color: _mealColor(meal)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mealLabel(meal), style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(crowdLabel(ratio), style: const TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          ),
          _MiniBadge(label: '$percent%'),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        '$value • $label',
        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, this.color = const Color(0xFF0C4A6E)});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF64748B))),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}

class _IntentChoice {
  const _IntentChoice({required this.willEat, required this.reason});

  final bool willEat;
  final String? reason;
}

Color _mealColor(MealType meal) {
  switch (meal) {
    case MealType.breakfast:
      return const Color(0xFF0EA5E9);
    case MealType.lunch:
      return const Color(0xFF0C4A6E);
    case MealType.dinner:
      return const Color(0xFFF59E0B);
  }
}

IconData _mealIcon(MealType meal) {
  switch (meal) {
    case MealType.breakfast:
      return Icons.wb_sunny_outlined;
    case MealType.lunch:
      return Icons.lunch_dining_outlined;
    case MealType.dinner:
      return Icons.nightlight_round_outlined;
  }
}

Color _severityColor(ComplaintSeverity severity) {
  switch (severity) {
    case ComplaintSeverity.low:
      return const Color(0xFF15803D);
    case ComplaintSeverity.medium:
      return const Color(0xFFF59E0B);
    case ComplaintSeverity.high:
      return const Color(0xFFEA580C);
    case ComplaintSeverity.critical:
      return const Color(0xFFDC2626);
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'resolved':
      return const Color(0xFF15803D);
    case 'in progress':
      return const Color(0xFF0EA5E9);
    case 'open':
      return const Color(0xFFF59E0B);
    default:
      return const Color(0xFF64748B);
  }
}

List<Dish> _parseDishList(String text) {
  final names = text
      .split(RegExp(r'[\n,]'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  return names
      .asMap()
      .entries
      .map(
        (entry) => Dish(
          id: 'd_${entry.key}_${DateTime.now().microsecondsSinceEpoch}',
          name: entry.value,
          isVeg: true,
          tags: const ['custom'],
        ),
      )
      .toList();
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.points);

  final List<MapEntry<String, double>> points;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = const Color(0xFF0C4A6E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x4D0C4A6E), Color(0x000C4A6E)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;
    final maxValue = math.max(5, points.map((e) => e.value).fold<double>(0, math.max));
    final dx = points.length == 1 ? 0.0 : size.width / (points.length - 1);
    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < points.length; i++) {
      final x = dx * i.toDouble();
      final y = size.height - (points[i].value / maxValue * (size.height - 16)) - 8;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (var i = 0; i < points.length; i++) {
      final x = dx * i;
      final y = size.height - (points[i].value / maxValue * (size.height - 16)) - 8;
      canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = const Color(0xFF0C4A6E));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => oldDelegate.points != points;
}
