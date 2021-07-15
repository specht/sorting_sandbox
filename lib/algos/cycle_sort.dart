import 'package:sorting_sandbox/misc.dart';

class CycleSort extends SortingAlgorithm {
  void sort(list, scratch) {
    for (int cycle_start = 0; cycle_start <= list.length - 2; cycle_start++) {
      Element item = list[cycle_start];
      int pos = cycle_start;
      for (int i = cycle_start + 1; i < list.length; i++)
        if (list[i] < item) pos++;
      if (pos == cycle_start) continue;
      while (item == list[pos]) pos++;
      if (pos != cycle_start) {
        Element temp = list[pos];
        list[pos] = item;
        item = temp;
      }
      while (pos != cycle_start) {
        pos = cycle_start;
        for (int i = cycle_start + 1; i < list.length; i++)
          if (list[i] < item) pos++;
        while (item == list[pos]) pos++;
        if (item != list[pos]) {
          Element temp = list[pos];
          list[pos] = item;
          item = temp;
        }
      }
    }
  }
}
