import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'mess_cloud_models.dart';
import 'mess_cloud_service.dart';
import 'mess_models.dart';

class StudentExtraFoodPage extends StatefulWidget {
  const StudentExtraFoodPage({super.key, required this.user});

  final MessUser user;

  @override
  State<StudentExtraFoodPage> createState() => _StudentExtraFoodPageState();
}

class _StudentExtraFoodPageState extends State<StudentExtraFoodPage> {
  final MessCloudService _cloud = MessCloudService.instance;
  bool _windowOpen = true;

  @override
  void initState() {
    super.initState();
    _checkWindow();
  }

  Future<void> _checkWindow() async {
    final open = await _cloud.canStudentRequestNow();
    if (!mounted) return;
    setState(() => _windowOpen = open);
  }

  Future<void> _openRequestSheet() async {
    final dishCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final quantityCtrl = TextEditingController(text: '1');
    final feeCtrl = TextEditingController(text: '80');

    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Additional Food Form',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dishCtrl,
                decoration: const InputDecoration(labelText: 'Dish name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: feeCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Est. Fee (Rs)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.send),
                label: const Text('Submit Request'),
              ),
            ],
          ),
        );
      },
    );

    if (accepted != true) return;

    try {
      await _cloud.submitAdditionalFoodRequest(
        student: widget.user,
        dishName: dishCtrl.text.trim(),
        reason: reasonCtrl.text.trim(),
        quantity: int.tryParse(quantityCtrl.text.trim()) ?? 1,
        estimatedFee: double.tryParse(feeCtrl.text.trim()) ?? 0,
        targetDateKey: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted for admin approval')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to submit: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Additional Food Requests')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _windowOpen ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _windowOpen
                  ? 'Request window is open. Use the form sheet to request additional food.'
                  : 'Request window is closed for today. Try tomorrow before cutoff.',
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AdditionalFoodRequest>>(
              stream: _cloud.studentRequestsStream(widget.user.id),
              builder: (context, snapshot) {
                final requests = snapshot.data ?? const <AdditionalFoodRequest>[];
                if (requests.isEmpty) {
                  return const Center(child: Text('No requests yet.'));
                }
                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return ListTile(
                      title: Text('${request.dishName} x${request.quantity}'),
                      subtitle: Text('${request.status.name.toUpperCase()} • Rs.${request.estimatedFee.toStringAsFixed(0)}'),
                      trailing: Text(DateFormat('dd MMM').format(request.createdAt)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _windowOpen ? _openRequestSheet : null,
        icon: const Icon(Icons.description_outlined),
        label: const Text('Open Form Sheet'),
      ),
    );
  }
}

class StudentBillsPage extends StatelessWidget {
  const StudentBillsPage({super.key, required this.user});

  final MessUser user;

  @override
  Widget build(BuildContext context) {
    final cloud = MessCloudService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Mess Bill')),
      body: StreamBuilder<List<MonthlyMessBill>>(
        stream: cloud.studentBillsStream(user.id),
        builder: (context, snapshot) {
          final bills = snapshot.data ?? const <MonthlyMessBill>[];
          if (bills.isEmpty) {
            return const Center(child: Text('No bills generated yet.'));
          }

          return ListView.builder(
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              final dueText = DateFormat('dd MMM yyyy').format(bill.dueDate);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Month ${bill.monthKey}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text('Base: Rs.${bill.baseAmount.toStringAsFixed(0)}'),
                      Text('Additional: Rs.${bill.additionalAmount.toStringAsFixed(0)}'),
                      Text('Penalty: Rs.${bill.penaltyAmount.toStringAsFixed(0)}'),
                      Text('Paid: Rs.${bill.totalPaid.toStringAsFixed(0)}'),
                      Text('Balance: Rs.${bill.balance.toStringAsFixed(0)}'),
                      Text('Due date: $dueText'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [
                          Chip(label: Text(bill.status.name.toUpperCase())),
                          FilledButton(
                            onPressed: bill.balance > 0
                                ? () async {
                                    await cloud.markBillPaid(bill: bill, amount: bill.balance);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Payment marked as completed')),
                                    );
                                  }
                                : null,
                            child: const Text('Mark Paid'),
                          ),
                        ],
                      ),
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

class StudentMessagesPage extends StatelessWidget {
  const StudentMessagesPage({super.key, required this.user});

  final MessUser user;

  @override
  Widget build(BuildContext context) {
    final cloud = MessCloudService.instance;
    final subjectCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Messages & Mail')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessAnnouncement>>(
              stream: cloud.announcementsStream(role: user.role),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <MessAnnouncement>[];
                if (messages.isEmpty) {
                  return const Center(child: Text('No announcements yet.'));
                }
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ListTile(
                      title: Text(message.title),
                      subtitle: Text(message.body),
                      trailing: Text(DateFormat('dd MMM').format(message.createdAt)),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'Mail subject to admin')),
                const SizedBox(height: 8),
                TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Mail body'), maxLines: 2),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    await cloud.queueEmail(
                      to: 'mess-admin@college.edu',
                      subject: subjectCtrl.text.trim().isEmpty ? 'Student Query' : subjectCtrl.text.trim(),
                      body: bodyCtrl.text.trim().isEmpty ? 'Please assist.' : bodyCtrl.text.trim(),
                      metadata: {'studentId': user.id, 'studentName': user.name},
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mail queued for delivery')),
                    );
                  },
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Send Mail'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminApprovalsPage extends StatelessWidget {
  const AdminApprovalsPage({super.key, required this.user});

  final MessUser user;

  @override
  Widget build(BuildContext context) {
    final cloud = MessCloudService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Approve Additional Requests')),
      body: StreamBuilder<List<AdditionalFoodRequest>>(
        stream: cloud.pendingRequestsStream(),
        builder: (context, snapshot) {
          final requests = snapshot.data ?? const <AdditionalFoodRequest>[];
          if (requests.isEmpty) {
            return const Center(child: Text('No pending requests.'));
          }
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${request.studentName} requested ${request.dishName}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(request.reason),
                      const SizedBox(height: 6),
                      Text('Qty ${request.quantity} • Est Rs.${request.estimatedFee.toStringAsFixed(0)}'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [
                          FilledButton(
                            onPressed: () async {
                              await cloud.approveRequest(
                                request: request,
                                adminId: user.id,
                                approvedFee: request.estimatedFee,
                                adminNote: 'Approved by admin',
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Request approved and bill updated')),
                              );
                            },
                            child: const Text('Approve'),
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              await cloud.rejectRequest(
                                requestId: request.id,
                                adminId: user.id,
                                adminNote: 'Not feasible in current cycle',
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Request rejected')),
                              );
                            },
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
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

class AdminBillingPage extends StatelessWidget {
  const AdminBillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cloud = MessCloudService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Billing Control Center')),
      body: StreamBuilder<List<MonthlyMessBill>>(
        stream: cloud.allBillsStream(),
        builder: (context, snapshot) {
          final bills = snapshot.data ?? const <MonthlyMessBill>[];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        await cloud.generateMonthlyBills(baseAmount: 3200);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Monthly bills generated for all students')),
                        );
                      },
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Generate Current Month Bills'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: bills.length,
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    return ListTile(
                      title: Text('${bill.studentName} • ${bill.monthKey}'),
                      subtitle: Text('Balance Rs.${bill.balance.toStringAsFixed(0)}'),
                      trailing: Chip(label: Text(bill.status.name.toUpperCase())),
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

class AdminDeadlinesPage extends StatefulWidget {
  const AdminDeadlinesPage({super.key});

  @override
  State<AdminDeadlinesPage> createState() => _AdminDeadlinesPageState();
}

class _AdminDeadlinesPageState extends State<AdminDeadlinesPage> {
  final cloud = MessCloudService.instance;

  Future<void> _save(FoodWindowConfig config) async {
    await cloud.setFoodWindowConfig(config);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deadline settings updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request/Menu Deadline Settings')),
      body: StreamBuilder<FoodWindowConfig>(
        stream: cloud.foodWindowConfigStream(),
        builder: (context, snapshot) {
          final config = snapshot.data ?? FoodWindowConfig.defaultValue;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Student additional request window enabled'),
                value: config.studentRequestEnabled,
                onChanged: (value) => _save(FoodWindowConfig(
                  studentRequestCutoffHour: config.studentRequestCutoffHour,
                  adminMenuCutoffHour: config.adminMenuCutoffHour,
                  studentRequestEnabled: value,
                  adminMenuEnabled: config.adminMenuEnabled,
                )),
              ),
              ListTile(
                title: const Text('Student request cutoff hour'),
                subtitle: Text('${config.studentRequestCutoffHour}:00'),
                trailing: DropdownButton<int>(
                  value: config.studentRequestCutoffHour,
                  items: List.generate(24, (i) => i)
                      .map((hour) => DropdownMenuItem(value: hour, child: Text(hour.toString())))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _save(FoodWindowConfig(
                      studentRequestCutoffHour: value,
                      adminMenuCutoffHour: config.adminMenuCutoffHour,
                      studentRequestEnabled: config.studentRequestEnabled,
                      adminMenuEnabled: config.adminMenuEnabled,
                    ));
                  },
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Admin menu update window enabled'),
                value: config.adminMenuEnabled,
                onChanged: (value) => _save(FoodWindowConfig(
                  studentRequestCutoffHour: config.studentRequestCutoffHour,
                  adminMenuCutoffHour: config.adminMenuCutoffHour,
                  studentRequestEnabled: config.studentRequestEnabled,
                  adminMenuEnabled: value,
                )),
              ),
              ListTile(
                title: const Text('Admin menu update cutoff hour'),
                subtitle: Text('${config.adminMenuCutoffHour}:00'),
                trailing: DropdownButton<int>(
                  value: config.adminMenuCutoffHour,
                  items: List.generate(24, (i) => i)
                      .map((hour) => DropdownMenuItem(value: hour, child: Text(hour.toString())))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _save(FoodWindowConfig(
                      studentRequestCutoffHour: config.studentRequestCutoffHour,
                      adminMenuCutoffHour: value,
                      studentRequestEnabled: config.studentRequestEnabled,
                      adminMenuEnabled: config.adminMenuEnabled,
                    ));
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

class AdminMessagingPage extends StatelessWidget {
  const AdminMessagingPage({super.key, required this.user});

  final MessUser user;

  @override
  Widget build(BuildContext context) {
    final cloud = MessCloudService.instance;
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Send Message & Mail')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Announcement title')),
            const SizedBox(height: 10),
            TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Announcement body'), maxLines: 4),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    await cloud.postAnnouncement(
                      senderId: user.id,
                      title: titleCtrl.text.trim().isEmpty ? 'Mess update' : titleCtrl.text.trim(),
                      body: bodyCtrl.text.trim().isEmpty ? 'Please check mess dashboard.' : bodyCtrl.text.trim(),
                      target: 'student',
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Announcement posted')),)
                    ;
                  },
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('Send Student Announcement'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await cloud.queueEmail(
                      to: 'hostel-group@college.edu',
                      subject: titleCtrl.text.trim().isEmpty ? 'Mess circular' : titleCtrl.text.trim(),
                      body: bodyCtrl.text.trim().isEmpty ? 'Please check latest update.' : bodyCtrl.text.trim(),
                      metadata: {'sentBy': user.id, 'type': 'adminCircular'},
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mail added to queue')),)
                    ;
                  },
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Queue Mail'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<MessAnnouncement>>(
                stream: cloud.announcementsStream(role: UserRole.admin),
                builder: (context, snapshot) {
                  final messages = snapshot.data ?? const <MessAnnouncement>[];
                  if (messages.isEmpty) return const Center(child: Text('No messages yet.'));
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return ListTile(
                        title: Text(msg.title),
                        subtitle: Text(msg.body),
                        trailing: Text(DateFormat('dd MMM').format(msg.createdAt)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
