import 'package:flutter/material.dart';
import '../menu/menu_data.dart';
import 'distance.dart';
import 'entry.dart';
import 'utils.dart';
import 'render_widget.dart';
import '../color.dart';

typedef ShowMenuCallback = Function();
typedef SelectItemCallback = Function(DistanceEntry item);

/// This is the Stateful Widget associated with the Distance object.
/// It is built from a [focusItem], that is the event the [Distance] should
/// focus on when it's created.
class DistanceWidget extends StatefulWidget {
  final MenuItemData focusItem;
  final Distance distance;
  const DistanceWidget(this.focusItem, this.distance, {Key? key}) : super(key: key);

  @override
  DistanceWidgetState createState() => DistanceWidgetState();
}

class DistanceWidgetState extends State<DistanceWidget> {
  static const String defaultPositionName = "Distance";
  static const double topOverlap = 56.0;

  /// These variables are used to calculate the correct viewport for the distance
  /// when performing a scaling operation as in [_scaleStart], [_scaleUpdate], [_scaleEnd].
  late Offset _lastFocalPoint;
  double _scaleStartYearStart = -100.0;
  double _scaleStartYearEnd = 100.0;

  /// When touching a bubble on the [Distance] keep track of which
  /// element has been touched in order to move to the [article_widget].
  TapTarget? _touchedBubble;
  DistanceEntry? _touchedEntry;

/*  /// Which position the Distance is currently focused on.
  /// Defaults to [DefaultPositionName].
  String? _positionName;*/

  /// Syntactic-sugar-getter.
  Distance get distance => widget.distance;

/*
  Color? _headerTextColor;
  Color? _headerBackgroundColor;
*/


  /// The following three functions define are the callbacks used by the
  /// [GestureDetector] widget when rendering this widget.
  /// First gather the information regarding the starting point of the scaling operation.
  /// Then perform the update based on the incoming [ScaleUpdateDetails] data,
  /// and pass the relevant information down to the [Distance], so that it can display
  /// all the relevant information properly.
  void _scaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    _scaleStartYearStart = distance.start;
    _scaleStartYearEnd = distance.end;
    distance.isInteracting = true;
    distance.setViewport(velocity: 0.0, animate: true);
  }

  void _scaleUpdate(ScaleUpdateDetails details) {
    double changeScale = details.scale;
    double scale =
        (_scaleStartYearEnd - _scaleStartYearStart) / context.size!.height;

    double focus = _scaleStartYearStart + details.focalPoint.dy * scale;
    double focalDiff =
        (_scaleStartYearStart + _lastFocalPoint.dy * scale) - focus;
    distance.setViewport(
        start: focus + (_scaleStartYearStart - focus) / changeScale + focalDiff,
        end: focus + (_scaleStartYearEnd - focus) / changeScale + focalDiff,
        height: context.size!.height,
        animate: true);
  }

  void _scaleEnd(ScaleEndDetails details) {
    distance.isInteracting = false;
    distance.setViewport(
        velocity: details.velocity.pixelsPerSecond.dy, animate: true);
  }

  /// The following two callbacks are passed down to the [DistanceRenderWidget] so
  /// that it can pass the information back to this widget.
  onTouchBubble(TapTarget bubble) {
    _touchedBubble = bubble;
  }

  onTouchEntry(DistanceEntry entry) {
    _touchedEntry = entry;
  }

  void _tapDown(TapDownDetails details) {
    distance.setViewport(velocity: 0.0, animate: true);
  }

  /// If the [DistanceRenderWidget] has set the [_touchedBubble] to the currently
  /// touched bubble on the distance, upon removing the finger from the screen,
  /// the app will check if the touch operation consists of a zooming operation.
  ///
  /// If it is, adjust the layout accordingly.
  /// Otherwise trigger a [Navigator.push()] for the tapped bubble. This moves
  /// the app into the [ArticleWidget].
  void _tapUp(TapUpDetails details) {
    EdgeInsets devicePadding = MediaQuery.of(context).padding;
    if (_touchedBubble != null) {
      if (_touchedBubble!.zoom) {
        MenuItemData target = MenuItemData.fromEntry(_touchedBubble!.entry);

        distance.padding = EdgeInsets.only(
            top: topOverlap +
                devicePadding.top +
                target.padTop +
                Distance.parallax,
            bottom: target.padBottom);
        distance.setViewport(
            start: target.start, end: target.end, animate: true, pad: true);
      }
    }
  }

  /// When performing a long-press operation, the viewport will be adjusted so that
  /// the visible start and end times will be updated according to the [DistanceEntry]
  /// information. The long-pressed bubble will float to the top of the viewport,
  /// and the viewport will be scaled appropriately.
  void _longPress() {
    EdgeInsets devicePadding = MediaQuery.of(context).padding;
    if (_touchedBubble != null) {
      MenuItemData target = MenuItemData.fromEntry(_touchedBubble!.entry);

      distance.padding = EdgeInsets.only(
          top: topOverlap +
              devicePadding.top +
              target.padTop +
              Distance.parallax,
          bottom: target.padBottom);
      distance.setViewport(
          start: target.start, end: target.end, animate: true, pad: true);
    }
  }

  @override
  initState() {
    super.initState();
    //if (distance != null) {
      widget.distance.isActive = true;
/*      _positionName = distance.currentPosition != null
          ? distance.currentPosition!.label
          : defaultPositionName;
      distance.onHeaderColorsChanged = (Color background, Color text) {
        setState(() {
          _headerTextColor = text;
          _headerBackgroundColor = background;
        });
      };

      /// Update the label for the [Distance] object.
      distance.onPositionChanged = (DistanceEntry entry) {
        setState(() {
          _positionName = entry != null ? entry.label : defaultPositionName;
        });
      };

      _headerTextColor = distance.headerTextColor;
      _headerBackgroundColor = distance.headerBackgroundColor;
    }*/
  }

  /// Update the current view and change the distance header, color and background color,
  @override
  void didUpdateWidget(covariant DistanceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

/*    if (distance != oldWidget.distance && distance != null) {
      setState(() {
        _headerTextColor = distance.headerTextColor!;
        _headerBackgroundColor = distance.headerBackgroundColor;
      });

      distance.onHeaderColorsChanged = (Color background, Color text) {
        setState(() {
          _headerTextColor = text;
          _headerBackgroundColor = background;
        });
      };
      distance.onPositionChanged = (DistanceEntry entry) {
        setState(() {
          _positionName = entry != null ? entry.label : defaultPositionName;
        });
      };*/
/*      setState(() {
        _positionName =
        distance.currentPosition ?? defaultPositionName;
      });*/
   // }
  }

  /// This is a [StatefulWidget] life-cycle method. It's being overridden here
  /// so that we can properly update the [Distance] widget.
  @override
  deactivate() {
    super.deactivate();
/*    if (distance != null) {
      distance.onHeaderColorsChanged = null;
      distance.onPositionChanged = null;
    }*/
  }

  /// This widget is wrapped in a [Scaffold] to have the classic Material Design visual layout structure.
  /// Then the body of the app is made of a [GestureDetector] to properly handle all the user-input events.
  /// This widget then lays down a [Stack]:
  ///   - [DistanceRenderWidget] renders the actual contents of the distance such as the currently visible
  ///   bubbles with their corresponding [FlareWidget]s, the left bar with the ticks, etc.
  ///   - [BackdropFilter] that wraps the top header bar, with the back button, the favorites button, and its coloring.
  @override
  Widget build(BuildContext context) {
    EdgeInsets devicePadding = MediaQuery.of(context).padding;
    if (distance != null) {
      distance.devicePadding = devicePadding;
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
          onLongPress: _longPress,
          onTapDown: _tapDown,
          onScaleStart: _scaleStart,
          onScaleUpdate: _scaleUpdate,
          onScaleEnd: _scaleEnd,
          onTapUp: _tapUp,
          child: Stack(children: <Widget>[
            DistanceRenderWidget(
                distance: distance,
                topOverlap: topOverlap + devicePadding.top,
                focusItem: widget.focusItem,
                touchBubble: onTouchBubble,
                touchEntry: onTouchEntry
            ),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                      height: devicePadding.top,
                      //color: _headerBackgroundColor ?? const Color.fromRGBO(238, 240, 242, 0.81)
                  ),
                  Container(
                      //color: _headerBackgroundColor ?? const Color.fromRGBO(238, 240, 242, 0.81),
                      height: 56.0,
                      width: double.infinity,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            IconButton(
                              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                              //color: _headerTextColor ?? Colors.black.withOpacity(0.5),
                              alignment: Alignment.centerLeft,
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                widget.distance.isActive = false;
                                Navigator.of(context).pop();
                                //return true;
                              },
                            ),
                            const Text(
                              "VoyagerII",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontSize: 20.0),
                              ),
                          ]))
                ])
          ])),
    );
  }
}