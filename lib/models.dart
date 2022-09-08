import 'package:equatable/equatable.dart';

class Job extends Equatable {
  final String title;
  final Location location;

  const Job({required this.title, required this.location});

  Job.fromJson(Map<String, dynamic> json)
      : title = json["title"],
        location = Location.fromJson(json["location"]);

  static List<Job> multipleFromJson(List<dynamic> list) {
    return list.map<Job>((job) => Job.fromJson(job)).toList();
  }

  @override
  List<Object?> get props => [title, location];
}

class Location extends Equatable {
  final double latitude;
  final double longitude;

  const Location({required this.latitude, required this.longitude});

  Location.fromJson(Map<String, dynamic> json)
      : longitude = json["longitude"],
        latitude = json["latitude"];

  @override
  List<Object?> get props => [latitude, longitude];
}
