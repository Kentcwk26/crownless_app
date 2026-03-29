import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'main.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("faq".tr())),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Icon(Icons.help_outline, size: 60),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        "faqSubtitle".tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFAQItem(
                      question: "What is Crownless?",
                      answer: "Crownless is a dynamic dance group that embodies the spirit of creativity, passion, and unity. We are a collective of talented dancers who come together to create captivating performances that inspire and entertain audiences worldwide.",
                    ),
                    _buildFAQItem(
                      question: "Where can I watch Crownless perform?",
                      answer: "You can catch our performances at various events, competitions, and showcases. We also share our dance videos on our social media platforms and YouTube channel. Follow us to stay updated on our latest performances and upcoming events!",
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.queue_play_next),
                  onPressed: () => Navigator.pushNamed(context, '/inquiries'),
                  label: const Text("moreQuestionsToAsk").tr(),
                ),
              )
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        collapsedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        backgroundColor: Colors.grey[50],
        collapsedBackgroundColor: Colors.grey[50],
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
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
    String lastUpdated = '';
    if (rawTimestamp is Timestamp) {
      final dt = rawTimestamp.toDate();
      lastUpdated = DateFormat('dd MMM yyyy').format(dt); // e.g. 30 Mar 2026
    }

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
    String lastUpdated = '';
    if (rawTimestamp is Timestamp) {
      final dt = rawTimestamp.toDate();
      lastUpdated = DateFormat('dd MMM yyyy').format(dt); // e.g. 30 Mar 2026
    }

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