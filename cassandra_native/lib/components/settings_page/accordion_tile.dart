import 'package:flutter/material.dart';

class AccordionTile extends StatelessWidget {
  final String title;
  final List<Widget> content;
  const AccordionTile({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      //leading: Icon(Icons.computer),
      backgroundColor: Theme.of(context).colorScheme.surface,
      collapsedIconColor: Theme.of(context).colorScheme.primary,
      //iconColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide.none,
        borderRadius: BorderRadius.circular(8),
      ),
      children: content,
    );
  }
}
