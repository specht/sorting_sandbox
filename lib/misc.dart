import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';

class Element {
  int a;
  SortingAlgorithm _algo;

  Element(this._algo, this.a);

  bool operator <(Element other) {
    _algo.cCount++;
    _algo.update();
    return a < other.a;
  }

  bool operator <=(Element other) {
    _algo.cCount++;
    _algo.update();
    return a <= other.a;
  }

  bool operator >(Element other) {
    _algo.cCount++;
    _algo.update();
    return a > other.a;
  }

  bool operator >=(Element other) {
    _algo.cCount++;
    _algo.update();
    return a >= other.a;
  }

  int get hashCode {
    return a;
  }

  bool operator ==(other) {
    _algo.cCount++;
    _algo.update();
    return other is Element && a == other.a;
  }
}

class Elements {
  SortingAlgorithm _algo;
  List<Element> _elements = [];
  int length = 0;
  int? readMarker, writeMarker;

  Elements(this._algo);

  void init(List<int> list) {
    length = list.length;
    _elements = [for (var v in list) Element(_algo, v)];
  }

  Element operator [](int index) {
    _algo.rCount++;
    readMarker = index;
    _algo.update();
    return _elements[index];
  }

  void operator []=(int index, Element value) {
    _algo.wCount++;
    writeMarker = index;
    _algo.update();
    _elements[index] = value;
  }

  void swap(int a, int b) {
    Element temp = this[b];
    this[b] = this[a];
    this[a] = temp;
  }
}

abstract class SortingAlgorithm {
  SendPort? sendPort;
  int rCount = 0, wCount = 0, cCount = 0;
  int updateCount = 0;
  Elements? list, scratch;
  int updateFrequency = 1;
  int updateDelayMilliseconds = 1;
  File? settingsFile;

  get name => '(no name)';
  get color => Colors.black38;
  get author => 'no author';

  // SortingAlgorithm();

  void setSendPort(port) => sendPort = port;
  void sort(Elements list, Elements scratch);
  void setElements(Elements list, Elements scratch) async {
    this.list = list;
    this.scratch = scratch;
  }

  void update({bool force = false}) {
    updateCount++;
    if (force || (updateCount >= updateFrequency && updateFrequency > 0)) {
      sendPort!.send(['update_counts', rCount, wCount, cCount]);
      sendPort!.send([
        'update_numbers',
        [for (Element x in list!._elements) x.a],
        [for (Element x in scratch!._elements) x.a],
        list!.readMarker,
        list!.writeMarker,
        scratch!.readMarker,
        scratch!.writeMarker,
      ]);
      updateCount = 0;
      if (updateDelayMilliseconds > 0)
        sleep(Duration(milliseconds: updateDelayMilliseconds));
    }
    if (force) sendPort!.send(['finished']);
  }
}

class Benchmark {
  final int n, r, w, c;
  Benchmark(this.n, this.r, this.w, this.c);
}
