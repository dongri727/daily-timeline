import "package:flutter/widgets.dart";
import 'distance/distance.dart';
import 'distance/entry.dart';

/// This [InheritedWidget] wraps the whole app, and provides access
/// to the [Distance] object.
class BlocProvider extends InheritedWidget {
  final Distance distance;

  BlocProvider(
      {Key? key,
        required Distance t,
        required Widget child,
        TargetPlatform platform = TargetPlatform.iOS})
      : distance = t ?? Distance(platform),
        super(key: key, child: child) {
    distance
        .loadFromBundle("assets/distance.json")
        .then((List<DistanceEntry> entries) {
      distance.setViewport(
          start: entries.first.start * 2.0,
          end: entries.first.start,
          animate: true);

      /// Advance the distance to its starting position.
      distance.advance(0.0, false);
    });
  }

  @override
  updateShouldNotify(InheritedWidget oldWidget) => true;

  /// static accessor for the [Distance].
  /// e.g. [_MainMenuWidgetState.navigateToDistance] uses this static getter to access build the [DistanceWidget].
  static Distance getDistance(BuildContext context) {
    BlocProvider? bp =
    context.dependOnInheritedWidgetOfExactType<BlocProvider>();
    Distance bloc = bp!.distance;
    return bloc;
  }
}
