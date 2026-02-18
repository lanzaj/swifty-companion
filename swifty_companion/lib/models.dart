class User {
  final int id;
  final String login;
  final String email;
  final String displayName;
  final String imageUrl;
  final int wallet;
  final int correctionPoint;
  final String location;
  final List<Skill> skills;
  final List<Project> projects;

  User({
    required this.id,
    required this.login,
    required this.email,
    required this.displayName,
    required this.imageUrl,
    required this.wallet,
    required this.correctionPoint,
    required this.location,
    required this.skills,
    required this.projects,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Aggregate skills from all cursuses
    // Use a map to handle duplicates, keeping the highest level
    Map<String, double> skillsMap = {};

    if (json['cursus_users'] != null) {
      for (var cursus in json['cursus_users'] as List) {
        if (cursus['skills'] != null) {
          for (var skillJson in cursus['skills'] as List) {
            final String name = skillJson['name'];
            final double level = (skillJson['level'] as num).toDouble();

            if (!skillsMap.containsKey(name) || skillsMap[name]! < level) {
              skillsMap[name] = level;
            }
          }
        }
      }
    }

    var rawSkills = skillsMap.entries
        .map((e) => {'name': e.key, 'level': e.value})
        .toList();

    // Sort by level descending
    rawSkills.sort(
      (a, b) => (b['level'] as double).compareTo(a['level'] as double),
    );

    // 42 API structure for projects is complex. We usually look at 'projects_users'.
    var rawProjects = json['projects_users'] as List? ?? [];

    return User(
      id: json['id'],
      login: json['login'],
      email: json['email'],
      displayName: json['displayname'],
      imageUrl: json['image']['link'] ?? '',
      wallet: json['wallet'] ?? 0,
      correctionPoint: json['correction_point'] ?? 0,
      location: json['location'] ?? 'Unavailable',
      skills: rawSkills.map((s) => Skill.fromJson(s)).toList(),
      projects: rawProjects.map((p) => Project.fromJson(p)).toList(),
    );
  }
}

class Skill {
  final String name;
  final double level;

  Skill({required this.name, required this.level});

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(name: json['name'], level: (json['level'] as num).toDouble());
  }
}

class Project {
  final String name;
  final String status; // "finished", "in_progress", etc.
  final bool? validated; // true if validated
  final int? finalMark;

  Project({
    required this.name,
    required this.status,
    this.validated,
    this.finalMark,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['project']['name'],
      status: json['status'],
      validated: json['validated?'],
      finalMark: json['final_mark'],
    );
  }
}
