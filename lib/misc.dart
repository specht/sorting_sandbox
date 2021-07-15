import 'dart:io';
import 'dart:isolate';
import 'dart:developer' as developer;
import 'package:sorting_sandbox/main.dart' show SortWidgetState;
import 'package:path_provider/path_provider.dart';

class Element {
  int a;
  SortingAlgorithm _algo;

  Element(this._algo, this.a);

  bool operator <(Element other) {
    _algo.c_count++;
    _algo.update();
    return a < other.a;
  }

  bool operator <=(Element other) {
    _algo.c_count++;
    _algo.update();
    return a <= other.a;
  }

  bool operator >(Element other) {
    _algo.c_count++;
    _algo.update();
    return a > other.a;
  }

  bool operator >=(Element other) {
    _algo.c_count++;
    _algo.update();
    return a >= other.a;
  }

  bool operator ==(other) {
    _algo.c_count++;
    _algo.update();
    return a == (other as Element).a;
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
    _algo.r_count++;
    readMarker = index;
    _algo.update();
    return _elements[index];
  }

  void operator []=(int index, Element value) {
    _algo.w_count++;
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
  int r_count = 0, w_count = 0, c_count = 0;
  int update_count = 0;
  Elements? list, scratch;
  int updateFrequency = 1;
  int updateDelayMilliseconds = 1;
  File? settingsFile;

  SortingAlgorithm();

  void setSendPort(port) => sendPort = port;
  void sort(Elements list, Elements scratch);
  void setElements(Elements list, Elements scratch) async {
    this.list = list;
    this.scratch = scratch;
    // final Directory? directory = await getApplicationDocumentsDirectory();
    // if (directory != null) {
    //   settingsFile = File('${directory.path}/speed.txt');
    //   String s = await settingsFile!.readAsString();
    //   int speed = int.parse(s);
    //   developer.log('speed is $speed');
    // }
  }

  void update({bool force = false}) {
    update_count++;
    if (force || (update_count >= updateFrequency && updateFrequency > 0)) {
      sendPort!.send(['update_counts', r_count, w_count, c_count]);
      sendPort!.send([
        'update_numbers',
        [for (Element x in list!._elements) x.a],
        [for (Element x in scratch!._elements) x.a],
        list!.readMarker,
        list!.writeMarker,
        scratch!.readMarker,
        scratch!.writeMarker,
      ]);
      update_count = 0;
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
