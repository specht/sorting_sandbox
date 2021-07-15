import 'package:sorting_sandbox/misc.dart';

class InsertionSort extends SortingAlgorithm {
  void sort(list, scratch) {
    int start = 0;
    int end = list.length;
    for (int pos = start + 1; pos < end; pos++) {
      var min = start;
      var max = pos;
      var element = list[pos];
      while (min < max) {
        var mid = min + ((max - min) >> 1);
        if (element < list[mid]) {
          max = mid;
        } else {
          min = mid + 1;
        }
      }
      for (int i = pos; i >= min + 1; i--) list[i] = list[i - 1];
      list[min] = element;
    }
  }
}
