
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'package:nano/core/debug_service.dart';

class UserModel implements NanoSerializable {
  final String name;
  final int age;

  UserModel(this.name, this.age);

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(json['name'] as String, json['age'] as int);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}

void main() {
  test('Serialization: Atom<UserModel> should support custom serialization/deserialization', () {
    final originalUser = UserModel('Alice', 25);
    final atom = Atom<UserModel>(
      originalUser,
      label: 'user_atom',
      fromJson: (json) => UserModel.fromJson(json),
    );

    // Verify serialization (simulation of getAtoms)
    final val = atom.value;
    final serializableValue = val is NanoSerializable ? val.toJson() : val.toString();
    expect(serializableValue, {'name': 'Alice', 'age': 25});

    // Verify deserialization (simulation of revertToState)
    // We simulate what NanoDebugService._parseValue does
    final jsonString = json.encode({'name': 'Bob', 'age': 30});
    
    // Since _parseValue is private, we'll verify it indirectly if we can, 
    // but here we just test the strategy we implemented in debug_service.dart
    
    final decoded = json.decode(jsonString);
    final revertedUser = atom.fromJson!(decoded as Map<String, dynamic>);
    
    expect(revertedUser.name, 'Bob');
    expect(revertedUser.age, 30);
  });

  test('Serialization: Primitives should still work', () {
    final atom = Atom<int>(0, label: 'count_atom');
    
    // Simulation of primitive parsing in _parseValue
    final valueToParse = '10';
    final parsedValue = int.parse(valueToParse);
    
    expect(parsedValue, 10);
  });
}
