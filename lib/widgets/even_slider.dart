
import 'package:flutter/material.dart';

class EvenSlider extends StatelessWidget {

  final double value;
  final Function(double) onChanged;

  const EvenSlider(this.value, this.onChanged, {super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 100,
                  child: LinearProgressIndicator(
                    value: 1 - value / -100,
                    color: Colors.grey,
                    backgroundColor: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), bottomLeft: Radius.circular(5)),
                    minHeight: 8,
                  ),
                ),
                Expanded(
                  flex: 100,
                  child: LinearProgressIndicator(
                    value: value / 100,
                    color:Theme.of(context).primaryColor,
                    backgroundColor: Colors.grey,
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          Slider(
            value: value,
            activeColor: Colors.transparent,
            inactiveColor: Colors.transparent,
            thumbColor: Theme.of(context).primaryColor,
            min: -100,
            max: 100,
            divisions: 100,
            onChanged: onChanged,
          ),
        ],
      );
  }
}