import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'utils/date_formatter.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  static const _langFieldMap = {
    'en': 'faq-eng',
    'ms': 'faq-bm',
    'zh': 'faq-cn',
  };

  Future<({String lastUpdated, List<dynamic> items})> _fetchFAQ(String langCode) async {
    final fieldKey = _langFieldMap[langCode] ?? 'faq-eng';

    final snapshot = await FirebaseFirestore.instance
        .collection('about')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return (items: [], lastUpdated: '');

    final data = snapshot.docs.first.data();
    final Map<String, dynamic> faqMap = (data[fieldKey] as Map<String, dynamic>?) ?? {};

    final rawTimestamp = data['faq-last-updated'];

    final lastUpdated = rawTimestamp is Timestamp
        ? DateFormatter.formatLongDate(context, rawTimestamp)
        : '';

    int extractNum(String key) =>
        int.tryParse(key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final sortedKeys = faqMap.keys.toList()
      ..sort((a, b) => extractNum(a).compareTo(extractNum(b)));

    final items = sortedKeys.map((key) {
      final map = (faqMap[key] as Map<String, dynamic>?) ?? {};

      return (
        question: map['question']?.toString() ?? '',
        answer: map['answer']?.toString() ?? '',
      );
    }).where((e) => e.question.isNotEmpty).toList();

    return (items: items, lastUpdated: lastUpdated);
  }

  String _getCurrentLangCode() => context.locale.languageCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
      ),
      body: FutureBuilder(
        future: _fetchFAQ(_getCurrentLangCode()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load FAQ.'));
          }

          final items = snapshot.data?.items ?? [];
          final lastUpdated = snapshot.data?.lastUpdated ?? '';

          if (items.isEmpty) {
            return const Center(child: Text('No FAQ available.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  spacing: 10,
                  children: [
                    Icon(Icons.question_answer_outlined, size: 48),
                    Text("faqSubtitle".tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

              ...items.map((item) {
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      shape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                      ),
                      collapsedShape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                      ),
                      title: Text(
                        item.question,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black // always black as you want
                        ),
                      ),
                      children: [
                        Text(
                          item.answer,
                          style: TextStyle(
                            height: 1.5,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Last updated: $lastUpdated',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {

  static const _langFieldMap = {
    'en': 'privacy-policy-eng',
    'ms': 'privacy-policy-bm',
    'zh': 'privacy-policy-cn',
  };

  Future<({String lastUpdated, List<dynamic> sections})> _fetchSections(String langCode) async {
    final fieldKey = _langFieldMap[langCode] ?? 'privacy-policy-eng';

    final snapshot = await FirebaseFirestore.instance
        .collection('about')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return (sections: [], lastUpdated: '');

    final data = snapshot.docs.first.data();
    final Map<String, dynamic> policyMap = (data[fieldKey] as Map<String, dynamic>?) ?? {};

    final rawTimestamp = data['tac-last-updated'];

    final lastUpdated = rawTimestamp is Timestamp
        ? DateFormatter.formatLongDate(context, rawTimestamp)
        : '';

    int extractNum(String key) =>
        int.tryParse(key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final sortedSectionKeys = policyMap.keys.toList()
      ..sort((a, b) => extractNum(a).compareTo(extractNum(b)));

    final sections = sortedSectionKeys.map((sectionKey) {
      final sectionMap = (policyMap[sectionKey] as Map<String, dynamic>?) ?? {};
      final header = sectionMap['header']?.toString() ?? '';
      final contentMap = (sectionMap['content'] as Map<String, dynamic>?) ?? {};

      final sortedContentKeys = contentMap.keys.toList()
        ..sort((a, b) => extractNum(a).compareTo(extractNum(b)));

      final contents = sortedContentKeys
          .map((k) => contentMap[k]?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      return (header: header, contents: contents);
    }).where((s) => s.header.isNotEmpty).toList();

    return (sections: sections, lastUpdated: lastUpdated);
  }

  String _getCurrentLangCode() => context.locale.languageCode;

  Widget _buildSection({
    required String header,
    required List<String> contents,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (contents.isNotEmpty) const SizedBox(height: 8),
        ...contents.map(
          (content) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    content,
                    style: textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('privacyPolicy').tr(),
      ),
      body: FutureBuilder(
        future: _fetchSections(_getCurrentLangCode()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load privacy policy.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final sections = snapshot.data?.sections ?? [];
          final lastUpdated = snapshot.data?.lastUpdated ?? '';

          if (sections.isEmpty) {
            return const Center(child: Text('No content available.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: sections.length + 2,
            separatorBuilder: (_, _) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text(
                  'privacyPolicy_desc',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                ).tr();
              }

              if (index == sections.length + 1) {
                return Text(
                  'lastUpdated',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ).tr(args: [lastUpdated]);
              }

              final section = sections[index - 1];
              return _buildSection(
                header: section.header,
                contents: section.contents,
              );
            },
          );
        },
      ),
    );
  }
}

class TACPage extends StatefulWidget {
  const TACPage({super.key});

  @override
  State<TACPage> createState() => _TACPageState();
}

class _TACPageState extends State<TACPage> {
  
  static const _langFieldMap = {
    'en': 'tac-eng',
    'ms': 'tac-bm',
    'zh': 'tac-cn',
  };

  Future <({String lastUpdated, List<dynamic> sections})> _fetchSections(String langCode) async {
    final fieldKey = _langFieldMap[langCode] ?? 'tac-eng';

    final snapshot = await FirebaseFirestore.instance
        .collection('about')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return (sections: [], lastUpdated: '');

    final data = snapshot.docs.first.data();
    final Map<String, dynamic> policyMap = (data[fieldKey] as Map<String, dynamic>?) ?? {};

    final rawTimestamp = data['tac-last-updated'];

    final lastUpdated = rawTimestamp is Timestamp
        ? DateFormatter.formatLongDate(context, rawTimestamp)
        : '';

    int extractNum(String key) =>
        int.tryParse(key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final sortedSectionKeys = policyMap.keys.toList()
      ..sort((a, b) => extractNum(a).compareTo(extractNum(b)));

    final sections = sortedSectionKeys.map((sectionKey) {
      final sectionMap = (policyMap[sectionKey] as Map<String, dynamic>?) ?? {};
      final header = sectionMap['header']?.toString() ?? '';
      final contentMap = (sectionMap['content'] as Map<String, dynamic>?) ?? {};

      final sortedContentKeys = contentMap.keys.toList()
        ..sort((a, b) => extractNum(a).compareTo(extractNum(b)));

      final contents = sortedContentKeys
          .map((k) => contentMap[k]?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      return (header: header, contents: contents);
    }).where((s) => s.header.isNotEmpty).toList();

    return (sections: sections, lastUpdated: lastUpdated);
  }

  String _getCurrentLangCode() => context.locale.languageCode;

  Widget _buildSection({
    required String header,
    required List<String> contents,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (contents.isNotEmpty) const SizedBox(height: 8),
        ...contents.map(
          (content) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    content,
                    style: textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('termsConditions').tr(),
      ),
      body: FutureBuilder(
        future: _fetchSections(_getCurrentLangCode()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load terms and conditions.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final sections = snapshot.data?.sections ?? [];
          final lastUpdated = snapshot.data?.lastUpdated ?? '';

          if (sections.isEmpty) {
            return const Center(child: Text('No content available.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: sections.length + 2,
            separatorBuilder: (_, _) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text(
                  'termsConditions_desc',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                ).tr();
              }

              if (index == sections.length + 1) {
                return Text(
                  'lastUpdated',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ).tr(args: [lastUpdated]);
              }

              final section = sections[index - 1];
              return _buildSection(
                header: section.header,
                contents: section.contents,
              );
            },
          );
        },
      ),
    );
  }
}