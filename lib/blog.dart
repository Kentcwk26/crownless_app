import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'utils/bottom_bar.dart';
import 'utils/image_responsive.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class BlogPage extends StatelessWidget {
  const BlogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("blog").tr(),
      ),

      body: SafeArea(
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return MediaCard(
              index: index,
              path: items[index].path,
              type: items[index].type,
              kind: items[index].kind,
              description: items[index].description,
              createdAt: items[index].createdAt,
            );
          },
        ),
      ),
      bottomNavigationBar: StickyBottomBar(
        left: Text(
          "Join our dance journey 🕺",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        right: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/inquiries'),
          child: const Text("Join Now"),
        ),
      ),
    );
  }
}