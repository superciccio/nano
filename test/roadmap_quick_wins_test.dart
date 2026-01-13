import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

class UserModel implements NanoSerializable {
  final String name;
  final int age;

  UserModel(this.name, this.age);

  @override
  Map<String, dynamic> toJson() => {'name': name, 'age': age};

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(json['name'] as String, json['age'] as int);
  }
}

void main() {
  group('Precision Selectors (.select)', () {
    test('should only notify when selected value changes', () {
      final user = Atom(UserModel('Andrea', 30), label: 'user');
      final name = user.select((u) => u.name, label: 'name');

      int nameNotifications = 0;
      name.addListener(() => nameNotifications++);

      expect(name.value, 'Andrea');

      // Update age - name should NOT notify
      user.value = UserModel('Andrea', 31);
      expect(name.value, 'Andrea');
      expect(nameNotifications, 0);

      // Update name - name SHOULD notify
      user.value = UserModel('Bob', 31);
      expect(name.value, 'Bob');
      expect(nameNotifications, 1);
    });
  });

  group('State Replay (backup/restore)', () {
    test('should backup and restore primitive values', () {
      final count = Atom(0, label: 'count');

      Nano.backupState();

      count.value = 10;
      expect(count.value, 10);

      Nano.restoreState();
      expect(count.value, 0);
    });

    test('should backup and restore complex serializable values', () {
      final user = Atom(
        UserModel('Andrea', 30),
        label: 'user_replay',
        fromJson: (json) => UserModel.fromJson(json),
      );

      Nano.backupState();

      user.value = UserModel('Bob', 40);
      expect(user.value.name, 'Bob');

      Nano.restoreState();
      expect(user.value.name, 'Andrea');
      expect(user.value.age, 30);
    });
  });
}
