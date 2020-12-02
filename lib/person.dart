import 'dart:convert';

class Person {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String photo;
  final String address1;
  final String address2;

  Person({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.photo,
    this.address1,
    this.address2,
  });

  Person copyWith({
    int id,
    String name,
    String email,
    String phone,
    String photo,
    String address1,
    String address2,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photo: photo ?? this.photo,
      address1: address1 ?? this.address1,
      address2: address2 ?? this.address2,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photo': photo,
      'address1': address1,
      'address2': address2,
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Person(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      photo: map['photo'],
      address1: map['address1'],
      address2: map['address2'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Person.fromJson(String source) => Person.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Person(id: $id, name: $name, email: $email, phone: $phone, photo: $photo, address1: $address1, address2: $address2)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Person &&
      o.id == id &&
      o.name == name &&
      o.email == email &&
      o.phone == phone &&
      o.photo == photo &&
      o.address1 == address1 &&
      o.address2 == address2;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      phone.hashCode ^
      photo.hashCode ^
      address1.hashCode ^
      address2.hashCode;
  }
}
