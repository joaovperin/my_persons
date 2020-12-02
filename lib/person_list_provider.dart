import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'db-utils.dart';
import 'person.dart';

class EntityListProvider with ChangeNotifier {
  final List<Person> _list = [];

  Future<void> loadList() async {
    _list
      ..clear()
      ..addAll([...await loadFromDatabase()]);
    notifyListeners();
  }

  List<Person> get list => [..._list];

  int get count => _list.length;

  Person getByIndex(int index) => _list[index];

  /// Grava a entidade no webservice e atualiza lista
  Future<void> gravar(Person entidade) async {
    await saveOnWebService(entidade);
    await saveOnDatabase(entidade);
    _list.add(entidade);
    notifyListeners();
  }

  Future<void> saveOnDatabase(Person p) async {
    await DbUtils.insert('Person', p.toMap());
  }

  Future<List<Person>> loadFromDatabase() async {
    final list = await DbUtils.query('Person');
    return list.map((e) => Person.fromMap(e)).toList();
  }

  Future<void> removeAllFromDatabase() async {
    await DbUtils.delete('Person');
  }

  Future<void> removeOneFromDatabase(Person p) async {
    await DbUtils.delete('Person', where: 'id = ?', args: [p.id]);
  }

  Future<List<Person>> getFromWebService() async {
    var response = await http.get('https://jsonplaceholder.typicode.com/users');
    final list = json.decode(response.body) as List;
    if (list.length > 0) {
      return list
          .map((elm) => Person.fromMap({
                ...elm,
                'id': null,
                'address1':
                    '${elm["address"]["city"]} ${elm["address"]["street"]}',
                'address2': elm["address"]["suite"],
                'photo':
                    'https://randomuser.me/api/portraits/men/${elm["id"]}.jpg'
              }))
          .toList();
    }
    return [];
  }

  Future<void> saveOnWebService(Person entity) async {
    return Future.delayed(Duration(seconds: 2));
  }
}
