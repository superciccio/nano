import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  test('NanoDebugService.getGraphData returns correct graph', () {
    // 1. Setup Graph
    final atom = Atom(10, label: 'testAtom');
    
    // Computed must be listened to be active and track dependencies
    final computed = ComputedAtom(() {
      return atom.value * 2;
    }, label: 'testComputed');
    
    void listener() {}
    computed.addListener(listener);
    
    // 2. Access value to trigger dependency tracking
    expect(computed.value, 20);

    // 3. Verify Graph Data
    final data = NanoDebugService.getGraphData();
    final nodes = data['nodes'] as List;
    
    // We expect at least our computed node
    expect(nodes.length, greaterThanOrEqualTo(1));
    
    final computedNode = nodes.firstWhere(
      (n) => n['label'] == 'testComputed',
      orElse: () => throw Exception('Computed node not found'),
    );
    
    expect(computedNode['type'], contains('ComputedAtom'));
    
    final deps = computedNode['dependencies'] as List;
    expect(deps.length, 1);
    expect(deps[0]['label'], 'testAtom');
    expect(deps[0]['value'], '10');
    
    // 4. Cleanup
    computed.removeListener(listener);
  });
}
