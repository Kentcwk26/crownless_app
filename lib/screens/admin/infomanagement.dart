import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crownless_app/utils/information.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../utils/color_buttons.dart';
import '../../utils/date_formatter.dart';
import '../../utils/role_formatter.dart';

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
      footer: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: () => _addSection(lang),
          icon: const Icon(Icons.add),
          label: const Text('Add Section'),
        ),
      ),
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
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.save_outlined),
                tooltip: 'Save all',
                onPressed: _saveAll,
              ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map(_buildTabContent).toList(),
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
      footer: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: () => _addSection(lang),
          icon: const Icon(Icons.add),
          label: const Text('Add Section'),
        ),
      ),
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
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.save_outlined),
                tooltip: 'Save all',
                onPressed: _saveAll,
              ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map(_buildTabContent).toList(),
        ),
      ),
    );
  }
}