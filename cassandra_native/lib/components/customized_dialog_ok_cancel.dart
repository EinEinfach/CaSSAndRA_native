import 'package:flutter/material.dart';

import 'package:cassandra_native/components/customized_elevated_button.dart';

class CustomizedDialogOkCancel extends StatelessWidget {
  final String title;
  final String content;
  final void Function() onCancelPressed;
  final void Function() onOkPressed;

  const CustomizedDialogOkCancel({
    super.key,
    required this.title,
    required this.content,
    required this.onCancelPressed,
    required this.onOkPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Theme.of(context).colorScheme.secondary,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      content: Text(content),
      actions: [
        CustomizedElevatedButton(
          text: 'cancel',
          onPressed: onCancelPressed,
        ),
        CustomizedElevatedButton(
          text: 'ok',
          onPressed: onOkPressed,
        ),
      ],
    );
  }
}
