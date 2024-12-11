import 'package:flutter/material.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/cupertino.dart';

import 'package:cassandra_native/models/mow_parameters.dart';
import 'package:cassandra_native/components/common/customized_elevated_button.dart';

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
  final controller = MultiSelectController<Pattern>();
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
    List<DropdownItem<Pattern>> items = [
      DropdownItem(
          label: 'lines',
          value: Pattern.lines,
          selected: mowPattern == Pattern.lines),
      DropdownItem(
          label: 'squares',
          value: Pattern.squares,
          selected: mowPattern == Pattern.squares),
      DropdownItem(
          label: 'rings',
          value: Pattern.rings,
          selected: mowPattern == Pattern.rings),
    ];
    return SizedBox(
      width: 300,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(
              height: 5,
            ),
            SizedBox(
              width: 150,
              child: MultiDropdown<Pattern>(
                singleSelect: true,
                items: items,
                controller: controller,
                enabled: true,
                searchEnabled: false,
                fieldDecoration: FieldDecoration(
                  hintText: mowPattern.name,
                  hintStyle: Theme.of(context).textTheme.bodyMedium,
                  showClearIcon: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                dropdownDecoration: DropdownDecoration(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  marginTop: 2,
                  maxHeight: 300,
                ),
                dropdownItemDecoration: DropdownItemDecoration(
                  // selectedIcon: null,
                  selectedBackgroundColor:
                      Theme.of(context).colorScheme.secondary,
                ),
                onSelectionChange: (selectedItems) {
                  mowPattern =
                      selectedItems.isNotEmpty ? selectedItems[0] : mowPattern;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
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
