class User {
  String name;
  String surname;
  String birthDate;
  String placeOfStudy;
  String cityOfLiving;
  int id;
  String faceEmbedding;

  User({
    required this.name,
    required this.surname,
    required this.birthDate,
    required this.placeOfStudy,
    required this.cityOfLiving,
    required this.id,
    this.faceEmbedding = '',
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'surname': surname,
      'birthDate': birthDate,
      'placeOfStudy': placeOfStudy,
      'cityOfLiving': cityOfLiving,
      'id': id,
      'faceEmbedding': faceEmbedding,
    };
  }

  static User fromFirestore(Map<String, dynamic> data) {
    return User(
      name: data['name'],
      surname: data['surname'],
      birthDate: data['birthDate'],
      placeOfStudy: data['placeOfStudy'],
      cityOfLiving: data['cityOfLiving'],
      id: data['id'],
      faceEmbedding: data['faceEmbedding'] ?? '',
    );
  }
}
