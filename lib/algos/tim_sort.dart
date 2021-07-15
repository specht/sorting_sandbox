import 'package:sorting_sandbox/misc.dart';
import 'dart:math';

class TimSort extends SortingAlgorithm {
  void sort(list, scratch) {
    const int run = 32;
    int n = list.length;
    for (int i = 0; i < n; i += run) {
      insertionSort(list, i, min(i + run - 1, n - 1));
    }

    for (int size = run; size < n; size *= 2) {
      for (int left = 0; left < n; left += size * 2) {
        int middle = left + size - 1;
        int right = min(left + 2 * size - 1, n - 1);
        if (middle < right) merge(list, scratch, left, middle, right);
      }
    }
  }

  void insertionSort(list, int left, int right) {
    for (int i = left + 1; i <= right; i++) {
      Element temp = list[i];
      int j = i - 1;
      while (j >= left && list[j] > temp) {
        list[j + 1] = list[j];
        j--;
      }
      list[j + 1] = temp;
    }
  }

  void merge(list, scratch, int left, int middle, int right) {
    int length1 = middle - left + 1, length2 = right - middle;
    int lo = left;
    int ro = left + length1;

    for (int i = 0; i < length1; i++) scratch[lo + i] = list[left + i];
    for (int i = 0; i < length2; i++) scratch[ro + i] = list[middle + 1 + i];

    int i = 0, j = 0, k = left;
    while (i < length1 && j < length2) {
      if (scratch[lo + i] <= scratch[ro + j]) {
        list[k] = scratch[lo + i];
        i++;
      } else {
        list[k] = scratch[ro + j];
        j++;
      }
      k++;
    }

    while (i < length1) {
      list[k] = scratch[lo + i];
      k++;
      i++;
    }

    while (j < length2) {
      list[k] = scratch[ro + j];
      k++;
      j++;
    }
  }
}
