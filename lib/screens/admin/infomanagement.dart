import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crownless_app/utils/information.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../utils/color_buttons.dart';
import '../../utils/date_formatter.dart';
import '../../utils/role_formatter.dart';

class ManageNotificationsPage extends StatefulWidget {
  const ManageNotificationsPage({super.key});

  @override
  State<ManageNotificationsPage> createState() => _ManageNotificationsPageState();
}

class _ManageNotificationsPageState extends State<ManageNotificationsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("manage_notifications").tr(),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuCard(
            icon: Icons.notifications_active,
            title: 'send_notification'.tr(),
            subtitle: 'send_notification_desc'.tr(),
            onTap: () => _showSendNotificationDialog(context),
          ),

          _buildMenuCard(
            icon: Icons.history,
            title: 'notification_history'.tr(),
            subtitle: 'notification_history_desc'.tr(),
            onTap: () {
              // TODO: navigate to history page
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showSendNotificationDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    bool sendToAll = true;
    Set<String> selectedUserIds = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('send_notification'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'title'.tr()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bodyController,
                  decoration: InputDecoration(labelText: 'body'.tr()),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: sendToAll,
                      onChanged: (value) => setState(() => sendToAll = value ?? true),
                    ),
                    Expanded(child: const Text('send_to_all_users').tr()),
                  ],
                ),
                if (!sendToAll)
                  ElevatedButton(
                    onPressed: () async => await _selectUsers(
                      context,
                      selectedUserIds,
                      setState,
                    ),
                    child: Text(
                      'select_users_count'
                          .tr(args: [selectedUserIds.length.toString()]),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('cancel').tr(),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final body = bodyController.text.trim();

                if (title.isEmpty || body.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('title_and_body_required'.tr())),
                  );
                  return;
                }

                List<String>? userIds;

                if (!sendToAll) {
                  userIds = selectedUserIds.toList();
                  if (userIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('select_users'.tr())),
                    );
                    return;
                  }
                }

                try {
                  await FirebaseService().sendNotification(
                    title: title,
                    body: body,
                    userIds: userIds,
                  );

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('notification_sent'.tr())),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'notification_failed'
                            .tr(namedArgs: {'error': e.toString()}),
                      ),
                    ),
                  );
                }
              },
              child: const Text('send').tr(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectUsers(
    BuildContext context,
    Set<String> selectedUserIds,
    StateSetter setState,
  ) async {
    final users = await FirebaseService().getAllUsers();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, innerSetState) => AlertDialog(
          title: const Text('select_user').tr(),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final userId = user['id'] as String;

                return CheckboxListTile(
                  title: Text(user['name'] ?? ''),
                  subtitle: Text(user['email'] ?? ''),
                  value: selectedUserIds.contains(userId),
                  onChanged: (value) {
                    innerSetState(() {
                      if (value == true) {
                        selectedUserIds.add(userId);
                      } else {
                        selectedUserIds.remove(userId);
                      }
                    });
                    setState(() {});
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('done').tr(),
            ),
          ],
        ),
      ),
    );
  }
}

class ManageDancersPage extends StatefulWidget {
  const ManageDancersPage({super.key});

  @override
  State<ManageDancersPage> createState() => _ManageDancersPageState();
}

class _ManageDancersPageState extends State<ManageDancersPage> {
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  List<Map<String, dynamic>> _dancers = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _checkAdminRole();
    if (_isAdmin) await _load();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _checkAdminRole() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      _isAdmin = doc.data()?['role'] == 'admin';
    } catch (_) {
      _isAdmin = false;
    }
  }

  int _extractNum(String key) =>
      int.tryParse(key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  Future<void> _load() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('about')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;

    final data = snapshot.docs.first.data();

    final Map<String, dynamic> dancersMap =
        (data['dancers'] as Map<String, dynamic>?) ?? {};

    final keys = dancersMap.keys.toList()
      ..sort((a, b) => _extractNum(a).compareTo(_extractNum(b)));

    _dancers = keys.map((k) {
      final d = dancersMap[k] as Map<String, dynamic>;
      return {
        'name': d['name'] ?? '',
        'role': d['role'] ?? '',
        'mbti': d['mbti'] ?? '',
        'quote': d['quote'] ?? '',
        'image': d['image'] ?? '',
      };
    }).toList();

    _hasChanges = false;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('about')
          .limit(1)
          .get();

      final docRef = snapshot.docs.isNotEmpty
          ? snapshot.docs.first.reference
          : FirebaseFirestore.instance.collection('about').doc();

      final Map<String, dynamic> dancersMap = {};

      for (int i = 0; i < _dancers.length; i++) {
        dancersMap['d${i + 1}'] = {
          'name': _dancers[i]['name'],
          'role': _dancers[i]['role'],
          'mbti': _dancers[i]['mbti'],
          'quote': _dancers[i]['quote'],
          'image': _dancers[i]['image'],
          'order': i + 1,
        };
      }

      await docRef.set({
        'dancers': dancersMap,
      }, SetOptions(merge: true));

      _hasChanges = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dancers saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _add() {
    setState(() {
      _dancers.add({
        'name': '',
        'role': '',
        'mbti': '',
        'quote': '',
        'image': '',
      });
      _hasChanges = true;
    });
  }

  void _delete(int index) {
    setState(() {
      _dancers.removeAt(index);
      _hasChanges = true;
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _dancers.removeAt(oldIndex);
      _dancers.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  Widget _buildAccessDenied() => const Center(
        child: Text('Access Denied'),
      );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Dancers')),
        body: _buildAccessDenied(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Dancers'),
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _dancers.length,
        onReorder: _reorder,
        buildDefaultDragHandles: false,
        itemBuilder: (context, index) {
          final dancer = _dancers[index];

          return Card(
            key: ValueKey(index),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dancer ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _delete(index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    initialValue: dancer['name'],
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      dancer['name'] = v;
                      _hasChanges = true;
                    },
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    initialValue: dancer['role'],
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      dancer['role'] = v;
                      _hasChanges = true;
                    },
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    initialValue: dancer['mbti'],
                    decoration: const InputDecoration(
                      labelText: 'MBTI (optional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      dancer['mbti'] = v;
                      _hasChanges = true;
                    },
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    initialValue: dancer['quote'],
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Quote',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      dancer['quote'] = v;
                      _hasChanges = true;
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 10,
        children: [
          FloatingActionButton(
            heroTag: "add",
            onPressed: _add,
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            heroTag: "save",
            onPressed: _hasChanges ? _save : null,
            child: const Icon(Icons.save),
          ),
        ],
      ),
    );
  }
}

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRoleFilter = 'all';

  static const int _pageSize = 10;
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();
  List<DocumentSnapshot> _loadedDocs = [];
  final FirebaseService _firebaseService = FirebaseService();

  void _showRoleFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('role'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text('all'.tr()),
                    value: 'all',
                    groupValue: _selectedRoleFilter,
                    onChanged: (value) {
                      setState(() {
                        _selectedRoleFilter = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile<String>(
                    title: Text('role_admin'.tr()),
                    value: 'admin',
                    groupValue: _selectedRoleFilter,
                    onChanged: (value) {
                      setState(() {
                        _selectedRoleFilter = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile<String>(
                    title: Text('role_member'.tr()),
                    value: 'member',
                    groupValue: _selectedRoleFilter,
                    onChanged: (value) {
                      setState(() {
                        _selectedRoleFilter = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    if (_lastDocument == null) return;

    setState(() => _isLoadingMore = true);

    final query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .startAfterDocument(_lastDocument!)
        .limit(_pageSize);

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
      _loadedDocs.addAll(snapshot.docs);
    } else {
      _hasMore = false;
    }

    setState(() => _isLoadingMore = false);
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('manageUsers'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showRoleFilterDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'searchUsers'.tr(),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: IconText(
                    leading: Icon(Icons.search_off_outlined, color: Colors.red),
                    text: 'error_with_message'.tr(args: [
                      'error'.tr(),
                      snapshot.error.toString(),
                    ]),
                    textColor: Colors.red,
                  ),
                );
              }

              if (snapshot.data != null && _loadedDocs.isEmpty) {
                _loadedDocs = snapshot.data!.docs.take(_pageSize).toList();
                if (_loadedDocs.isNotEmpty) {
                  _lastDocument = _loadedDocs.last;
                }
              }

              final users = _loadedDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;

              final name = (data['name'] ?? '').toString().toLowerCase();
              final email = (data['email'] ?? '').toString().toLowerCase();
              final role = (data['role'] ?? 'user');

              final matchesSearch = name.contains(_searchQuery) || email.contains(_searchQuery);

              final matchesRole = _selectedRoleFilter == 'all'
                  ? true
                  : role == _selectedRoleFilter;

              return matchesSearch && matchesRole;
            }).toList();

              if (users.isEmpty) {
                return Center(
                  child: IconText(
                    leading: Icon(Icons.search_off_outlined, color: Colors.red),
                    text: 'noMatchingUsers'.tr(),
                    textColor: Colors.red,
                  )
                );
              }

              return ListView.separated(
                controller: _scrollController,
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = users[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final name = data['name'] ?? 'Unknown';
                  final email = data['email'] ?? '';
                  final role = data['role'] ?? 'user';
                  final roleLabel = RoleFormatter.format(role);

                  return ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          backgroundImage: data['photoUrl'] != null
                              ? NetworkImage(data['photoUrl'])
                              : null,
                          child: data['photoUrl'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                      ],
                    ),
                    title: Text(name),
                    subtitle: Text('${'auth.email'.tr()}: $email\n${'role'.tr()}: $roleLabel'),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () => _showUserDetails(context, doc.id, data),
                  );
                },
              );
            },
          ),
          )
        ]
      )
    );
  }

  void _showUserDetails(BuildContext context, String userId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? '';
    final role = data['role'] ?? 'user';
    final createdAt = data['createdAt'] as Timestamp?;

    String selectedRole = role;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('user_details'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10.0,
              children: [
                Text('${'auth.name'.tr()}: $name'),
                Text('${'auth.email'.tr()}: $email'),

                Row(
                  children: [
                    Text('${'role'.tr()}:'),
                    const SizedBox(width: 10),

                    DropdownButton<String>(
                      value: selectedRole,
                      items: [
                        DropdownMenuItem(
                          value: 'member',
                          child: Text('role_member'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('role_admin'.tr()),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
                    )
                  ],
                ),

                Text(
                  '${'created_at'.tr()} ${createdAt != null ? DateFormatter.fullDateTime(context, createdAt.toDate()) : 'N/A'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('close'.tr()),
              ),
              ElevatedButtonVariants.danger(
                onPressed: selectedRole == role
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('confirm'.tr()),
                            content: Text(
                              'confirm_update_role'.tr(args: [selectedRole]),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('cancel'.tr()),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('update_role'.tr()),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await _firebaseService.updateUserRole(
                            userId: userId,
                            role: selectedRole,
                          );

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'role_updated_success'.tr(
                                  args: ['role_$selectedRole'.tr()],
                                ),
                              ),
                            ),
                          );
                        }
                      },
                child: Text('update_role'.tr()),
              ),
              ]      
            )
          );
        },
      );
    }
  }

class PrivacyPolicyAdminPage extends StatefulWidget {
  const PrivacyPolicyAdminPage({super.key});

  @override
  State<PrivacyPolicyAdminPage> createState() => _PrivacyPolicyAdminPageState();
}

class _PrivacyPolicyAdminPageState extends State<PrivacyPolicyAdminPage> with SingleTickerProviderStateMixin {

  static const _langFieldMap = {
    'English': 'privacy-policy-eng',
    'Malay': 'privacy-policy-bm',
    'Chinese': 'privacy-policy-cn',
  };

  static const _tabs = ['English', 'Malay', 'Chinese'];

  late final TabController _tabController;

  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  final Map<String, List<Map<String, Object>>> _data = {
    'English': [],
    'Malay': [],
    'Chinese': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _checkAdminRole();
    if (_isAdmin) await _loadAll();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _checkAdminRole() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      _isAdmin = doc.data()?['role'] == 'admin';
    } catch (_) {
      _isAdmin = false;
    }
  }

  int _extractNum(String key) =>
      int.tryParse(key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  Future<void> _loadAll() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('about')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;

    final raw = snapshot.docs.first.data();

    for (final lang in _tabs) {
      final fieldKey = _langFieldMap[lang]!;
      final Map<String, dynamic> policyMap = (raw[fieldKey] as Map<String, dynamic>?) ?? {};

      final sortedSectionKeys = policyMap.keys.toList()
        ..sort((a, b) => _extractNum(a).compareTo(_extractNum(b)));

      _data[lang] = sortedSectionKeys.map((sKey) {
        final sMap = (policyMap[sKey] as Map<String, dynamic>?) ?? {};
        final contentMap =
            (sMap['content'] as Map<String, dynamic>?) ?? {};

        final sortedContentKeys = contentMap.keys.toList()
          ..sort((a, b) => _extractNum(a).compareTo(_extractNum(b)));

        return <String, Object>{
          'header': sMap['header']?.toString() ?? '',
          'contents': sortedContentKeys
              .map((k) => contentMap[k]?.toString() ?? '')
              .toList(),
        };
      }).toList();
    }

    _hasChanges = false;
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('about')
          .limit(1)
          .get();

      final docRef = snapshot.docs.isNotEmpty
          ? snapshot.docs.first.reference
          : FirebaseFirestore.instance.collection('about').doc();

      final Map<String, dynamic> toSave = {};

      for (final lang in _tabs) {
        final fieldKey = _langFieldMap[lang]!;
        final Map<String, dynamic> sectionsMap = {};

        final sections = _data[lang]!;
        for (int i = 0; i < sections.length; i++) {
          final contents = sections[i]['contents'] as List<String>;
          sectionsMap['section${i + 1}'] = {
            'header': sections[i]['header'],
            'content': {
              for (int j = 0; j < contents.length; j++)
                'c${j + 1}': contents[j],
            },
          };
        }

        toSave[fieldKey] = sectionsMap;
      }

      toSave['privacy-policy-last-updated'] = FieldValue.serverTimestamp();

      await docRef.set(toSave, SetOptions(merge: true));

      _hasChanges = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy policy saved successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addSection(String lang) => setState(() {
        _data[lang]!.add(<String, Object>{
          'header': '',
          'contents': <String>[],
        });
        _hasChanges = true;
      });

  void _deleteSection(String lang, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Section'),
        content: const Text('Are you sure you want to delete this section? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _data[lang]!.removeAt(index);
                _hasChanges = true;
              });
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addContent(String lang, int sectionIndex) => 
    setState(() {
      (_data[lang]![sectionIndex]['contents'] as List<String>).add('');
      _hasChanges = true;
    });

  void _deleteContent(String lang, int sectionIndex, int contentIndex) =>
    setState(() {
      (_data[lang]![sectionIndex]['contents'] as List<String>).removeAt(contentIndex);
      _hasChanges = true;
    });

  void _onReorder(String lang, int oldIndex, int newIndex) =>
      setState(() {
        if (newIndex > oldIndex) newIndex--;
        final sections = _data[lang]!;
        final item = sections.removeAt(oldIndex);
        sections.insert(newIndex, item);
        _hasChanges = true;
      });

  Widget _buildAccessDenied() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'Access Denied',
          style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'You do not have permission to view this page.',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    ),
  );

  Widget _buildTabContent(String lang) {
    final sections = _data[lang]!;

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) => _onReorder(lang, oldIndex, newIndex),
      itemCount: sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = sections[sectionIndex];
        final contents = section['contents'] as List<String>;

        return Card(
          key: ValueKey('$lang-section-$sectionIndex'),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ReorderableDragStartListener(
                      index: sectionIndex,
                      child: const Icon(Icons.drag_handle, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Section ${sectionIndex + 1}',
                      style: const TextStyle( fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete section',
                      onPressed: () => _deleteSection(lang, sectionIndex),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey('$lang-header-$sectionIndex'),
                  initialValue: section['header'] as String,
                  decoration: const InputDecoration(
                    labelText: 'Section Header',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    _data[lang]![sectionIndex]['header'] = val;
                    _hasChanges = true;
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Content Items',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ...List.generate(contents.length, (contentIndex) {
                  return Padding(
                    key: ValueKey('$lang-content-$sectionIndex-$contentIndex'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Text('• '),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('$lang-contentfield-$sectionIndex-$contentIndex'),
                            initialValue: contents[contentIndex],
                            decoration: InputDecoration(
                              hintText: 'Content item ${contentIndex + 1}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (val) {
                              (_data[lang]![sectionIndex]['contents'] as List<String>)[contentIndex] = val;
                              _hasChanges = true;
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                              size: 20),
                          tooltip: 'Remove item',
                          onPressed: () => _deleteContent(lang, sectionIndex, contentIndex),
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => _addContent(lang, sectionIndex),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Privacy Policy')),
        body: _buildAccessDenied(),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !_hasChanges) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Confirm Exit"),
              content: const Text(
                "Are you sure you want to leave this page? Your data will not be saved.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("cancel").tr(),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("yes", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)).tr(),
                ),
              ],
            );
          },
        );

        if ((shouldExit ?? false) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Privacy Policy'),
          bottom: TabBar(
            controller: _tabController,
            tabs: _tabs.map((l) => Tab(text: l)).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map(_buildTabContent).toList(),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 10,
          children: [
            FloatingActionButton(
              heroTag: "add",
              onPressed: () => _addSection(_tabs[_tabController.index]),
              child: const Icon(Icons.add),
            ),
            FloatingActionButton(
              heroTag: "save",
              onPressed: _hasChanges ? _saveAll : null,
              child: const Icon(Icons.save),
            ),
          ],
        ),
      ),
    );
  }
}

class TACAdminPage extends StatefulWidget {
  const TACAdminPage({super.key});

  @override
  State<TACAdminPage> createState() => _TACAdminPageState();
}

class _TACAdminPageState extends State<TACAdminPage> with SingleTickerProviderStateMixin {
  
  static const _langFieldMap = {
    'English': 'tac-eng',
    'Malay': 'tac-bm',
    'Chinese': 'tac-cn',
  };

  static const _tabs = ['English', 'Malay', 'Chinese'];

  late final TabController _tabController;

  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  final Map<String, List<Map<String, Object>>> _data = {
    'English': [],
    'Malay': [],
    'Chinese': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _checkAdminRole();
    if (_isAdmin) await _loadAll();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _checkAdminRole() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      _isAdmin = doc.data()?['role'] == 'admin';
    } catch (_) {
      _isAdmin = false;
    }
  }

  int _extractNum(String key) => int.tryParse(key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  Future<void> _loadAll() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('about')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;

    final raw = snapshot.docs.first.data();

    for (final lang in _tabs) {
      final fieldKey = _langFieldMap[lang]!;
      final Map<String, dynamic> policyMap = (raw[fieldKey] as Map<String, dynamic>?) ?? {};

      final sortedSectionKeys = policyMap.keys.toList()
        ..sort((a, b) => _extractNum(a).compareTo(_extractNum(b)));

      _data[lang] = sortedSectionKeys.map((sKey) {
        final sMap = (policyMap[sKey] as Map<String, dynamic>?) ?? {};
        final contentMap = (sMap['content'] as Map<String, dynamic>?) ?? {};

        final sortedContentKeys = contentMap.keys.toList()
          ..sort((a, b) => _extractNum(a).compareTo(_extractNum(b)));

        return <String, Object>{
          'header': sMap['header']?.toString() ?? '',
          'contents': sortedContentKeys
              .map((k) => contentMap[k]?.toString() ?? '')
              .toList(),
        };
      }).toList();
    }

    _hasChanges = false;
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('about')
          .limit(1)
          .get();

      final docRef = snapshot.docs.isNotEmpty
          ? snapshot.docs.first.reference
          : FirebaseFirestore.instance.collection('about').doc();

      final Map<String, dynamic> toSave = {};

      for (final lang in _tabs) {
        final fieldKey = _langFieldMap[lang]!;
        final Map<String, dynamic> sectionsMap = {};

        final sections = _data[lang]!;
        for (int i = 0; i < sections.length; i++) {
          final contents = sections[i]['contents'] as List<String>;
          sectionsMap['section${i + 1}'] = {
            'header': sections[i]['header'],
            'content': {
              for (int j = 0; j < contents.length; j++)
                'c${j + 1}': contents[j],
            },
          };
        }

        toSave[fieldKey] = sectionsMap;
      }

      toSave['tac-last-updated'] = FieldValue.serverTimestamp();

      await docRef.set(toSave, SetOptions(merge: true));

      _hasChanges = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('T&C saved successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addSection(String lang) => setState(() {
        _data[lang]!.add(<String, Object>{
          'header': '',
          'contents': <String>[],
        });
        _hasChanges = true;
      });

  void _deleteSection(String lang, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Section'),
        content: const Text('Are you sure you want to delete this section? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _data[lang]!.removeAt(index);
                _hasChanges = true;
              });
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addContent(String lang, int sectionIndex) => 
    setState(() {
      (_data[lang]![sectionIndex]['contents'] as List<String>).add('');
      _hasChanges = true;
    });

  void _deleteContent(String lang, int sectionIndex, int contentIndex) =>
    setState(() {
      (_data[lang]![sectionIndex]['contents'] as List<String>).removeAt(contentIndex);
      _hasChanges = true;
    });

  void _onReorder(String lang, int oldIndex, int newIndex) =>
      setState(() {
        if (newIndex > oldIndex) newIndex--;
        final sections = _data[lang]!;
        final item = sections.removeAt(oldIndex);
        sections.insert(newIndex, item);
        _hasChanges = true;
      });

  Widget _buildAccessDenied() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'Access Denied',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'You do not have permission to view this page.',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    ),
  );

  Widget _buildTabContent(String lang) {
    final sections = _data[lang]!;

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) => _onReorder(lang, oldIndex, newIndex),
      itemCount: sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = sections[sectionIndex];
        final contents = section['contents'] as List<String>;

        return Card(
          key: ValueKey('$lang-section-$sectionIndex'),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ReorderableDragStartListener(
                      index: sectionIndex,
                      child: const Icon(Icons.drag_handle, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Section ${sectionIndex + 1}',
                      style: const TextStyle( fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete section',
                      onPressed: () => _deleteSection(lang, sectionIndex),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey('$lang-header-$sectionIndex'),
                  initialValue: section['header'] as String,
                  decoration: const InputDecoration(
                    labelText: 'Section Header',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    _data[lang]![sectionIndex]['header'] = val;
                    _hasChanges = true;
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Content Items',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ...List.generate(contents.length, (contentIndex) {
                  return Padding(
                    key: ValueKey('$lang-content-$sectionIndex-$contentIndex'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Text('• '),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('$lang-contentfield-$sectionIndex-$contentIndex'),
                            initialValue: contents[contentIndex],
                            decoration: InputDecoration(
                              hintText: 'Content item ${contentIndex + 1}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (val) {
                              (_data[lang]![sectionIndex]['contents'] as List<String>)[contentIndex] = val;
                              _hasChanges = true;
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                              size: 20),
                          tooltip: 'Remove item',
                          onPressed: () => _deleteContent(lang, sectionIndex, contentIndex),
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => _addContent(lang, sectionIndex),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit T&C')),
        body: _buildAccessDenied(),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !_hasChanges) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Confirm Exit"),
              content: const Text(
                "Are you sure you want to leave this page? Your data will not be saved.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("cancel").tr(),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("yes", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)).tr(),
                ),
              ],
            );
          },
        );

        if ((shouldExit ?? false) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit T&C'),
          bottom: TabBar(
            controller: _tabController,
            tabs: _tabs.map((l) => Tab(text: l)).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map(_buildTabContent).toList(),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 10,
          children: [
            FloatingActionButton(
              heroTag: "add",
              onPressed: () => _addSection(_tabs[_tabController.index]),
              child: const Icon(Icons.add),
            ),
            FloatingActionButton(
              heroTag: "save",
              onPressed: _hasChanges ? _saveAll : null,
              child: const Icon(Icons.save),
            ),
          ],
        )
      ),
    );
  }
}

class ManageFAQPage extends StatefulWidget {
  const ManageFAQPage({super.key});

  @override
  State<ManageFAQPage> createState() => _ManageFAQPageState();
}

class _ManageFAQPageState extends State<ManageFAQPage> with SingleTickerProviderStateMixin {
  static const _langFieldMap = {
    'English': 'faq-eng',
    'Malay': 'faq-bm',
    'Chinese': 'faq-cn',
  };

  static const _tabs = ['English', 'Malay', 'Chinese'];

  late final TabController _tabController;

  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  final Map<String, List<Map<String, String>>> _data = {
    'English': [],
    'Malay': [],
    'Chinese': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _checkAdminRole();
    if (_isAdmin) await _loadAll();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _checkAdminRole() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      _isAdmin = doc.data()?['role'] == 'admin';
    } catch (_) {
      _isAdmin = false;
    }
  }

  int _extractNum(String key) => int.tryParse(key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  Future<void> _loadAll() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('about')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;

    final raw = snapshot.docs.first.data();

    for (final lang in _tabs) {
      final fieldKey = _langFieldMap[lang]!;
      final Map<String, dynamic> faqMap =
          (raw[fieldKey] as Map<String, dynamic>?) ?? {};

      final sortedKeys = faqMap.keys.toList()
        ..sort((a, b) => _extractNum(a).compareTo(_extractNum(b)));

      _data[lang] = sortedKeys.map((key) {
        final map = (faqMap[key] as Map<String, dynamic>?) ?? {};
        return {
          'question': map['question']?.toString() ?? '',
          'answer': map['answer']?.toString() ?? '',
        };
      }).toList();
    }

    _hasChanges = false;
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('about')
          .limit(1)
          .get();

      final docRef = snapshot.docs.isNotEmpty
          ? snapshot.docs.first.reference
          : FirebaseFirestore.instance.collection('about').doc();

      final Map<String, dynamic> toSave = {};

      for (final lang in _tabs) {
        final fieldKey = _langFieldMap[lang]!;
        final Map<String, dynamic> map = {};

        final list = _data[lang]!;
        for (int i = 0; i < list.length; i++) {
          map['q${i + 1}'] = {
            'question': list[i]['question'],
            'answer': list[i]['answer'],
          };
        }

        toSave[fieldKey] = map;
      }

      toSave['faq-last-updated'] = FieldValue.serverTimestamp();

      await docRef.set(toSave, SetOptions(merge: true));

      _hasChanges = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FAQ saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addItem(String lang) {
    setState(() {
      _data[lang]!.add({'question': '', 'answer': ''});
      _hasChanges = true;
    });
  }

  void _deleteItem(String lang, int index) {
    setState(() {
      _data[lang]!.removeAt(index);
      _hasChanges = true;
    });
  }

  void _onReorder(String lang, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _data[lang]!.removeAt(oldIndex);
      _data[lang]!.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  Widget _buildTab(String lang) {
    final list = _data[lang]!;

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: list.length,
      onReorder: (o, n) => _onReorder(lang, o, n),
      buildDefaultDragHandles: false,
      itemBuilder: (context, i) {
        final item = list[i];

        return Card(
          key: ValueKey('$lang-$i'),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: const Icon(Icons.drag_handle),
                    ),
                    const SizedBox(width: 8),
                    Text('FAQ ${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteItem(lang, i),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: item['question'],
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    item['question'] = v;
                    _hasChanges = true;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: item['answer'],
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Answer',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    item['answer'] = v;
                    _hasChanges = true;
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage FAQ'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((e) => Tab(text: e)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map(_buildTab).toList(),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 10,
        children: [
          FloatingActionButton(
            heroTag: "add",
            onPressed: () => _addItem(_tabs[_tabController.index]),
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            heroTag: "save",
            onPressed: _hasChanges ? _saveAll : null,
            child: const Icon(Icons.save),
          ),
        ],
      ),
    );
  }
}