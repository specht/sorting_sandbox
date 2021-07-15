import 'package:sorting_sandbox/misc.dart';

class ExchangeSort extends SortingAlgorithm {
  void sort(list, scratch) {
    for (int i = 0; i < list.length - 1; i++) {
      for (int j = i + 1; j < list.length; j++) {
        if (list[i] > list[j]) list.swap(i, j);
      }
    }
  }
}
