import 'package:sorting_sandbox/misc.dart';

class MergeSort extends SortingAlgorithm {
  void sort(list, scratch) {
    bisect(list, scratch, 0, list.length);
  }

  void bisect(list, scratch, int offset, int count) {
    if (count > 1) {
      int half_count = count ~/ 2;
      bisect(list, scratch, offset, half_count);
      bisect(list, scratch, offset + half_count, count - half_count);
      if (list[offset + half_count - 1] > list[offset + half_count]) {
        int i = offset;
        int p = offset + half_count;
        int o = offset;
        while (o < offset + half_count && p < offset + count) {
          scratch[i++] = list[(list[o] < list[p]) ? o++ : p++];
        }
        while (o < offset + half_count) scratch[i++] = list[o++];
        while (p < offset + count) scratch[i++] = list[p++];
        for (int i = 0; i < count; i++) list[i + offset] = scratch[i + offset];
      }
    }
  }
}
