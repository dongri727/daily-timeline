import 'dart:ui' as ui;

import 'package:flutter/material.dart';
//import 'package:intl/intl.dart';
import '../menu/menu_data.dart';
import 'distance.dart';
import 'entry.dart';
import 'ticks.dart';
import 'utils.dart';

/// These two callbacks are used to detect if a bubble or an entry have been tapped.
/// If that's the case, [ArticlePage] will be pushed onto the [Navigator] stack.
/// どちらのページにも遷移する必要はないが、無効化すると前後ボタンが効かなくなる。
typedef TouchBubbleCallback = Function(TapTarget bubble);
typedef TouchEntryCallback = Function(DistanceEntry entry);

/// This couples with [DistanceRenderObject].
/// This widget's fields are accessible from the [RenderBox] so that it can
/// be aligned with the current state.
class DistanceRenderWidget extends LeafRenderObjectWidget {
  final double topOverlap;
  final Distance distance;
  final MenuItemData focusItem;
  final TouchBubbleCallback touchBubble;
  final TouchEntryCallback touchEntry;

  const DistanceRenderWidget(
      {Key? key,
        required this.focusItem,
        required this.touchBubble,
        required this.touchEntry,
        required this.topOverlap,
        required this.distance,
      })
      : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return DistanceRenderObject()
      ..distance = distance
      ..touchBubble = touchBubble
      ..touchEntry = touchEntry
      ..focusItem = focusItem
      ..topOverlap = topOverlap;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant DistanceRenderObject renderObject) {
    renderObject
      ..distance = distance
      ..focusItem = focusItem
      ..touchBubble = touchBubble
      ..touchEntry = touchEntry
      ..topOverlap = topOverlap;
  }

  @override
  didUnmountRenderObject(covariant DistanceRenderObject renderObject) {
    renderObject.distance.isActive = false;
  }
}

/// A custom renderer is used for the the distance object.
/// The [Distance] serves as an abstraction layer for the positioning and advancing logic.
/// The core method of this object is [paint()]: this is where all the elements
/// are actually drawn to screen.
class DistanceRenderObject extends RenderBox {
  static const List<Color> lineColors = [
    Color.fromARGB(200, 125, 195, 184),
    Color.fromARGB(200, 190, 224, 146),
    Color.fromARGB(200, 238, 155, 75),
    Color.fromARGB(200, 202, 79, 63),
    Color.fromARGB(200, 128, 28, 15)
  ];

  double _topOverlap = 0.0;
  final Ticks _ticks = Ticks();
  Distance? _distance;
  MenuItemData? _focusItem;
  MenuItemData? _processedFocusItem;
  final List<TapTarget> _tapTargets = [];
  late TouchBubbleCallback touchBubble;
  late TouchEntryCallback touchEntry;

  @override
  bool get sizedByParent => true;

  double get topOverlap => _topOverlap;
  Distance get distance => _distance!;
  MenuItemData get focusItem => _focusItem!;

  set topOverlap(double value) {
    if (_topOverlap == value) {
      return;
    }
    _topOverlap = value;
    updateFocusItem();
    markNeedsPaint();
    markNeedsLayout();
  }

  set distance(Distance value) {
    if (_distance == value) {
      return;
    }
    _distance = value;
    updateFocusItem();
    _distance?.onNeedPaint = markNeedsPaint;
    markNeedsPaint();
    markNeedsLayout();
  }

  set focusItem(MenuItemData value) {
    if (_focusItem == value) {
      return;
    }
    _focusItem = value;
    _processedFocusItem = null;
    updateFocusItem();
  }

  /// If [_focusItem] has been updated with a new value, update the current view.
  void updateFocusItem() {
    if (_processedFocusItem == _focusItem) {
      return;
    }
    if (_focusItem == null || distance == null || topOverlap == 0.0) {
      return;
    }

    /// Adjust the current distance padding and consequently the viewport.
    if (_focusItem!.pad) {
      distance.padding = EdgeInsets.only(
          top: topOverlap + _focusItem!.padTop + Distance.parallax,
          bottom: _focusItem!.padBottom);
      distance.setViewport(
          start: _focusItem!.start,
          end: _focusItem!.end,
          animate: true,
          pad: true);
    } else {
      distance.padding = EdgeInsets.zero;
      distance.setViewport(
          start: _focusItem!.start, end: _focusItem!.end, animate: true);
    }
    _processedFocusItem = _focusItem;
  }

  /// Check if the current tap on the screen has hit a bubble.
  @override
  bool hitTestSelf(Offset screenOffset) {
    //touchEntry(null);
    for (TapTarget bubble in _tapTargets.reversed) {
      if (bubble.rect.contains(screenOffset)) {
        if (touchBubble != null) {
          touchBubble(bubble);
        }
        return true;
      }
    }
    //touchBubble(null);

    return true;
  }

  @override
  void performResize() {
    size = constraints.biggest;
  }

  /// Adjust the viewport when needed.
  @override
  void performLayout() {
    if (_distance != null) {
      _distance!.setViewport(height: size.height, animate: true);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    if (_distance == null) {
      return;
    }

/*    /// Fetch the background colors from the [Distance] and compute the fill.
    List<DistanceBackgroundColor> backgroundColors = distance.backgroundColors;
    ui.Paint backgroundPaint;
    if (backgroundColors != null && backgroundColors.isNotEmpty) {
      double rangeStart = backgroundColors.first.start;
      double range = backgroundColors.last.start - backgroundColors.first.start;
      List<ui.Color> colors = <ui.Color>[];
      List<double> stops = <double>[];
      for (DistanceBackgroundColor bg in backgroundColors) {
        colors.add(bg.color);
        stops.add((bg.start - rangeStart) / range);
      }
      double s =
      distance.computeScale(distance.renderStart, distance.renderEnd);
      double y1 = (backgroundColors.first.start - distance.renderStart) * s;
      double y2 = (backgroundColors.last.start - distance.renderStart) * s;

      /// Fill Background.
      backgroundPaint = ui.Paint()
        ..shader = ui.Gradient.linear(
            ui.Offset(0.0, y1), ui.Offset(0.0, y2), colors, stops)
        ..style = ui.PaintingStyle.fill;

      if (y1 > offset.dy) {
        canvas.drawRect(
            Rect.fromLTWH(
                offset.dx, offset.dy, size.width, y1 - offset.dy + 1.0),
            ui.Paint()..color = backgroundColors.first.color);
      }

      /// Draw the background on the canvas.
      canvas.drawRect(
          Rect.fromLTWH(offset.dx, y1, size.width, y2 - y1), backgroundPaint);
    }*/

    _tapTargets.clear();
    double renderStart = _distance!.renderStart;
    double renderEnd = _distance!.renderEnd;
    double scale = size.height / (renderEnd - renderStart);

    /// Paint the [Ticks] on the left side of the screen.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(
        offset.dx, offset.dy + topOverlap, size.width, size.height));
    _ticks.paint(
        context, offset, -renderStart * scale, scale, size.height, distance);
    canvas.restore();

    /// And then draw the rest of the distance.
    if (_distance!.entries != null) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(offset.dx + _distance!.gutterWidth,
          offset.dy, size.width - _distance!.gutterWidth, size.height));
      drawItems(
          context,
          offset,
          _distance!.entries,
          _distance!.gutterWidth +
              Distance.lineSpacing -
              Distance.depthOffset * _distance!.renderOffsetDepth,
          scale,
          0);
      canvas.restore();
    }

    /// After a few moments of inaction on the distance, if there's enough space,
    /// an arrow pointing to the next event on the distance will appear on the bottom of the screen.
    /// Draw it, and add it as another [TapTarget].
    /// 下向きボタン
    if (_distance?.nextEntry != null && _distance!.nextEntryOpacity > 0.0) {
      double x = offset.dx + _distance!.gutterWidth - Distance.gutterLeft;
      double opacity = _distance!.nextEntryOpacity;
      Color color = Color.fromRGBO(154, 205, 50, opacity);
      double pageReference = _distance!.renderEnd;

      /// Use a Paragraph to draw the arrow's label and page scrolls on canvas:
      /// 1. Create a [ParagraphBuilder] that'll be initialized with the correct styling information;
      /// 2. Add some text to the builder;
      /// 3. Build the [Paragraph];
      /// 4. Lay out the text with custom [ParagraphConstraints].
      /// 5. Draw the Paragraph at the right offset.
      const double maxLabelWidth = 1200.0;
      ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.start, fontSize: 15.0))
        ..pushStyle(ui.TextStyle(color: color));

      builder.addText(_distance!.nextEntry!.label);
      ui.Paragraph labelParagraph = builder.build();
      labelParagraph.layout(const ui.ParagraphConstraints(width: maxLabelWidth));

      double y = offset.dy + size.height - 200.0;
      double labelX =
          x + size.width / 2.0 - labelParagraph.maxIntrinsicWidth / 2.0;
      canvas.drawParagraph(labelParagraph, Offset(labelX, y));
      y += labelParagraph.height;

      /// Calculate the boundaries of the arrow icon.
      Rect nextEntryRect = Rect.fromLTWH(labelX, y,
          labelParagraph.maxIntrinsicWidth, offset.dy + size.height - y);

      const double radius = 25.0;
      labelX = x + size.width / 2.0;
      y += 15 + radius;

      /// Draw the background circle.
      canvas.drawCircle(
          Offset(labelX, y),
          radius,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill);
      nextEntryRect.expandToInclude(Rect.fromLTWH(
          labelX - radius, y - radius, radius * 2.0, radius * 2.0));
      Path path = Path();
      double arrowSize = 6.0;
      double arrowOffset = 1.0;

      /// Draw the stylized arrow on top of the circle.
      path.moveTo(x + size.width / 2.0 - arrowSize,
          y - arrowSize + arrowSize / 2.0 + arrowOffset);
      path.lineTo(x + size.width / 2.0, y + arrowSize / 2.0 + arrowOffset);
      path.lineTo(x + size.width / 2.0 + arrowSize,
          y - arrowSize + arrowSize / 2.0 + arrowOffset);
      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0);
      y += 15 + radius;

      builder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: 14.0,
          height: 1.3))
        ..pushStyle(ui.TextStyle(color: color));

      double timeUntil = _distance!.nextEntry!.start - pageReference;
      String until = DistanceEntry.formatDistance(timeUntil).toLowerCase();
      builder.addText(until);
      labelParagraph = builder.build();
      labelParagraph.layout(ui.ParagraphConstraints(width: size.width));

      /// Draw the Paragraph beneath the circle.
      canvas.drawParagraph(labelParagraph, Offset(x, y));
      y += labelParagraph.height;

      /// Add this to the list of *tappable* elements.
      _tapTargets.add(TapTarget()
        ..entry = _distance!.nextEntry!
        ..rect = nextEntryRect
        ..zoom = true);
    }

    /// Repeat the same procedure as above for the arrow pointing to the previous event on the distance.
    /// ↑ボタン
    if (_distance?.prevEntry != null && _distance!.prevEntryOpacity > 0.0) {
      double x = offset.dx + _distance!.gutterWidth - Distance.gutterLeft;
      double opacity = _distance!.prevEntryOpacity;
      Color color = Color.fromRGBO(154, 205, 50, opacity);
      double pageReference = _distance!.renderEnd;

      const double maxLabelWidth = 1200.0;
      ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.start, fontSize: 15.0))
        ..pushStyle(ui.TextStyle(color: color));

      builder.addText(_distance!.prevEntry!.label);
      ui.Paragraph labelParagraph = builder.build();
      labelParagraph.layout(const ui.ParagraphConstraints(width: maxLabelWidth));

      double y = offset.dy + topOverlap + 20.0;
      double labelX =
          x + size.width / 2.0 - labelParagraph.maxIntrinsicWidth / 2.0;
      canvas.drawParagraph(labelParagraph, Offset(labelX, y));
      y += labelParagraph.height;

      Rect prevEntryRect = Rect.fromLTWH(labelX, y,
          labelParagraph.maxIntrinsicWidth, offset.dy + size.height - y);

      const double radius = 25.0;
      labelX = x + size.width / 2.0;
      y += 15 + radius;
      canvas.drawCircle(
          Offset(labelX, y),
          radius,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill);
      prevEntryRect.expandToInclude(Rect.fromLTWH(
          labelX - radius, y - radius, radius * 2.0, radius * 2.0));
      Path path = Path();
      double arrowSize = 6.0;
      double arrowOffset = 1.0;
      path.moveTo(
          x + size.width / 2.0 - arrowSize, y + arrowSize / 2.0 + arrowOffset);
      path.lineTo(x + size.width / 2.0, y - arrowSize / 2.0 + arrowOffset);
      path.lineTo(
          x + size.width / 2.0 + arrowSize, y + arrowSize / 2.0 + arrowOffset);
      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0);
      y += 15 + radius;

      builder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: 14.0,
          height: 1.3))
        ..pushStyle(ui.TextStyle(color: color));

      double timeUntil = _distance!.prevEntry!.start - pageReference;
      String until = DistanceEntry.formatDistance(timeUntil).toLowerCase();
      builder.addText(until);
      labelParagraph = builder.build();
      labelParagraph.layout(ui.ParagraphConstraints(width: size.width));
      canvas.drawParagraph(labelParagraph, Offset(x, y));
      y += labelParagraph.height;

      _tapTargets.add(TapTarget()
        ..entry = _distance!.prevEntry!
        ..rect = prevEntryRect
        ..zoom = true);
    }
  }

  /// Given a list of [entries], draw the label with its bubble beneath.
  /// Draw also the dots&lines on the left side of the Distance. These represent
  /// the starting/ending points for a given event and are meant to give the idea of
  /// the time span encompassing that event, as well as putting the vent into context
  /// relative to the other events.
  void drawItems(PaintingContext context, Offset offset,
      List<DistanceEntry> entries, double x, double scale, int depth) {
    final Canvas canvas = context.canvas;

    for (DistanceEntry item in entries) {
      if (!item.isVisible ||
          item.y > size.height + Distance.bubblesHeight ||
          item.endY < -Distance.bubblesHeight) {
        /// Don't paint this item.
        continue;
      }

      double legOpacity = item.legOpacity * item.opacity;
      Offset entryOffset = Offset(x + Distance.lineWidth / 2.0, item.y);

      /// Draw the small circle on the left side of the distance.
      canvas.drawCircle(
          entryOffset,
          Distance.edgeRadius,
          Paint()
            ..color = (item.accent ?? lineColors[depth % lineColors.length])
                .withOpacity(item.opacity));
      if (legOpacity > 0.0) {
        Paint legPaint = Paint()
          ..color = (item.accent ?? lineColors[depth % lineColors.length])
              .withOpacity(legOpacity);

        /// Draw the line connecting the start&point of this item on the distance.
        canvas.drawRect(
            Offset(x, item.y) & Size(Distance.lineWidth, item.length),
            legPaint);
        canvas.drawCircle(
            Offset(x + Distance.lineWidth / 2.0, item.y + item.length),
            Distance.edgeRadius,
            legPaint);
      }

      const double maxLabelWidth = 1200.0;
      const double bubblePadding = 20.0;

      /// Let the distance calculate the height for the current item's bubble.
      double bubbleHeight = distance.bubbleHeight(item);

      /// Use [ui.ParagraphBuilder] to construct the label for canvas.
      ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.start, fontSize: 15.0))
        ..pushStyle(
            ui.TextStyle(color: const Color.fromRGBO(255, 255, 255, 1.0)));

      builder.addText(item.label);
      ui.Paragraph labelParagraph = builder.build();
      labelParagraph.layout(const ui.ParagraphConstraints(width: maxLabelWidth));

      double textWidth =
          labelParagraph.maxIntrinsicWidth * item.opacity * item.labelOpacity;
      double bubbleX = _distance!.renderLabelX -
          Distance.depthOffset * _distance!.renderOffsetDepth;
      double bubbleY = item.labelY - bubbleHeight / 2.0;

      canvas.save();
      canvas.translate(bubbleX, bubbleY);

      /// Get the bubble's path based on its width&height, draw it, and then add the label on top.
      Path bubble =
      makeBubblePath(textWidth + bubblePadding * 2.0, bubbleHeight);

      canvas.drawPath(
          bubble,
          Paint()
            ..color = (item.accent ?? lineColors[depth % lineColors.length])
                .withOpacity(item.opacity * item.labelOpacity));
      canvas
          .clipRect(Rect.fromLTWH(bubblePadding, 0.0, textWidth, bubbleHeight));
      _tapTargets.add(TapTarget()
        ..entry = item
        ..rect = Rect.fromLTWH(
            bubbleX, bubbleY, textWidth + bubblePadding * 2.0, bubbleHeight));

      canvas.drawParagraph(
          labelParagraph,
          Offset(
              bubblePadding, bubbleHeight / 2.0 - labelParagraph.height / 2.0));
      canvas.restore();
      if (item.children != null) {
        /// Draw the other elements in the hierarchy.
        drawItems(context, offset, item.children, x + Distance.depthOffset,
            scale, depth + 1);
      }
    }
  }

  /// Given a width and a height, design a path for the bubble that lies behind events' labels
  /// on the distance, and return it.
  Path makeBubblePath(double width, double height) {
    //const double ArrowSize = 0.0; //吹き出しの矢印
    const double cornerRadius = 10.0;

    const double circularConstant = 0.55;
    const double icircularConstant = 1.0 - circularConstant;

    Path path = Path();

    path.moveTo(cornerRadius, 0.0);
    path.lineTo(width - cornerRadius, 0.0);
    path.cubicTo(width - cornerRadius + cornerRadius * circularConstant, 0.0,
        width, cornerRadius * icircularConstant, width, cornerRadius);
    path.lineTo(width, height - cornerRadius);
    path.cubicTo(
        width,
        height - cornerRadius + cornerRadius * circularConstant,
        width - cornerRadius * icircularConstant,
        height,
        width - cornerRadius,
        height);
    path.lineTo(cornerRadius, height);
    path.cubicTo(cornerRadius * icircularConstant, height, 0.0,
        height - cornerRadius * icircularConstant, 0.0, height - cornerRadius);

    /*  path.lineTo(0.0, height / 2.0 + ArrowSize / 2.0);
    path.lineTo(-ArrowSize / 2.0, height / 2.0);
    path.lineTo(0.0, height / 2.0 - ArrowSize / 2.0);*/

    path.lineTo(0.0, cornerRadius);

    path.cubicTo(0.0, cornerRadius * icircularConstant,
        cornerRadius * icircularConstant, 0.0, cornerRadius, 0.0);

    path.close();

    return path;
  }
}
