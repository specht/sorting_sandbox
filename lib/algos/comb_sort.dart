import 'package:sorting_sandbox/misc.dart';

class CombSort extends SortingAlgorithm {
  int getNextGap(int gap) {
    gap = (gap * 10) ~/ 13;
    return (gap < 1) ? 1 : gap;
  }

  void sort(list, scratch) {
    int gap = list.length;
    bool swapped = true;
    while (gap != 1 || swapped) {
      gap = getNextGap(gap);
      swapped = false;
      for (int i = 0; i < list.length - gap; i++) {
        if (list[i] > list[i + gap]) {
          list.swap(i, i + gap);
          swapped = true;
        }
      }
    }
  }
}
