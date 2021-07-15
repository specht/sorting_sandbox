import 'package:sorting_sandbox/misc.dart';

class GnomeSort extends SortingAlgorithm {
  void sort(list, scratch) {
    int i = 0;

    while (i < list.length) {
      if (i == 0 || list[i - 1] <= list[i])
        i++;
      else {
        list.swap(i, i - 1);
        i--;
      }
    }
  }
}
