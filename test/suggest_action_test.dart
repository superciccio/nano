import 'package:flutter/material.dart';
import 'package:nano/nano.dart';

void testSuggestAction() {
  final atom1 = 0.toAtom();
  final atom2 = 0.toAtom();
  final atom3 = 0.toAtom();

  // Simple usage: OK
  final okParams = () {
    atom1.set(1);
    atom2.set(2);
  };

  // Complex usage: Should lint
  // expect_lint: suggest_nano_action
  final complexParams = () {
    atom1.set(1);
    atom2.set(2);
    atom3.set(3);
  };

  // Complex usage with update and assignment
  // expect_lint: suggest_nano_action
  final complexMixed = () {
    atom1.update((v) => v + 1);
    atom2.value = 5;
    atom3.increment();
  };
}
