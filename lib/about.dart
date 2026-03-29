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
                  const Text("dc_description", textAlign: TextAlign.justify).tr(),
                  CarouselSection(
                    imagePaths: [
                      'assets/images/photo3.jpg', 'assets/images/photo4.jpg', 
                    ],
                  ),
                  Text("dc_slogan".tr(), textAlign: TextAlign.center),
                  MeetOurTeamPage(),
                  const Text("haveQuestionsFeedback", textAlign: TextAlign.center).tr(),
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

class Dancer {
  final String name;
  final String role;
  final String? mbti;
  final String quote;

  Dancer({
    required this.name,
    required this.role,
    this.mbti,
    required this.quote,
  });
}

class MeetOurTeamPage extends StatelessWidget {
  const MeetOurTeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dancers = [
      Dancer(
        name: 'Member 1',
        role: 'Founder & Group Leader',
        mbti: null,
        quote: 'Vision without action is daydreaming. I choose to lead with intent'
      ),
      Dancer(
        name: 'Member 2',
        role: 'Co-Lead & Software Developer',
        mbti: 'ENTJ',
        quote: "I code the future and craft stories that move people"
      ),
      Dancer(
        name: 'Member 3',
        role: 'Dancer',
        mbti: null,
        quote: "Dance is the hidden language of the soul",
      ),
      Dancer(
        name: 'Member 4',
        role: 'Dancer',
        mbti: null,
        quote: "Dance is the joy of movement and the heart of life"
      ),
      Dancer(
        name: 'Member 5',
        role: 'Dancer',
        mbti: null,
        quote: "When you dance to your own rhythm, life taps its toes to your beat"
      ),
      Dancer(
        name: 'Member 6',
        role: 'Dancer',
        mbti: null,
        quote: "To watch us dance is to hear our hearts speak"
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10.0,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Meet Our Crew',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dancers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.55,
              ),
              itemBuilder: (context, index) {
                return DancerCard(dancer: dancers[index]);
              },
            ),
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

    return Container(
      width: MediaQuery.of(context).size.width * 0.35,
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
              height: MediaQuery.of(context).size.width * 0.35,
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
                  if (dancer.mbti != null) ...[
                    Text(
                      "MBTI: ${dancer.mbti}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
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