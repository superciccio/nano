import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  test('NanoList tracks length changes', () {
    final list = NanoList<int>();
    int calls = 0;

    final disposer = autorun(() {
      // Just accessing length should track
      list.length; 
      calls++;
    });

    expect(calls, 1); // Initial

    list.add(1);
    expect(calls, 2);

    list.addAll([2, 3]); // Should be 1 batch update due to override
    expect(calls, 3);
    
    disposer();
  });

  test('NanoList tracks index changes', () {
    final list = NanoList<int>([1, 2, 3]);
    int lastValue = 0;
    
    final disposer = autorun(() {
      lastValue = list[0];
    });
    
    expect(lastValue, 1);
    
    list[0] = 10;
    expect(lastValue, 10);
    
    disposer();
  });
  
  test('NanoMap tracks updates', () {
    final map = NanoMap<String, int>();
    int calls = 0;
    
    final disposer = autorun(() {
      // Accessing keys tracks
      map.keys.toList(); 
      calls++;
    });
    
    expect(calls, 1);
    
    map['a'] = 1;
    expect(calls, 2);
    
    map.remove('a');
    expect(calls, 3);
    
    disposer();
  });
}
