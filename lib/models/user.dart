class User {
  String name;
  String surname;
  String birthDate;
  String placeOfStudy;
  String cityOfLiving;
  int id;
  String faceEmbedding;
  String? imageUrl;

  User({
    required this.name,
    required this.surname,
    required this.birthDate,
    required this.placeOfStudy,
    required this.cityOfLiving,
    required this.id,
    this.faceEmbedding = '',
    this.imageUrl,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'surname': surname,
      'birthDate': birthDate,
      'placeOfStudy': placeOfStudy,
      'cityOfLiving': cityOfLiving,
      'id': id,
      'faceEmbedding': imageUrl ?? '',
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
      imageUrl: data['faceEmbedding'] as String?,
    );
  }
}
