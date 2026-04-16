import 'package:cloud_firestore/cloud_firestore.dart';

import 'main.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'utils/carousel_slides.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("aboutUs").tr()
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 10.0,
                children: [
                  Image.asset("assets/images/logo.jpg"),
                  const Text("dc_slogan", textAlign: TextAlign.center).tr(),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: const Text("dc_description", textAlign: TextAlign.justify).tr(),
                  ),
                  // CarouselSection(
                  //   imagePaths: [
                  //     'assets/images/photo3.jpg', 'assets/images/photo4.jpg', 
                  //   ],
                  // ),
                  MeetOurTeamPage(),
                  SupportUs(),
                  const Text("haveQuestionsOrFeedback", textAlign: TextAlign.center).tr(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.queue_play_next),
                    onPressed: () => Navigator.pushNamed(context, '/inquiries'),
                    label: const Text("wedLoveToHearFromYou").tr(),
                  ),
                  Footer()
                ],
              ),
            ),
          )
        )
      )
    );
  }
}

class SupportUs extends StatelessWidget {
  const SupportUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        spacing: 10.0,
        children: [
          Text("supportUs".tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            "supportUsDescription".tr(), 
            textAlign: MediaQuery.of(context).size.width >= 600
                ? TextAlign.center
                : TextAlign.justify,
            overflow: TextOverflow.visible
          ),
          Image.asset("assets/images/qr_code.jpg", height: 500),
        ],
      ),
    );
  }
}

class Dancer {
  final String name;
  final String role;
  final String? mbti;
  final String quote;
  final String image;
  final int order;

  Dancer({
    required this.name,
    required this.role,
    this.mbti,
    required this.quote,
    required this.image,
    required this.order,
  });

  factory Dancer.fromMap(Map<String, dynamic> map) {
    return Dancer(
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      mbti: map['mbti'],
      quote: map['quote'] ?? '',
      image: map['image'] ?? '',
      order: map['order'] ?? 0,
    );
  }
}

class MeetOurTeamPage extends StatelessWidget {
  const MeetOurTeamPage({super.key});

  Future<List<Dancer>> _fetchDancers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('about')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return [];

    final data = snapshot.docs.first.data();

    final Map<String, dynamic> dancersMap = (data['dancers'] as Map<String, dynamic>?) ?? {};

    int extractNum(String key) => int.tryParse(key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final sortedKeys = dancersMap.keys.toList()
      ..sort((a, b) => extractNum(a).compareTo(extractNum(b)));

    final dancers = sortedKeys.map((key) {
      final map = (dancersMap[key] as Map<String, dynamic>?) ?? {};
      return Dancer.fromMap(map);
    }).toList();

    dancers.sort((a, b) => a.order.compareTo(b.order));

    return dancers;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        spacing: 14,
        children: [
          const Text(
            'meetOurCrew',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ).tr(),

          FutureBuilder<List<Dancer>>(
            future: _fetchDancers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Failed to load team'));
              }

              final dancers = snapshot.data ?? [];

              if (dancers.isEmpty) {
                return const Center(child: Text('No team members'));
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dancers.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width >= 600 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.55,
                ),
                itemBuilder: (context, index) {
                  return DancerCard(dancer: dancers[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class DancerCard extends StatelessWidget {
  final Dancer dancer;

  const DancerCard({super.key, required this.dancer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrDesktop = screenWidth >= 600;

    final imageHeight = isTabletOrDesktop
        ? screenWidth * 0.25
        : screenWidth * 0.35;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: Image.asset("assets/images/defaultprofile.jpg", fit: BoxFit.cover),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10.0,
                children: [
                  Text(
                    dancer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    dancer.role,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (dancer.mbti != null && dancer.mbti!.trim().isNotEmpty)
                    Text(
                      "MBTI: ${dancer.mbti}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  Expanded(
                    child: Text(
                      "Quote: ${dancer.quote}",
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}