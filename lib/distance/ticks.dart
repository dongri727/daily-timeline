import 'dart:ui' as ui;
import 'package:daily/distance/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'distance.dart';

/// This class is used by the [DistanceRenderWidget] to render the ticks on the left side of the screen.
/// It has a single [paint()] method that's called within [DistanceRenderObject.paint()].
class Ticks {
  /// The following `const` variables are used to properly align, pad and layout the ticks
  /// on the left side of the distance.
  static const double margin = 20.0;
  static const double width = 40.0;
  static const double labelPadLeft = 5.0;
  static const double labelPadRight = 1.0;
  static const int ticksDistance = 16;
  static const int textsTickDistance = 64;
  static const double tickSize = 15.0;
  static const double smallTickSize = 5.0;

  /// Other than providing the [PaintingContext] to allow the ticks to paint themselves,
  /// other relevant sizing information is passed to this `paint()` method, as well as
  /// a reference to the [Distance].
  void paint(PaintingContext context, Offset offset, double translation,
      double scale, double height, Distance distance) {
    final Canvas canvas = context.canvas;

    double bottom = height;
    double tickDistance = ticksDistance.toDouble();
    double textTickDistance = textsTickDistance.toDouble();

    /// The width of the left panel can expand and contract if the favorites-view is activated,
    /// by pressing the button on the top-right corner of the distance.
    /// ただしこのアプリにfavorites機能はない
    double gutterWidth = distance.gutterWidth;

    /// Calculate spacing based on current scale
    double scaledTickDistance = tickDistance * scale;
    if (scaledTickDistance > 2 * ticksDistance) {
      while (scaledTickDistance > 2 * ticksDistance && tickDistance >= 2.0) {
        scaledTickDistance /= 2.0;
        tickDistance /= 2.0;
        textTickDistance /= 2.0;
      }
    } else {
      while (scaledTickDistance < ticksDistance) {
        scaledTickDistance *= 2.0;
        tickDistance *= 2.0;
        textTickDistance *= 2.0;
      }
    }

    /// The number of ticks to draw.
    int numTicks = (height / scaledTickDistance).ceil() + 2;
    if (scaledTickDistance > textsTickDistance) {
      textTickDistance = tickDistance;
    }

    /// Figure out the position of the top left corner of the screen
    double tickOffset = 0.0;
    double startingTickMarkValue = 0.0;
    double y = ((translation - bottom) / scale);
    startingTickMarkValue = y - (y % tickDistance);
    tickOffset = -(y % tickDistance) * scale - scaledTickDistance;

    /// Move back by one tick.
    tickOffset -= scaledTickDistance;
    startingTickMarkValue -= tickDistance;

    /// Ticks can change color because the distance background will also change color
    /// depending on the current era. The [TickColors] object, in `distance_utils.dart`,
    /// wraps this information.
    List<TickColors> tickColors = distance.tickColors;
    if (tickColors != null && tickColors.isNotEmpty) {
      /// Build up the color stops for the linear gradient.
      double rangeStart = tickColors.first.start;
      double range = tickColors.last.start - tickColors.first.start;
      List<ui.Color> colors = <ui.Color>[];
      List<double> stops = <double>[];
      for (TickColors bg in tickColors) {
        colors.add(bg.background);
        stops.add((bg.start - rangeStart) / range);
      }
      double s =
      distance.computeScale(distance.renderStart, distance.renderEnd);

      /// y-coordinate for the starting and ending element.
      double y1 = (tickColors.first.start - distance.renderStart) * s;
      double y2 = (tickColors.last.start - distance.renderStart) * s;

      /// Fill Background.
      ui.Paint paint = ui.Paint()
        ..shader = ui.Gradient.linear(
            ui.Offset(0.0, y1), ui.Offset(0.0, y2), colors, stops)
        ..style = ui.PaintingStyle.fill;

      /// Fill in top/bottom if necessary.
      if (y1 > offset.dy) {
        canvas.drawRect(
            Rect.fromLTWH(
                offset.dx, offset.dy, gutterWidth, y1 - offset.dy + 1.0),
            ui.Paint()
              ..color = tickColors.first.background);
      }
      if (y2 < offset.dy + height) {
        canvas.drawRect(
            Rect.fromLTWH(
                offset.dx, y2 - 1, gutterWidth, (offset.dy + height) - y2),
            ui.Paint()
              ..color = tickColors.last.background);
      }

      /// Draw the gutter.
      canvas.drawRect(
          Rect.fromLTWH(offset.dx, y1, gutterWidth, y2 - y1), paint);
    } else {
      canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, gutterWidth, height),
          Paint()
            ..color = const Color.fromRGBO(246, 246, 246, 0.95));
    }

    Set<String> usedValues = Set<String>();

    /// Draw all the ticks.
    for (int i = 0; i < numTicks; i++) {
      tickOffset += scaledTickDistance;

      int tt = startingTickMarkValue.round();
      tt = -tt;
      int o = tickOffset.floor();
      TickColors? colors = distance.findTickColors(offset.dy + height - o);
      if (tt % textTickDistance == 0) {
        /// Every `textTickDistance`, draw a wider tick with the a label laid on top.
        canvas.drawRect(
            Rect.fromLTWH(offset.dx + gutterWidth - tickSize,
                offset.dy + height - o, tickSize, 1.0),
            Paint()
              ..color = colors!.long);

        /// Drawing text to [canvas] is done by using the [ParagraphBuilder] directly.
        ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(
            textAlign: TextAlign.end, /* fontFamily: "Roboto", */
            fontSize: 10.0))
          ..pushStyle(ui.TextStyle(color: colors.text));

        int value = tt.round().abs();

/*        /// Format the label nicely depending on how long ago the tick is placed at.
        String label;
        if (value < 9000) {
          label = value.toStringAsFixed(0);
        } else {
          NumberFormat formatter = NumberFormat.compact();
          label = formatter.format(value);
          int? digits = formatter.minimumSignificantDigits;
          while (usedValues.contains(label) && digits! < 10) {
            formatter.minimumSignificantDigits = ++digits;
            label = formatter.format(value);
          }
        }
        usedValues.add(label);
        builder.addText(label);
        ui.Paragraph tickParagraph = builder.build();
        tickParagraph.layout(ui.ParagraphConstraints(
            width: gutterWidth - labelPadLeft - labelPadRight));
        canvas.drawParagraph(
            tickParagraph,
            Offset(offset.dx + labelPadLeft - labelPadRight,
                offset.dy + height - o - tickParagraph.height - 5));
      } else {
        /// If we're within two text-ticks, just draw a smaller line.
        canvas.drawRect(
            Rect.fromLTWH(offset.dx + gutterWidth - smallTickSize,
                offset.dy + height - o, smallTickSize, 1.0),
            Paint()..color = colors!.short);
      }*/
        startingTickMarkValue += tickDistance;
      }
    }
  }
}