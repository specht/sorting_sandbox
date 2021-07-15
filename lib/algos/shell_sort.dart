import 'package:sorting_sandbox/misc.dart';

class ShellSort extends SortingAlgorithm {
  void sort(list, scratch) {
    for (int gap = list.length ~/ 2; gap > 0; gap ~/= 2) {
      for (int i = gap; i < list.length; i++) {
        Element temp = list[i];
        int j;
        for (j = i; j >= gap && list[j - gap] > temp; j -= gap)
          list[j] = list[j - gap];
        list[j] = temp;
      }
    }
  }
}
