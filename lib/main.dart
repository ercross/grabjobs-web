import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:get/utils.dart';
import 'package:hovering/hovering.dart';

import 'package:http/http.dart' as http;
import 'package:searchfield/searchfield.dart';

import 'models.dart';

void main() {
  runApp(const Grabjobs());
}

class Controller extends GetxController {
  String currentTitle = "";

  List<Job> jobsNearby = [];
  bool isLoading = false;

  changeTitle(String title) {
    currentTitle = title;
    isLoading = true;
    update();
    final url = Uri.parse(
        "$baseUrl/top-jobs/around-me?latitude=${myLocation.latitude}&longitude=${myLocation.longitude}&title=$currentTitle");
    http.get(url).then((response) {
      isLoading = false;
      final data = jsonDecode(response.body);

      jobsNearby = Job.multipleFromJson(data["data"]);
      update();
    }).onError((error, stackTrace) {
      isLoading = false;
      update();
    });

    update();
  }
}

const baseUrl = "https://gjb.alopos.co/api/v1/jobs";
const arbitraryLocation = Location(longitude: 103.904, latitude: 1.33642);
const textBlack = Color.fromARGB(255, 25, 26, 32);
const myLocation = Location(latitude: 1.32443, longitude: 103.878);

class Grabjobs extends StatelessWidget {
  const Grabjobs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.put(Controller());
    return MaterialApp(
      color: Colors.grey.shade50,
      title: 'Grabjobs',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Grabjobs",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(50, 30, 50, 40),
          child: Row(
            children: [
              const Flexible(flex: 2, child: JobsByTitle()),
              const SizedBox(
                width: 20,
              ),
              Flexible(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: JobsOnMap()),
                    const SizedBox(
                      height: 13,
                    ),
                    GetBuilder<Controller>(
                      builder: (contr) => Text(
                        "${contr.currentTitle} jobs within 5km radius",
                      ),
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    const NearbyJobs()
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class JobsByTitle extends StatefulWidget {
  const JobsByTitle({Key? key}) : super(key: key);

  @override
  State<JobsByTitle> createState() => _JobsByTitleState();
}

class _JobsByTitleState extends State<JobsByTitle> {
  Map<String, List<Job>> _availableJobs = {};
  late final Controller ctrl;
  String selectedTitle = "";

  late final Future _fetchJobs;

  @override
  void initState() {
    super.initState();
    ctrl = Get.find<Controller>();
    _fetchJobs = _fetch();
  }

  Future _fetch() async {
    final url = Uri.parse("$baseUrl/available");
    final response = await http.get(url);
    return Future.value(jsonDecode(response.body));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 8, 5, 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 0.5),
        color: Colors.white,
      ),
      child: Column(
        children: [
          SearchField<String>(
            hint: "Search Jobs",
            suggestions: _availableJobs.keys
                .map(
                  (title) => SearchFieldListItem<String>(
                    title,
                    item: title,
                  ),
                )
                .toList(),
          ),
          const SizedBox(
            height: 10,
          ),
          Expanded(
            child: FutureBuilder(
              future: _fetchJobs,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Error fetching available jobs!!!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.red),
                    ),
                  );
                }

                if (snapshot.hasData) {
                  final response = snapshot.data as Map<String, dynamic>;
                  final Map<String, List<Job>> availableJobs = {};
                  response["data"].forEach((title, jobs) {
                    availableJobs[title] = Job.multipleFromJson(jobs);
                  });

                  _availableJobs = availableJobs;

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: _availableJobs.keys
                        .map<Widget>((title) => InkWell(
                              onTap: () {
                                if (ctrl.isLoading) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                          content:
                                              Text("App is loading data...")));
                                  return;
                                }
                                setState(() => selectedTitle = title);
                                ctrl.changeTitle(title);
                              },
                              child: Container(
                                height: 50,
                                width: 70,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.grey, width: 0.5),
                                  color: ctrl.currentTitle == title
                                      ? Colors.orange
                                      : CupertinoColors.systemGrey6,
                                ),
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 14, color: textBlack),
                                ),
                              ),
                            ))
                        .toList(),
                  );
                }

                return const Center(
                  child: SizedBox(
                      height: 25,
                      width: 25,
                      child: CircularProgressIndicator.adaptive(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      )),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class JobsOnMap extends StatelessWidget {
  const JobsOnMap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final height = Get.height * 0.4;
    final width = Get.width * 0.6;
    return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(8)),
        child: GetBuilder<Controller>(
          builder: (ctrl) => Visibility(
            visible: !ctrl.isLoading || ctrl.jobsNearby.isEmpty,
            replacement: const LoadingIndicator(),
            child: Stack(
              children: ctrl.jobsNearby
                  .map<Positioned>((job) => Positioned(
                      bottom: job.location.longitude + Random().nextInt(400),
                      left: job.location.latitude + Random().nextInt(200),
                      child: SelectedMapPoint(job)))
                  .toList(),
            ),
          ),
        ));
  }
}

class MapPoint extends StatelessWidget {
  final Job job;
  const MapPoint(this.job, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      Colors.grey,
      Colors.grey.shade500,
      Colors.grey.shade600,
      Colors.grey.shade700,
      Colors.grey.shade800,
      Colors.blueGrey,
      Colors.blue.shade400,
      Colors.red.shade100,
      Colors.red.shade200,
      Colors.brown.shade200,
    ];
    return HoverCrossFadeWidget(
      duration: const Duration(milliseconds: 350),
      firstChild:
          Icon(Icons.circle, size: 12, color: colors[Random().nextInt(9)]),
      secondChild: Card(
          elevation: 8,
          color: Colors.white,
          child: Text(
              "${job.title}\n${job.location.longitude.toStringAsFixed(5)},${job.location.latitude.toStringAsFixed(5)}")),
    );
  }
}

class SelectedMapPoint extends StatelessWidget {
  final Job job;
  const SelectedMapPoint(this.job, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.location_on_outlined, color: Colors.green, size: 25),
        MapPoint(job)
      ],
    );
  }
}

class NearbyJobs extends StatelessWidget {
  const NearbyJobs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 60,
        width: double.infinity,
        child: GetBuilder<Controller>(
          builder: (ctrl) => Visibility(
            visible: !ctrl.isLoading,
            replacement: const LoadingIndicator(),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: ctrl.jobsNearby
                  .map<Widget>((job) => Container(
                        color: Colors.blueGrey,
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(3),
                        height: 50,
                        width: 80,
                        child: Text(
                          job.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ));
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
          height: 25,
          width: 25,
          child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          )),
    );
  }
}
