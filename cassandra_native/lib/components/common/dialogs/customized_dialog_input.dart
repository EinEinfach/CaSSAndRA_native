import 'package:flutter/material.dart';

import 'package:cassandra_native/components/common/buttons/customized_elevated_button.dart';

class CustomizedDialogInput extends StatefulWidget {
  final String title;
  final String content;
  final String suggestionText;

  const CustomizedDialogInput({
    super.key,
    required this.title,
    required this.content,
    required this.suggestionText,
  });

  @override
  State<CustomizedDialogInput> createState() => _CustomizedDialogInputState();
}

class _CustomizedDialogInputState extends State<CustomizedDialogInput> {
  final TextEditingController _mapNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapNameController.text = widget.suggestionText;
  }

  @override
  void dispose() {
    _mapNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Theme.of(context).colorScheme.secondary,
      title: Text(
        widget.title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      content: SizedBox(
        height: 80,
        child: Column(
          children: [
            Text(widget.content),
            SizedBox(
              height: 50,
              child: TextField(
                controller: _mapNameController,
                decoration: InputDecoration(
                  label: Text(
                    'name',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        CustomizedElevatedButton(
          text: 'cancel',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        CustomizedElevatedButton(
          text: 'ok',
          onPressed: () {
            Navigator.of(context).pop(_mapNameController.text);
          },
        ),
      ],
    );
  }
}
