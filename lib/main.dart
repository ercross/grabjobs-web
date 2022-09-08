import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/utils.dart';
import 'package:hovering/hovering.dart';

import 'package:http/http.dart' as http;
import 'package:searchfield/searchfield.dart';

import 'models.dart';

void main() {
  runApp(const Grabjobs());
}

//const baseUrl = "https://grabjobs.alopos.co/api/v1/jobs";
const baseUrl = "http://localhost:4046/api/v1/jobs";
const textBlack = Color.fromARGB(255, 25, 26, 32);
const myLocation = Location(latitude: 1.27828, longitude: 103.842);

class Grabjobs extends StatelessWidget {
  const Grabjobs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  children: const [
                    Expanded(child: JobsOnMap()),
                    SizedBox(
                      height: 13,
                    ),
                    Text(
                      "Nearby jobs within 5km radius",
                    ),
                    SizedBox(
                      height: 7,
                    ),
                    NearbyJobs()
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

  late final Future _fetchJobs;

  @override
  void initState() {
    super.initState();
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
                        .map<Widget>((title) => Container(
                              height: 50,
                              width: 70,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey, width: 0.5),
                                color: CupertinoColors.systemGrey6,
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

class JobsOnMap extends StatefulWidget {
  const JobsOnMap({Key? key}) : super(key: key);

  @override
  State<JobsOnMap> createState() => _JobsOnMapState();
}

class _JobsOnMapState extends State<JobsOnMap> {
  late final Future _fetchJobs;

  @override
  void initState() {
    super.initState();
    _fetchJobs = _fetch();
  }

  Future _fetch() async {
    final url = Uri.parse(
        "$baseUrl/top-jobs/around-me?latitude=1.2&longitude=2.4&title=account executive");
    final response = await http.get(url);
    return Future.value(jsonDecode(response.body));
  }

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
      child: FutureBuilder(
          future: _fetchJobs,
          builder: (_, snapshot) {
            if (snapshot.hasData) {
              final data = snapshot.data as Map<String, dynamic>;
              final List<Job> jobs = Job.multipleFromJson(data["data"]);
              return Stack(
                children: [
                  Positioned(
                      top: jobs.first.location.longitude,
                      left: jobs.first.location.latitude,
                      child: SelectedMapPoint(jobs.first.location)),
                  ...jobs.map<Positioned>((job) => Positioned(
                      bottom: job.location.longitude + Random().nextInt(400),
                      left: job.location.latitude + Random().nextInt(200),
                      child: MapPoint(job.location)))
                ],
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  "Error fetching available jobs!!!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.red),
                ),
              );
            }
            return const Center(
                child: SizedBox(
                    height: 25,
                    width: 25,
                    child: CircularProgressIndicator.adaptive(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    )));
          }),
    );
  }
}

class MapPoint extends StatelessWidget {
  final Location location;
  const MapPoint(this.location, {Key? key}) : super(key: key);

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
          child: Text("${location.longitude},${location.latitude}")),
    );
  }
}

class SelectedMapPoint extends StatelessWidget {
  final Location location;
  const SelectedMapPoint(this.location, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.location_on_outlined, color: Colors.green, size: 25),
        MapPoint(location)
      ],
    );
  }
}

class NearbyJobs extends StatefulWidget {
  const NearbyJobs({Key? key}) : super(key: key);

  @override
  State<NearbyJobs> createState() => _NearbyJobsState();
}

class _NearbyJobsState extends State<NearbyJobs> {
  List<Job> _jobsNearby = [];

  late final Future _fetchJobs;

  @override
  void initState() {
    super.initState();
    _fetchJobs = _fetch();
  }

  Future _fetch() async {
    final url = Uri.parse(
        "$baseUrl/nearby?latitude=${myLocation.latitude}&longitude=${myLocation.longitude}&radius=5.0");
    final response = await http.get(url);
    return Future.value(jsonDecode(response.body));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: FutureBuilder(
        future: _fetchJobs,
        builder: (_, snapshot) {
          if (snapshot.hasData) {
            final response = snapshot.data as Map<String, dynamic>;
            final data = response["data"];
            _jobsNearby = Job.multipleFromJson(data);
            return ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: _jobsNearby
                  .map<Widget>((job) => Container(
                        color: Colors.blueGrey,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(3),
                        height: 50,
                        width: 80,
                        child: Text(
                          job.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ))
                  .toList(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error fetching jobs nearby!!!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.red),
              ),
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
    );
  }
}
