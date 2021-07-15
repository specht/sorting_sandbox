import 'package:sorting_sandbox/misc.dart';

class SelectionSort extends SortingAlgorithm {
  void sort(list, scratch) {
    for (int steps = 0; steps < list.length; steps++) {
      for (int i = steps + 1; i < list.length; i++) {
        if (list[steps] > list[i]) list.swap(i, steps);
      }
    }
  }
}
