import 'dart:developer' as developer;
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'algos/bubble_sort_nhcham.dart';
import 'misc.dart';

final List<SortingAlgorithm> algos = [
  new BubbleSortNHCham(),
];

List speedSettings = [
  [1, 100],
  [2, 10],
  [5, 10],
  [10, 10],
  [20, 10],
  [500, 5],
  [10000, 0]
];

void main() {
  runApp(new RootApp());
}

class RootApp extends StatelessWidget {
  const RootApp({Key? key}) : super(key: key);

  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Sorting Sandbox',
        home: SortWidget(),
        theme: ThemeData(primarySwatch: Colors.green));
  }
}

class SortWidget extends StatefulWidget {
  const SortWidget({Key? key}) : super(key: key);

  SortWidgetState createState() => SortWidgetState();
}

class SortWidgetState extends State<SortWidget> {
  List<int> numbers = [];
  List<int> scratch = [];
  SortingAlgorithm? algo;
  int rCount = 0;
  int wCount = 0;
  int cCount = 0;
  int magnitude = 0;
  double exponent = 0.3;
  bool isSorted = false;
  int? a, b, c, d;
  int speed = 3;
  int sortingAlgoIndex = 0;
  Map<int, List<Benchmark>> benchmarkByAlgo = {};
  int minX = 0, maxX = 1, minY = 0, maxY = 1;
  bool logx = false, logy = false;
  List<int>? algoRanking;

  Isolate? oneShotIsolate;
  ReceivePort? oneShotReceivePort;

  Isolate? benchmarkIsolate;
  ReceivePort? benchmarkReceivePort;

  void initState() {
    super.initState();
    shuffle();
    setSpeed(3);
  }

  void _startOneShotIsolate() async {
    oneShotReceivePort = ReceivePort();
    SendPort sendPort = oneShotReceivePort!.sendPort;
    var info = [
      sendPort,
      numbers,
      sortingAlgoIndex,
      speedSettings[speed][0],
      speedSettings[speed][1]
    ];
    oneShotIsolate = await Isolate.spawn(oneShotEntryPoint, info, paused: true);
    setState(() {});
    oneShotIsolate!.addOnExitListener(sendPort);
    oneShotReceivePort!.listen((data) {
      if (data == null) {
        updateIsSorted();
        setState(() {
          a = b = c = d = null;
          oneShotIsolate = null;
          oneShotReceivePort = null;
        });
        return;
      }
      String command = data[0];
      if (command == 'update_counts') {
        setState(() {
          rCount = data[1];
          wCount = data[2];
          cCount = data[3];
        });
      } else if (command == 'update_numbers') {
        setState(() {
          numbers = data[1];
          scratch = data[2];
          a = data[3];
          b = data[4];
          c = data[5];
          d = data[6];
        });
      } else if (command == 'finished') {
        updateIsSorted();
        setState(() {
          a = b = c = d = null;
          oneShotIsolate = null;
          oneShotReceivePort = null;
        });
      }
    });
    oneShotIsolate!.resume(oneShotIsolate!.pauseCapability!);
  }

  static void oneShotEntryPoint(var info) {
    var sendPort = info[0] as SendPort;
    var numbers = info[1];
    var algoInfo = algos[info[2]];
    var algo = algoInfo;
    // SortingAlgorithm algo = ctor();
    algo.updateFrequency = info[3];
    algo.updateDelayMilliseconds = info[4];
    algo.setSendPort(sendPort);
    Elements elNumbers = Elements(algo);
    Elements elScratch = Elements(algo);
    elNumbers.init(numbers);
    // ignore: unused_local_variable
    elScratch.init([for (int i in numbers) 0]);
    algo.setElements(elNumbers, elScratch);
    algo.sort(elNumbers, elScratch);
    algo.update(force: true);
  }

  void _startBenchmarkIsolate(String mode) async {
    benchmarkReceivePort = ReceivePort();
    SendPort sendPort = benchmarkReceivePort!.sendPort;
    var info = [sendPort, mode];
    benchmarkIsolate =
        await Isolate.spawn(benchmarkEntryPoint, info, paused: true);
    setState(() {
      benchmarkByAlgo = {};
      algoRanking = null;
    });
    benchmarkIsolate!.addOnExitListener(sendPort);
    benchmarkReceivePort!.listen((data) {
      if (data == null || data[0] == 'finished') {
        setState(() {
          benchmarkIsolate = null;
          benchmarkReceivePort = null;
          List listTemp = algos.mapIndexed<List>((index, entry) {
            var b = benchmarkByAlgo[index]!.last;
            return [index, b.r + b.w + b.c, b.isSorted ? 1 : 0];
          }).toList();
          listTemp.sort((a, b) {
            if (a[2] == b[2])
              return a[1].compareTo(b[1]);
            else
              return b[2].compareTo(a[2]);
          });
          algoRanking = listTemp.map<int>((entry) => entry[0]).toList();
        });
      }
      if (data != null && data[0] == 'update') {
        setState(() {
          int algoIndex = data[1];
          benchmarkByAlgo[algoIndex] ??= [];
          benchmarkByAlgo[algoIndex]!
              .add(Benchmark(data[2], data[3], data[4], data[5], data[6]));
        });
      }
    });
    benchmarkIsolate!.resume(benchmarkIsolate!.pauseCapability!);
  }

  static void benchmarkEntryPoint(var info) {
    var sendPort = info[0] as SendPort;
    String mode = info[1];
    for (int count in [50, 150, 250, 350, 450, 550, 650, 750, 850, 950]) {
      for (int i = 0; i < algos.length; i++) {
        SortingAlgorithm entry = algos[i];
        String algoName = entry.name;
        developer
            .log("Running $algoName (${entry.author}) with $count elements...");
        SortingAlgorithm algo = entry;
        List<int> _numbers = [for (int i = 0; i < count; i++) i + 1];
        if (mode == 'shuffled')
          _numbers.shuffle();
        else if (mode == 'reversed') _numbers = List.from(_numbers.reversed);
        List<int> _scratch = [for (int i = 0; i < count; i++) 0];
        Elements numbers = Elements(algo);
        Elements scratch = Elements(algo);
        algo.updateFrequency = 0;
        numbers.init(_numbers);
        scratch.init(_scratch);
        algo.sort(numbers, scratch);
        bool isSorted = true;
        for (int i = 0; isSorted && i < numbers.length; i++) {
          if (numbers[i].a != i + 1) isSorted = false;
        }

        developer.log(
            "reads: ${algo.rCount}, writes: ${algo.wCount}, compares: ${algo.cCount}, sorted: ${isSorted}");
        sendPort.send([
          'update',
          i,
          count,
          algo.rCount,
          algo.wCount,
          algo.cCount,
          isSorted
        ]);
      }
    }
    sendPort.send(['finished']);
  }

  String itos(int i) {
    if (i < 1e3) {
      return i.toString();
    } else if (i < 1e6) {
      return "${i ~/ 1e3}.${(i % 1e3) ~/ 1e2}k";
    } else if (i < 1e9) {
      return "${i ~/ 1e6}.${(i % 1e6) ~/ 1e5}M";
    } else if (i < 1e12) {
      return "${i ~/ 1e9}.${(i % 1e9) ~/ 1e8}G";
    } else if (i < 1e15) {
      return "${i ~/ 1e12}.${(i % 1e12) ~/ 1e11}T";
    }
    return i.toString();
  }

  bool _isSorted() {
    if (numbers.isEmpty) return false;
    for (int i = 0; i < numbers.length; i++) {
      if (numbers[i] != i + 1) return false;
    }
    return true;
  }

  void updateIsSorted() {
    setState(() {
      isSorted = _isSorted();
    });
  }

  void shuffle() {
    setState(() {
      int count = (window.physicalSize.width - 24) ~/ 15;
      count = (count * pow(2.0, magnitude)).toInt();
      numbers.clear();
      for (int i = 0; i < count; i++) numbers.add(i + 1);
      scratch.clear();
      for (int i = 0; i < count; i++) scratch.add(0);
      numbers.shuffle();
      updateIsSorted();
    });
  }

  void stop() {
    if (oneShotIsolate != null)
      oneShotIsolate!.kill(priority: Isolate.immediate);
    setState(() {
      a = b = c = d = null;
      updateIsSorted();
    });
  }

  void setSpeed(int speed) {
    this.speed = speed;
  }

  Widget build(BuildContext context) {
    developer.log(algoRanking.toString());
    final PageController pageController = PageController(initialPage: 0);
    List<Container> algoLegend = [];
    for (int k = 0; k < algos.length; k++) {
      int i = k;
      if (algoRanking != null && algoRanking!.length == algos.length)
        i = algoRanking![k];
      String algoName = algos[i].name;
      String algoAuthor = algos[i].author;
      bool algoFailed = false;
      if (benchmarkByAlgo != null &&
          benchmarkByAlgo.containsKey(i) &&
          !benchmarkByAlgo[i]!.last.isSorted) algoFailed = true;
      algoLegend.add(
        Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Container(
              decoration: new BoxDecoration(
                borderRadius: new BorderRadius.circular(4.0),
                color: (benchmarkByAlgo.containsKey(i)
                        ? algos[i].color
                        : Colors.black38)
                    .withOpacity(0.15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                    (algoRanking == null
                            ? ''
                            : (algoFailed ? '' : '${k + 1}. ')) +
                        algoName +
                        ' (' +
                        algoAuthor +
                        ')',
                    style: TextStyle(
                      decoration:
                          algoFailed ? TextDecoration.lineThrough : null,
                      fontWeight:
                          algoFailed ? FontWeight.normal : FontWeight.bold,
                      color: benchmarkByAlgo.containsKey(i)
                          ? algos[i].color
                          : Colors.black38,
                    )),
              ),
            )),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text("Let's sort some numbers! 🥳"),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: PageView(
        controller: pageController,
        children: [
          Stack(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: pow(numbers.length, exponent).toDouble(),
                          barTouchData: BarTouchData(
                            enabled: false,
                          ),
                          gridData: FlGridData(
                              drawHorizontalLine: false,
                              drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            show: false,
                          ),
                          borderData: FlBorderData(
                            show: false,
                          ),
                          barGroups: numbers
                              .asMap()
                              .entries
                              .map<BarChartGroupData>((entry) {
                            int x = entry.key;
                            int y = entry.value;
                            return BarChartGroupData(
                              x: x,
                              barRods: [
                                BarChartRodData(
                                    toY: pow(y, exponent).toDouble(),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: x == a
                                          ? [Colors.orange, Colors.orange]
                                          : x == b
                                              ? [Colors.red, Colors.red]
                                              : [
                                                  Colors.greenAccent,
                                                  Colors.lightBlueAccent,
                                                ],
                                    ),
                                    width: 2)
                              ],
                            );
                          }).toList(),
                        ),
                        swapAnimationDuration: Duration(milliseconds: 0),
                      ),
                    ),
                    Text(
                      'List to be sorted',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Text("Size: ${numbers.length}"),
                        Text("Reads: ${itos(rCount)}"),
                        Text("Writes: ${itos(wCount)}"),
                        Text("Comparisons: ${itos(cCount)}"),
                      ],
                    ),
                    Divider(),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: pow(scratch.length, exponent).toDouble(),
                          barTouchData: BarTouchData(
                            enabled: false,
                          ),
                          gridData: FlGridData(
                              drawHorizontalLine: false,
                              drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            show: false,
                          ),
                          borderData: FlBorderData(
                            show: false,
                          ),
                          barGroups: scratch
                              .asMap()
                              .entries
                              .map<BarChartGroupData>((entry) {
                            int x = entry.key;
                            int y = entry.value;
                            return BarChartGroupData(
                              x: x,
                              barRods: [
                                BarChartRodData(
                                    toY: pow(y, exponent).toDouble(),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: x == c
                                          ? [Colors.orange, Colors.orange]
                                          : x == d
                                              ? [Colors.red, Colors.red]
                                              : [
                                                  Color(0xff808080),
                                                  Color(0xffe0e0e0),
                                                ],
                                    ),
                                    width: 2)
                              ],
                            );
                          }).toList(),
                        ),
                        swapAnimationDuration: Duration(milliseconds: 100),
                      ),
                    ),
                    Text(
                      'Temporary list',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('Algorithm:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        DropdownButton<int>(
                          value: sortingAlgoIndex,
                          items: algos
                              .mapIndexed((i, x) => DropdownMenuItem<int>(
                                  value: i,
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.circle,
                                          color: x.color,
                                          size: 16,
                                        ),
                                      ),
                                      Text(x.name,
                                          style: TextStyle(fontSize: 16)),
                                      Text(" (${x.author})",
                                          style: TextStyle(fontSize: 13)),
                                    ],
                                  )))
                              .toList(),
                          onChanged: oneShotIsolate != null
                              ? null
                              : (value) {
                                  setState(() => sortingAlgoIndex = value!);
                                },
                        ),
                      ],
                    ),
                    // Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            label: 'Animation Speed',
                            value: speed.toDouble(),
                            min: 0,
                            max: 6,
                            divisions: 6,
                            onChanged: oneShotIsolate != null
                                ? null
                                : (v) {
                                    setState(() => setSpeed(v.toInt()));
                                  },
                          ),
                        ),
                        SizedBox(
                          child: Icon(Icons.speed),
                          width: 60,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Icon(Icons.flash_on_outlined),
                        Expanded(
                          child: Slider(
                            activeColor: Colors.blue,
                            inactiveColor: Colors.blue[100],
                            label: 'List Size',
                            value: magnitude.toDouble(),
                            min: 0.0,
                            max: 6.0,
                            divisions: 6,
                            onChanged: oneShotIsolate != null
                                ? null
                                : (v) {
                                    setState(() {
                                      magnitude = v.toInt();
                                      shuffle();
                                    });
                                  },
                          ),
                        ),
                        SizedBox(
                            child: Text("n = ${itos(numbers.length)}"),
                            width: 60)
                      ],
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                            onPressed: oneShotIsolate != null
                                ? null
                                : () {
                                    shuffle();
                                    updateIsSorted();
                                  },
                            icon: Icon(Icons.shuffle)),
                        IconButton(
                            onPressed: oneShotIsolate != null
                                ? null
                                : () {
                                    setState(() {
                                      numbers = List.from(numbers.reversed);
                                    });
                                    updateIsSorted();
                                  },
                            icon: Icon(Icons.compare_arrows_outlined)),
                        IconButton(
                            onPressed: oneShotIsolate != null
                                ? null
                                : () => _startOneShotIsolate(),
                            icon: Icon(Icons.play_arrow)),
                        IconButton(
                            onPressed:
                                oneShotIsolate != null ? () => stop() : null,
                            icon: Icon(Icons.stop)),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            color: Color.fromARGB(32, 0, 0, 0), blurRadius: 10)
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(24))),
                  child: Icon(
                    isSorted ? Icons.check : Icons.error_outline,
                    color: isSorted ? Colors.green : Colors.redAccent,
                    size: 24.0,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Reads + Writes + Comparisons',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        lineBarsData: benchmarkByAlgo
                            .map<int, LineChartBarData>((algoIndex, v) {
                              return MapEntry<int, LineChartBarData>(
                                  algoIndex,
                                  LineChartBarData(
                                    spots: benchmarkByAlgo[algoIndex]!
                                        .map<FlSpot>((entry) {
                                      double x = entry.n.toDouble();
                                      double y = (entry.r + entry.w + entry.c)
                                          .toDouble();
                                      if (logx) x = log(x + 0.001);
                                      if (logy) y = log(y + 0.001);
                                      return FlSpot(x, y);
                                    }).toList(),
                                    isCurved: true,
                                    gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          algos[algoIndex].color ??
                                              Colors.black45,
                                          algos[algoIndex].color ??
                                              Colors.black45
                                        ]),
                                    barWidth: 2,
                                    dashArray: benchmarkByAlgo[algoIndex]!
                                            .last
                                            .isSorted
                                        ? null
                                        : [2, 10],
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(
                                      show: false,
                                    ),
                                    belowBarData: BarAreaData(
                                      show: false,
                                    ),
                                  ));
                            })
                            .values
                            .toList(),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        gridData: FlGridData(
                          show: false,
                        ),
                        titlesData: FlTitlesData(
                          show: false,
                        ),
                      ),
                      swapAnimationDuration:
                          Duration(milliseconds: 200), // Optional
                      swapAnimationCurve: Curves.easeInToLinear, // Optional
                    ),
                  ),
                  Divider(),
                  Wrap(children: algoLegend),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Switch(
                        value: logx,
                        onChanged: (value) {
                          setState(() {
                            logx = value;
                          });
                        },
                      ),
                      Text('log x'),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      Switch(
                        value: logy,
                        onChanged: (value) {
                          setState(() {
                            logy = value;
                          });
                        },
                      ),
                      Text('log y'),
                    ],
                  ),
                  Divider(),
                  Text('Compare all algorithms on lists which are:',
                      textAlign: TextAlign.center),
                  Divider(),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                            onPressed: benchmarkIsolate == null
                                ? () => _startBenchmarkIsolate('shuffled')
                                : null,
                            child: Text('Shuffled')),
                        OutlinedButton(
                            onPressed: benchmarkIsolate == null
                                ? () => _startBenchmarkIsolate('reversed')
                                : null,
                            child: Text('Reversed')),
                        OutlinedButton(
                            onPressed: benchmarkIsolate == null
                                ? () => _startBenchmarkIsolate('sorted')
                                : null,
                            child: Text('Sorted')),
                      ]),
                ]),
          ),
        ],
      ),
    );
  }
}
