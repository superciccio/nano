// Simple services to demonstrate dependency injection

class ServiceA {
  String get prefix => "Count: ";
}

class ServiceB {
  void log(String message) => print('[ServiceB] $message');
}

class ServiceC {
  int calculate(int current) => current + 1;
}
