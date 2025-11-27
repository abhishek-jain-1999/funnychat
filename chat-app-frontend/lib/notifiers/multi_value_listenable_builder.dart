import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CombinedNotifier extends StatelessWidget {

  // factory CombinedNotifier.twoValue<A,B>({
  //   required ValueListenable<A> value1,
  //   required ValueListenable<B> value2,
  // required Widget Function(BuildContext context, A values1,B values1, Widget? child)
  // }) {
  //   return CombinedNotifier(
  //     multipleListenable: [value1, value2],
  //     builder: (context, values, child) => const SizedBox.shrink(),
  //   );
  // }


  /// List of [ValueListenable]s to listen to.
  final List<ValueListenable> multipleListenable;

  /// The builder function to be called when value of any of the [ValueListenable] changes.
  /// The order of values list will be same as [multipleListenable] list.
  final Widget Function(BuildContext context, List<dynamic> values, Widget? child) builder;

  /// An optional child widget which will be avaliable as child parameter in [builder].
  final Widget? child;

  // The const constructor.
  const CombinedNotifier({
    super.key,
    required this.multipleListenable,
    required this.builder,
    this.child,
  }) : assert(multipleListenable.length != 0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(multipleListenable),
      builder: (context, child) {
        final list = multipleListenable.map((listenable) => listenable.value);
        return builder(context, List<dynamic>.unmodifiable(list), child);
      },
      child: child,
    );
  }
}
