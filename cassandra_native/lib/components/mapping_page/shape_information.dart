import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/components/common/buttons/customized_elevated_icon_button.dart';
import 'package:cassandra_native/components/logic/shapes_logic.dart';

class ShapeInformation extends StatelessWidget {
  final String shapeName;
  final int? exclusionNr;
  final Shapes shapes;
  final bool addPointActive;
  final void Function(String, int?) onAddPointPressed;
  final void Function(String, int?) onRemoveShapePressed;
  final void Function(LongPressStartDetails) selectShapeOrPointInformation;
  final void Function(String, int?, LongPressMoveUpdateDetails) moveShapeInformation;

  const ShapeInformation({
    super.key,
    required this.shapeName,
    this.exclusionNr,
    required this.shapes,
    required this.addPointActive,
    required this.onAddPointPressed,
    required this.onRemoveShapePressed,
    required this.selectShapeOrPointInformation,
    required this.moveShapeInformation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$shapeName ${exclusionNr ?? ''}', style: Theme.of(context).textTheme.bodySmall),
        Row(
          children: [
            GestureDetector(
              onLongPressStart: (details) => selectShapeOrPointInformation(details),
              onLongPressMoveUpdate: (details) => moveShapeInformation(shapeName, exclusionNr, details),
              child: Icon(
                Icons.drag_indicator,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            // CustomizedElevatedIconButton(
            //   icon: BootstrapIcons.node_plus,
            //   isActive: addPointActive && shapes.selectedShape == shapeName && shapes.selectedExclusionIndex == exclusionNr,
            //   onPressed: () => onAddPointPressed(shapeName, exclusionNr),
            // ),
            CustomizedElevatedIconButton(
              icon: BootstrapIcons.trash,
              isActive: false,
              onPressed: () => onRemoveShapePressed(shapeName, exclusionNr),
            ),
          ],
        ),
      ],
    );
  }
}
