import 'package:flutter/material.dart';
import 'package:sorting_sandbox/misc.dart';

class BubbleSortNHCham extends SortingAlgorithm {
  get name => 'Bubble Sort';
  get color => Colors.green;
  get author => 'nh_cham';

  void sort(Elements list, Elements scratch) {
    int length = list.length;
    for (int i = 0; i < length; i++) {
      for (int j = 0; j < length - i - 1; j++) {
        if (list[j] > list[j + 1]) list.swap(j, j + 1);
      }
    }
  }
}
