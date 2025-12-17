class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.designation,
    required this.hospital,
    required this.centre,
    required this.employeeId,
    required this.phone,
    required this.email,
    required this.dob,
  });

  final String id;
  final String name;
  final int age;
  final String designation;
  final String hospital;
  final String centre;
  final String employeeId;
  final String phone;
  final String email;
  final DateTime dob;

  Profile copyWith({
    String? id,
    String? name,
    int? age,
    String? designation,
    String? hospital,
    String? centre,
    String? employeeId,
    String? phone,
    String? email,
    DateTime? dob,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      designation: designation ?? this.designation,
      hospital: hospital ?? this.hospital,
      centre: centre ?? this.centre,
      employeeId: employeeId ?? this.employeeId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dob: dob ?? this.dob,
    );
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      name: map['name'] as String,
      age: (map['age'] as num).toInt(),
      designation: map['designation'] as String,
      hospital: map['hospital'] as String,
      centre: map['centre'] as String,
      employeeId: map['employee_id'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String,
      dob: DateTime.parse(map['dob'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    final date = dob.toIso8601String().split('T').first;
    return {
      'id': id,
      'name': name,
      'age': age,
      'designation': designation,
      'hospital': hospital,
      'centre': centre,
      'employee_id': employeeId,
      'phone': phone,
      'email': email,
      'dob': date,
    };
  }
}
