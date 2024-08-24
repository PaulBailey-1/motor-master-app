
import 'package:flutter/material.dart';
import 'package:motor_master/Output.dart';
import 'package:motor_master/widgets/even_slider.dart';

class ControlTile extends StatefulWidget {
  final Output output;
  bool? end = false;

  ControlTile(this.output, {super.key, this.end});

  @override
  State<ControlTile> createState() => _ControlTileState();
}

class _ControlTileState extends State<ControlTile> {
  bool scanning = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.only(top: 20)),
        Text(
          widget.output.name,
          style: const TextStyle(fontSize: 18),
        ),
        ..._buildControls(context),
        SizedBox(
          width: 150,
          height: 60,
          child: ElevatedButton(
              onPressed: () {
                setState(() {
                  widget.output.setEnabled(!widget.output.enabled);
                });
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor:
                    widget.output.enabled ? Colors.red : Colors.green,
              ),
              child: Text(
                widget.output.enabled ? "Disable" : "Enable",
                style: const TextStyle(fontSize: 18),
              )),
        ),
        const Padding(padding: EdgeInsets.only(top: 20)),
        ...(!widget.end!
            ? [
                Divider(
                  indent: 20,
                  endIndent: 20,
                  color: Theme.of(context).colorScheme.primary,
                )
              ]
            : []),
      ],
    );
  }

  List<Widget> _buildControls(BuildContext context) {
    if (widget.output is PwmOutput) {
      PwmOutput output = widget.output as PwmOutput;
      return [
        Text("CMD: ${output.cmd.round()}%"),
        EvenSlider(output.cmd, (double value) {
          setState(() {
            output.setCmd(value.roundToDouble());
          });
        })
      ];
    } else if (widget.output is CanOutput) {
      CanOutput output = widget.output as CanOutput;
      return [
        const Padding(padding: EdgeInsets.only(top: 10)),
        ElevatedButton(
          onPressed: _onScanPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Theme.of(context).primaryColor
          ),
          child: scanning ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(color: Colors.white,),
          ) : const Text("Scan for Devices"),
        ),
        ..._buildCanControls(output),
      ];
    }
    return [];
  }

  void _onScanPressed() {
    (widget.output as CanOutput).readInfo().then((value) {
      setState(() {
        scanning = false;
      });
    });
    setState(() {
      scanning = true;
    });
  }

  List<Widget> _buildCanControls(CanOutput output) {
    List<Widget> widgets = [];
    output.info.forEach((id, device) {
      widgets.add(Text('Name: ${device.name}'));
      widgets.add(Text('Id: $id'));
      widgets.add(Text('CMD: ${output.getCmd(id)}'));
      widgets.add(EvenSlider(output.getCmd(id), (double value) {
          setState(() {
            widget.output.setCmd(CanCommand(id, value));
          });
        }));
    });
    return widgets;
  }
}
