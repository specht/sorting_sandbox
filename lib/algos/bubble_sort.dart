import 'package:sorting_sandbox/misc.dart';

class BubbleSort extends SortingAlgorithm {
  void sort(Elements list, Elements scratch) {
    for (int a = 0; a < list.length - 1; a++) {
      int b = a;
      for (int i = a; i < list.length; i++) {
        if (list[i] < list[b]) {
          b = i;
        }
      }
      if (a != b && list[b] < list[a]) {
        list.swap(a, b);
      }
    }
  }
}
