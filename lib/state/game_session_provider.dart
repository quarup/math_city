import 'package:flutter_riverpod/flutter_riverpod.dart';

class TotalStarsNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void add(int stars) => state += stars;
}

final NotifierProvider<TotalStarsNotifier, int> totalStarsProvider =
    NotifierProvider<TotalStarsNotifier, int>(TotalStarsNotifier.new);
