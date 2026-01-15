import 'dart:math';
import 'package:nano/nano.dart';

enum ExcuseCategory { frontend, backend, infra, universal }

class ExcuseLogic extends NanoLogic<void> {
  // Current state
  final category = Atom(ExcuseCategory.universal);
  final currentExcuse = Atom("Click the button to generate an excuse...");

  // Lists of funny excuses
  static const _excuses = {
    ExcuseCategory.frontend: [
      "The CSS specificity is too high for the browser to render.",
      "A z-index conflict in the 4th dimension.",
      "The shadow DOM is haunting the main thread.",
      "The user's screen has a non-reactive resolution.",
      "Tailwind reached its maximum utility capacity.",
    ],
    ExcuseCategory.backend: [
      "The database is in a non-blocking existential crisis.",
      "Redis memory is full of forgotten promises.",
      "A race condition won, and we lost.",
      "The microservices are no longer speaking to each other.",
      "The garbage collector threw away the production keys.",
    ],
    ExcuseCategory.infra: [
      "The load balancer is feeling overwhelmed by its responsibilities.",
      "K8s pod is in a permanent state of meditation (CrashLoopBackOff).",
      "The server is on a digital detox.",
      "AWS S3 is currently a black hole for data.",
      "The Jenkins pipeline is clogged with too many 'just one more fix' commits.",
    ],
    ExcuseCategory.universal: [
      "It worked on my machine, which is currently being shipped to production.",
      "The PR was so good it broke the laws of physics.",
      "The bug is actually a feature that requires advanced intelligence to appreciate.",
      "A cosmic ray flipped the 'IsBug' bit to true.",
      "The code is simply ahead of its time.",
    ],
  };

  void generate() {
    final list = _excuses[category.value]!;
    final random = Random().nextInt(list.length);
    currentExcuse.value = list[random];
  }

  void setCategory(ExcuseCategory cat) {
    category.value = cat;
    currentExcuse.value = "Selected ${cat.name}. Ready to generate!";
  }

  @override
  void onReady() {
    super.onReady();
    status.value = NanoStatus.success;
  }
}
