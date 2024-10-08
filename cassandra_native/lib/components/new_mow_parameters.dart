import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/cupertino.dart';

import 'package:cassandra_native/models/mow_parameters.dart';
import 'package:cassandra_native/components/customized_elevated_button.dart';

const uuid = Uuid();

class NewMowParameters extends StatefulWidget {
  final MowParameters mowParameters;

  const NewMowParameters({
    super.key,
    required this.onSetMowParameters,
    required this.mowParameters,
  });

  final void Function(MowParameters mowParameters) onSetMowParameters;

  @override
  State<NewMowParameters> createState() => _NewMowParametersState();
}

class _NewMowParametersState extends State<NewMowParameters> {
  late Pattern mowPattern;
  final _widthController = TextEditingController();
  final _angleController = TextEditingController();
  final _distanceToBorderController = TextEditingController();
  final _borderLapsController = TextEditingController();
  late bool mowArea;
  late bool mowExclusionBorder;
  late bool mowBorderCcw;

  void _submitMowParametersData() {
    final enteredWidth = double.tryParse(_widthController.text);
    final enteredAngle = int.tryParse(_angleController.text);
    final enteredDistanceToBorder =
        int.tryParse(_distanceToBorderController.text);
    final enteredBorderLaps = int.tryParse(_borderLapsController.text);

    final inputInvalid = (enteredWidth == null || enteredWidth <= 0) ||
        (enteredAngle == null || enteredAngle < 0) ||
        (enteredDistanceToBorder == null || enteredDistanceToBorder < 0) ||
        (enteredBorderLaps == null || enteredBorderLaps < 0);

    if (inputInvalid) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          title: const Text(
            'Invalid input',
            style: TextStyle(fontSize: 14),
          ),
          content: const Text(
              'Please make sure a valid values for mow parameters was entered'),
          actions: [
            CustomizedElevatedButton(
              text: 'ok',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
      return;
    }
    widget.onSetMowParameters(MowParameters(
      mowPattern: mowPattern,
      width: enteredWidth,
      angle: enteredAngle,
      distanceToBorder: enteredDistanceToBorder,
      borderLaps: enteredBorderLaps,
      mowArea: mowArea,
      mowExclusionBorder: mowExclusionBorder,
      mowBorderCcw: mowBorderCcw,
    ));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _widthController.dispose();
    _angleController.dispose();
    _distanceToBorderController.dispose();
    _borderLapsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _widthController.text = widget.mowParameters.width.toString();
    _angleController.text = widget.mowParameters.angle.toString();
    _distanceToBorderController.text =
        widget.mowParameters.distanceToBorder.toString();
    _borderLapsController.text = widget.mowParameters.borderLaps.toString();
    mowPattern = widget.mowParameters.mowPattern;
    mowArea = widget.mowParameters.mowArea;
    mowExclusionBorder = widget.mowParameters.mowExclusionBorder;
    mowBorderCcw = widget.mowParameters.mowBorderCcw;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 310,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _widthController,
                    decoration: InputDecoration(
                      label: Text(
                        'Width',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _angleController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      label: Text(
                        'Angle',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _distanceToBorderController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      label: Text(
                        'Distance to border',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _borderLapsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      label: Text(
                        'Border laps',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      'area',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    CupertinoSwitch(
                      value: mowArea,
                      onChanged: (value) {
                        mowArea = !mowArea;
                        setState(() {});
                      },
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      'border',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    CupertinoSwitch(
                      value: mowExclusionBorder,
                      onChanged: (value) {
                        mowExclusionBorder = !mowExclusionBorder;
                        setState(() {});
                      },
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      'ccw',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    CupertinoSwitch(
                      value: mowBorderCcw,
                      onChanged: (value) {
                        mowBorderCcw = !mowBorderCcw;
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 8, 5),
              child: DropdownButton(
                isExpanded: true,
                dropdownColor: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(8),
                value: mowPattern,
                items: Pattern.values
                    .map(
                      (pattern) => DropdownMenuItem(
                        value: pattern,
                        child: Center(
                          child: Text(
                            pattern.name.toUpperCase(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    mowPattern = value;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomizedElevatedButton(
                    text: 'cancel',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  CustomizedElevatedButton(
                      text: 'save', onPressed: _submitMowParametersData),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
