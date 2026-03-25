import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crownless_app/utils/information.dart';
import 'package:easy_localization/easy_localization.dart';
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                  child: IconTextWidget(
                    icon: Icons.search_off_outlined,
                    iconColor: Colors.red,
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
                  child: IconTextWidget(
                    icon: Icons.search_off_outlined,
                    iconColor: Colors.red,
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