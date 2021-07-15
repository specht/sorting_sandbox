import 'package:sorting_sandbox/misc.dart';

class HeapSort extends SortingAlgorithm {
  void sort(list, scratch) {
    for (int i = list.length ~/ 2; i >= 0; i--) heapify(list, list.length, i);
    for (int i = list.length - 1; i >= 0; i--) {
      list.swap(i, 0);
      heapify(list, i, 0);
    }
  }

  void heapify(list, int n, int i) {
    int largest = i;
    int l = 2 * i + 1;
    int r = 2 * i + 2;

    if (l < n && list[l] > list[largest]) {
      largest = l;
    }

    if (r < n && list[r] > list[largest]) {
      largest = r;
    }

    if (largest != i) {
      list.swap(i, largest);
      heapify(list, n, largest);
    }
  }
}
