import 'package:sorting_sandbox/misc.dart';

class QuickSort extends SortingAlgorithm {
  void sort(list, scratch) {
    quicksort(list, 0, list.length - 1);
  }

  void quicksort(list, int left, int right) {
    if (left < right) {
      int pivot = partition(list, left, right);
      quicksort(list, left, pivot - 1);
      quicksort(list, pivot + 1, right);
    }
  }

  int partition(list, int left, int right) {
    int i = left;
    int j = right - 1;
    Element pivot = list[right];

    while (i < j) {
      while (i < right && list[i] < pivot) i++;
      while (j > left && list[j] >= pivot) j--;
      if (i < j) list.swap(i, j);
    }
    if (list[i] > pivot) list.swap(i, right);
    return i;
  }
}
