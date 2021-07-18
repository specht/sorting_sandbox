import 'package:sorting_sandbox/misc.dart';

class RadixSort extends SortingAlgorithm {
  Element getMax(list) {
    Element m = list[0];
    for (int i = 1; i < list.length; i++) if (list[i] > m) m = list[i];
    return m;
  }

  void countSort(list, scratch, int exp) {
    List<int> count = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    for (int i = 0; i < list.length; i++) count[(list[i].a ~/ exp) % 10]++;
    for (int i = 1; i < 10; i++) count[i] += count[i - 1];
    for (int i = list.length - 1; i >= 0; i--) {
      scratch[count[(list[i].a ~/ exp) % 10] - 1] = list[i];
      count[(list[i].a ~/ exp) % 10]--;
    }

    for (int i = 0; i < list.length; i++) list[i] = scratch[i];
  }

  void sort(list, scratch) {
    int m = getMax(list).a;
    for (int exp = 1; m ~/ exp > 0; exp *= 10) countSort(list, scratch, exp);
  }
}
