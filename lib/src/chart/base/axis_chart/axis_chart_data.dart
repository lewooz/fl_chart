// coverage:ignore-file
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/base/axis_chart/axis_chart_painter.dart';
import 'package:fl_chart/src/utils/lerp.dart';
import 'package:flutter/material.dart' hide Image;

/// This is the base class for axis base charts data
/// that contains a [FlGridData] that holds data for showing grid lines,
/// also we have [minX], [maxX], [minY], [maxY] values
/// we use them to determine how much is the scale of chart,
/// and calculate x and y according to the scale.
/// each child have to set it in their constructor.
abstract class AxisChartData extends BaseChartData with EquatableMixin {
  final FlGridData gridData;
  final FlTitlesData titlesData;
  final RangeAnnotations rangeAnnotations;

  double minX, maxX, baselineX;
  double minY, maxY, baselineY;

  /// clip the chart to the border (prevent draw outside the border)
  FlClipData clipData;

  /// A background color which is drawn behind th chart.
  Color backgroundColor;

  /// [AxisChart] draws some horizontal or vertical lines on above or below of everything
  ExtraLinesData extraLinesData;

  /// Difference of [maxY] and [minY]
  double get verticalDiff => maxY - minY;

  /// Difference of [maxX] and [minX]
  double get horizontalDiff => maxX - minX;

  AxisChartData({
    FlGridData? gridData,
    required FlTitlesData titlesData,
    RangeAnnotations? rangeAnnotations,
    required double minX,
    required double maxX,
    double? baselineX,
    required double minY,
    required double maxY,
    double? baselineY,
    FlClipData? clipData,
    Color? backgroundColor,
    FlBorderData? borderData,
    required FlTouchData touchData,
    ExtraLinesData? extraLinesData,
  })  : gridData = gridData ?? FlGridData(),
        titlesData = titlesData,
        rangeAnnotations = rangeAnnotations ?? RangeAnnotations(),
        minX = minX,
        maxX = maxX,
        baselineX = baselineX ?? 0,
        minY = minY,
        maxY = maxY,
        baselineY = baselineY ?? 0,
        clipData = clipData ?? FlClipData.none(),
        backgroundColor = backgroundColor ?? Colors.transparent,
        extraLinesData = extraLinesData ?? ExtraLinesData(),
        super(
        borderData: borderData,
        touchData: touchData,
      );

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        gridData,
        titlesData,
        rangeAnnotations,
        minX,
        maxX,
        baselineX,
        minY,
        maxY,
        baselineY,
        clipData,
        backgroundColor,
        borderData,
        touchData,
      ];
}

/// Represents a side of the chart
enum AxisSide { left, top, right, bottom }

/// Contains meta information about the drawing title.
class TitleMeta {
  /// min axis value
  final double min;

  /// max axis value
  final double max;

  /// The interval that applied to this drawing title
  final double appliedInterval;

  /// Reference of [SideTitles] object.
  final SideTitles sideTitles;

  /// Formatted value that is suitable to show, for example 100, 2k, 5m, ...
  final String formattedValue;

  /// Determines the axis side of titles (left, top, right, bottom)
  final AxisSide axisSide;

  TitleMeta({
    required this.min,
    required this.max,
    required this.appliedInterval,
    required this.sideTitles,
    required this.formattedValue,
    required this.axisSide,
  });
}

/// It gives you the axis value and gets a String value based on it.
typedef GetTitleWidgetFunction = Widget Function(double value, TitleMeta meta);

/// The default [SideTitles.getTitlesWidget] function.
///
/// formats the axis number to a shorter string using [formatNumber].
Widget defaultGetTitle(double value, TitleMeta meta) {
  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: Text(
      meta.formattedValue,
    ),
  );
}

/// Holds data for showing label values on axis numbers
class SideTitles with EquatableMixin {
  /// Determines showing or hiding this side titles
  final bool showTitles;

  /// You can override it to pass your custom widget to show in each axis value
  /// We recommend you to use [SideTitleWidget].
  final GetTitleWidgetFunction getTitlesWidget;

  /// It determines the maximum space that your titles need,
  /// (All titles will stretch using this value)
  final double reservedSize;

  /// Texts are showing with provided [interval]. If you don't provide anything,
  /// we try to find a suitable value to set as [interval] under the hood.
  final double? interval;

  /// It draws some title on an axis, per axis values,
  /// [showTitles] determines showing or hiding this side,
  ///
  /// Texts are depend on the axis value, you can override [getTitles],
  /// it gives you an axis value (double value) and a [TitleMeta] which contains
  /// additional information about the axis.
  /// Then you should return a [Widget] to show.
  /// It allows you to do anything you want, For example you can show icons
  /// instead of texts, because it accepts a [Widget]
  ///
  /// [reservedSize] determines the maximum space that your titles need,
  /// (All titles will stretch using this value)
  ///
  /// Texts are showing with provided [interval]. If you don't provide anything,
  /// we try to find a suitable value to set as [interval] under the hood.
  SideTitles({
    bool? showTitles,
    GetTitleWidgetFunction? getTitlesWidget,
    double? reservedSize,
    double? interval,
  })  : showTitles = showTitles ?? false,
        getTitlesWidget = getTitlesWidget ?? defaultGetTitle,
        reservedSize = reservedSize ?? 22,
        interval = interval {
    if (interval == 0) {
      throw ArgumentError("SideTitles.interval couldn't be zero");
    }
  }

  /// Lerps a [SideTitles] based on [t] value, check [Tween.lerp].
  static SideTitles lerp(SideTitles a, SideTitles b, double t) {
    return SideTitles(
      showTitles: b.showTitles,
      getTitlesWidget: b.getTitlesWidget,
      reservedSize: lerpDouble(a.reservedSize, b.reservedSize, t),
      interval: lerpDouble(a.interval, b.interval, t),
    );
  }

  /// Copies current [SideTitles] to a new [SideTitles],
  /// and replaces provided values.
  SideTitles copyWith({
    bool? showTitles,
    GetTitleWidgetFunction? getTitlesWidget,
    double? reservedSize,
    double? interval,
  }) {
    return SideTitles(
      showTitles: showTitles ?? this.showTitles,
      getTitlesWidget: getTitlesWidget ?? this.getTitlesWidget,
      reservedSize: reservedSize ?? this.reservedSize,
      interval: interval ?? this.interval,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        showTitles,
        getTitlesWidget,
        reservedSize,
        interval,
      ];
}

/// Holds data for showing each side titles (left, top, right, bottom)
class AxisTitles with EquatableMixin {
  /// Determines the size of [axisName]
  final double axisNameSize;

  /// It shows the name of axis, for example your x-axis shows year,
  /// then you might want to show it using [axisNameWidget] property as a widget
  final Widget? axisNameWidget;

  /// It is responsible to show your axis side labels.
  final SideTitles sideTitles;

  /// If titles are showing on top of your tooltip, you can draw them below everything.
  ///
  /// In the future, we will convert tooltips to a widget, that would solve this problem.
  final bool drawBelowEverything;

  /// If there is something to show as axisTitles, it returns true
  bool get showAxisTitles => axisNameWidget != null && axisNameSize != 0;

  /// If there is something to show as sideTitles, it returns true
  bool get showSideTitles =>
      sideTitles.showTitles && sideTitles.reservedSize != 0;

  /// you can provide [axisName] if you want to show a general
  /// label on this axis,
  ///
  /// [axisNameSize] determines the maximum size that [axisName] can use
  ///
  /// [sideTitles] property is responsible to show your axis side labels
  AxisTitles({
    Widget? axisNameWidget,
    double? axisNameSize,
    SideTitles? sideTitles,
    bool? drawBehindEverything,
  })  : axisNameWidget = axisNameWidget,
        axisNameSize = axisNameSize ?? 16,
        sideTitles = sideTitles ?? SideTitles(),
        drawBelowEverything = drawBehindEverything ?? false;

  /// Lerps a [AxisTitles] based on [t] value, check [Tween.lerp].
  static AxisTitles lerp(AxisTitles a, AxisTitles b, double t) {
    return AxisTitles(
      axisNameWidget: b.axisNameWidget,
      axisNameSize: lerpDouble(a.axisNameSize, b.axisNameSize, t),
      sideTitles: SideTitles.lerp(a.sideTitles, b.sideTitles, t),
      drawBehindEverything: b.drawBelowEverything,
    );
  }

  /// Copies current [SideTitles] to a new [SideTitles],
  /// and replaces provided values.
  AxisTitles copyWith({
    Widget? axisNameWidget,
    double? axisNameSize,
    SideTitles? sideTitles,
    bool? drawBelowEverything,
  }) {
    return AxisTitles(
      axisNameWidget: axisNameWidget ?? this.axisNameWidget,
      axisNameSize: axisNameSize ?? this.axisNameSize,
      sideTitles: sideTitles ?? this.sideTitles,
      drawBehindEverything: drawBelowEverything ?? this.drawBelowEverything,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        axisNameWidget,
        axisNameSize,
        sideTitles,
        drawBelowEverything,
      ];
}

/// Holds data for showing titles on each side of charts.
class FlTitlesData with EquatableMixin {
  final bool show;

  final AxisTitles leftTitles, topTitles, rightTitles, bottomTitles;

  /// [show] determines showing or hiding all titles,
  /// [leftTitles], [topTitles], [rightTitles], [bottomTitles] defines
  /// side titles of left, top, right, bottom sides respectively.
  FlTitlesData({
    bool? show,
    AxisTitles? leftTitles,
    AxisTitles? topTitles,
    AxisTitles? rightTitles,
    AxisTitles? bottomTitles,
  })  : show = show ?? true,
        leftTitles = leftTitles ??
            AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 44,
                showTitles: true,
              ),
            ),
        topTitles = topTitles ??
            AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 30,
                showTitles: true,
              ),
            ),
        rightTitles = rightTitles ??
            AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 44,
                showTitles: true,
              ),
            ),
        bottomTitles = bottomTitles ??
            AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 30,
                showTitles: true,
              ),
            );

  /// Lerps a [FlTitlesData] based on [t] value, check [Tween.lerp].
  static FlTitlesData lerp(FlTitlesData a, FlTitlesData b, double t) {
    return FlTitlesData(
      show: b.show,
      leftTitles: AxisTitles.lerp(a.leftTitles, b.leftTitles, t),
      rightTitles: AxisTitles.lerp(a.rightTitles, b.rightTitles, t),
      bottomTitles: AxisTitles.lerp(a.bottomTitles, b.bottomTitles, t),
      topTitles: AxisTitles.lerp(a.topTitles, b.topTitles, t),
    );
  }

  /// Copies current [FlTitlesData] to a new [FlTitlesData],
  /// and replaces provided values.
  FlTitlesData copyWith({
    bool? show,
    AxisTitles? leftTitles,
    AxisTitles? topTitles,
    AxisTitles? rightTitles,
    AxisTitles? bottomTitles,
  }) {
    return FlTitlesData(
      show: show ?? this.show,
      leftTitles: leftTitles ?? this.leftTitles,
      topTitles: topTitles ?? this.topTitles,
      rightTitles: rightTitles ?? this.rightTitles,
      bottomTitles: bottomTitles ?? this.bottomTitles,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        show,
        leftTitles,
        topTitles,
        rightTitles,
        bottomTitles,
      ];
}

/// Represents a conceptual position in cartesian (axis based) space.
class FlSpot with EquatableMixin {
  final double x;
  final double y;

  /// [x] determines cartesian (axis based) horizontally position
  /// 0 means most left point of the chart
  ///
  /// [y] determines cartesian (axis based) vertically position
  /// 0 means most bottom point of the chart
  const FlSpot(double x, double y)
      : x = x,
        y = y;

  /// Copies current [FlSpot] to a new [FlSpot],
  /// and replaces provided values.
  FlSpot copyWith({
    double? x,
    double? y,
  }) {
    return FlSpot(
      x ?? this.x,
      y ?? this.y,
    );
  }

  ///Prints x and y coordinates of FlSpot list
  @override
  String toString() => '($x, $y)';

  /// Used for splitting lines, or maybe other concepts.
  static const FlSpot nullSpot = FlSpot(double.nan, double.nan);

  /// Sets zero for x and y
  static const FlSpot zero = FlSpot(0, 0);

  /// Determines if [x] or [y] is null.
  bool isNull() => this == nullSpot;

  /// Determines if [x] and [y] is not null.
  bool isNotNull() => !isNull();

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        x,
        y,
      ];

  /// Lerps a [FlSpot] based on [t] value, check [Tween.lerp].
  static FlSpot lerp(FlSpot a, FlSpot b, double t) {
    if (a == FlSpot.nullSpot) {
      return b;
    }

    if (b == FlSpot.nullSpot) {
      return a;
    }

    return FlSpot(
      lerpDouble(a.x, b.x, t)!,
      lerpDouble(a.y, b.y, t)!,
    );
  }
}

/// Responsible to hold grid data,
class FlGridData with EquatableMixin {
  /// Determines showing or hiding all horizontal and vertical lines.
  final bool show;

  /// Determines showing or hiding all horizontal lines.
  final bool drawHorizontalLine;

  /// Determines interval between horizontal lines, left it null to be auto calculated.
  final double? horizontalInterval;

  /// Gives you a y value, and gets a [FlLine] that represents specified line.
  final GetDrawingGridLine getDrawingHorizontalLine;

  /// Gives you a y value, and gets a boolean that determines showing or hiding specified line.
  final CheckToShowGrid checkToShowHorizontalLine;

  /// Determines showing or hiding all vertical lines.
  final bool drawVerticalLine;

  /// Determines interval between vertical lines, left it null to be auto calculated.
  final double? verticalInterval;

  /// Gives you a x value, and gets a [FlLine] that represents specified line.
  final GetDrawingGridLine getDrawingVerticalLine;

  /// Gives you a x value, and gets a boolean that determines showing or hiding specified line.
  final CheckToShowGrid checkToShowVerticalLine;

  /// Responsible for rendering grid lines behind the content of charts,
  /// [show] determines showing or hiding all grids,
  ///
  /// [AxisChartPainter] draws horizontal lines from left to right of the chart,
  /// with increasing y value, it increases by [horizontalInterval].
  /// Representation of each line determines by [getDrawingHorizontalLine] callback,
  /// it gives you a double value (in the y axis), and you should return a [FlLine] that represents
  /// a horizontal line.
  /// You are allowed to show or hide any horizontal line, using [checkToShowHorizontalLine] callback,
  /// it gives you a double value (in the y axis), and you should return a boolean that determines
  /// showing or hiding specified line.
  /// or you can hide all horizontal lines by setting [drawHorizontalLine] false.
  ///
  /// [AxisChartPainter] draws vertical lines from bottom to top of the chart,
  /// with increasing x value, it increases by [verticalInterval].
  /// Representation of each line determines by [getDrawingVerticalLine] callback,
  /// it gives you a double value (in the x axis), and you should return a [FlLine] that represents
  /// a horizontal line.
  /// You are allowed to show or hide any vertical line, using [checkToShowVerticalLine] callback,
  /// it gives you a double value (in the x axis), and you should return a boolean that determines
  /// showing or hiding specified line.
  /// or you can hide all vertical lines by setting [drawVerticalLine] false.
  FlGridData({
    bool? show,
    bool? drawHorizontalLine,
    double? horizontalInterval,
    GetDrawingGridLine? getDrawingHorizontalLine,
    CheckToShowGrid? checkToShowHorizontalLine,
    bool? drawVerticalLine,
    double? verticalInterval,
    GetDrawingGridLine? getDrawingVerticalLine,
    CheckToShowGrid? checkToShowVerticalLine,
  })  : show = show ?? true,
        drawHorizontalLine = drawHorizontalLine ?? true,
        horizontalInterval = horizontalInterval,
        getDrawingHorizontalLine = getDrawingHorizontalLine ?? defaultGridLine,
        checkToShowHorizontalLine = checkToShowHorizontalLine ?? showAllGrids,
        drawVerticalLine = drawVerticalLine ?? true,
        verticalInterval = verticalInterval,
        getDrawingVerticalLine = getDrawingVerticalLine ?? defaultGridLine,
        checkToShowVerticalLine = checkToShowVerticalLine ?? showAllGrids {
    if (horizontalInterval == 0) {
      throw ArgumentError("FlGridData.horizontalInterval couldn't be zero");
    }
    if (verticalInterval == 0) {
      throw ArgumentError("FlGridData.verticalInterval couldn't be zero");
    }
  }

  /// Lerps a [FlGridData] based on [t] value, check [Tween.lerp].
  static FlGridData lerp(FlGridData a, FlGridData b, double t) {
    return FlGridData(
      show: b.show,
      drawHorizontalLine: b.drawHorizontalLine,
      horizontalInterval:
          lerpDouble(a.horizontalInterval, b.horizontalInterval, t),
      getDrawingHorizontalLine: b.getDrawingHorizontalLine,
      checkToShowHorizontalLine: b.checkToShowHorizontalLine,
      drawVerticalLine: b.drawVerticalLine,
      verticalInterval: lerpDouble(a.verticalInterval, b.verticalInterval, t),
      getDrawingVerticalLine: b.getDrawingVerticalLine,
      checkToShowVerticalLine: b.checkToShowVerticalLine,
    );
  }

  /// Copies current [FlGridData] to a new [FlGridData],
  /// and replaces provided values.
  FlGridData copyWith({
    bool? show,
    bool? drawHorizontalLine,
    double? horizontalInterval,
    GetDrawingGridLine? getDrawingHorizontalLine,
    CheckToShowGrid? checkToShowHorizontalLine,
    bool? drawVerticalLine,
    double? verticalInterval,
    GetDrawingGridLine? getDrawingVerticalLine,
    CheckToShowGrid? checkToShowVerticalLine,
  }) {
    return FlGridData(
      show: show ?? this.show,
      drawHorizontalLine: drawHorizontalLine ?? this.drawHorizontalLine,
      horizontalInterval: horizontalInterval ?? this.horizontalInterval,
      getDrawingHorizontalLine:
          getDrawingHorizontalLine ?? this.getDrawingHorizontalLine,
      checkToShowHorizontalLine:
          checkToShowHorizontalLine ?? this.checkToShowHorizontalLine,
      drawVerticalLine: drawVerticalLine ?? this.drawVerticalLine,
      verticalInterval: verticalInterval ?? this.verticalInterval,
      getDrawingVerticalLine:
          getDrawingVerticalLine ?? this.getDrawingVerticalLine,
      checkToShowVerticalLine:
          checkToShowVerticalLine ?? this.checkToShowVerticalLine,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        show,
        drawHorizontalLine,
        horizontalInterval,
        getDrawingHorizontalLine,
        checkToShowHorizontalLine,
        drawVerticalLine,
        verticalInterval,
        getDrawingVerticalLine,
        checkToShowVerticalLine,
      ];
}

/// Determines showing or hiding specified line.
typedef CheckToShowGrid = bool Function(double value);

/// Shows all lines.
bool showAllGrids(double value) {
  return true;
}

/// Determines the appearance of specified line.
///
/// It gives you an axis [value] (horizontal or vertical),
/// you should pass a [FlLine] that represents style of specified line.
typedef GetDrawingGridLine = FlLine Function(double value);

/// Returns a grey line for all values.
FlLine defaultGridLine(double value) {
  return FlLine(
    color: Colors.blueGrey,
    strokeWidth: 0.4,
    dashArray: [8, 4],
  );
}

/// Defines style of a line.
class FlLine with EquatableMixin {
  /// Defines color of the line.
  final Color color;

  /// Defines thickness of the line.
  final double strokeWidth;

  /// Defines dash effect of the line.
  ///
  /// it is a circular array of dash offsets and lengths.
  /// For example, the array `[5, 10]` would result in dashes 5 pixels long
  /// followed by blank spaces 10 pixels long.
  final List<int>? dashArray;

  /// Renders a line, color it by [color],
  /// thickness is defined by [strokeWidth],
  /// and if you want to have dashed line, you should fill [dashArray],
  /// it is a circular array of dash offsets and lengths.
  /// For example, the array `[5, 10]` would result in dashes 5 pixels long
  /// followed by blank spaces 10 pixels long.
  FlLine({
    Color? color,
    double? strokeWidth,
    List<int>? dashArray,
  })  : color = color ?? Colors.black,
        strokeWidth = strokeWidth ?? 2,
        dashArray = dashArray;

  /// Lerps a [FlLine] based on [t] value, check [Tween.lerp].
  static FlLine lerp(FlLine a, FlLine b, double t) {
    return FlLine(
      color: Color.lerp(a.color, b.color, t),
      strokeWidth: lerpDouble(a.strokeWidth, b.strokeWidth, t),
      dashArray: lerpIntList(a.dashArray, b.dashArray, t),
    );
  }

  /// Copies current [FlLine] to a new [FlLine],
  /// and replaces provided values.
  FlLine copyWith({
    Color? color,
    double? strokeWidth,
    List<int>? dashArray,
  }) {
    return FlLine(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      dashArray: dashArray ?? this.dashArray,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        color,
        strokeWidth,
        dashArray,
      ];
}

/// holds information about touched spot on the axis based charts.
abstract class TouchedSpot with EquatableMixin {
  /// Represents the spot inside our axis based chart,
  /// 0, 0 is bottom left, and 1, 1 is top right.
  final FlSpot spot;

  /// Represents the touch position in device pixels,
  /// 0, 0 is top, left, and 1, 1 is bottom right.
  final Offset offset;

  /// [spot]  represents the spot inside our axis based chart,
  /// 0, 0 is bottom left, and 1, 1 is top right.
  ///
  /// [offset] is the touch position in device pixels,
  /// 0, 0 is top, left, and 1, 1 is bottom right.
  TouchedSpot(
    FlSpot spot,
    Offset offset,
  )   : spot = spot,
        offset = offset;

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        spot,
        offset,
      ];
}

/// Holds data for rendering horizontal and vertical range annotations.
class RangeAnnotations with EquatableMixin {
  final List<HorizontalRangeAnnotation> horizontalRangeAnnotations;
  final List<VerticalRangeAnnotation> verticalRangeAnnotations;

  /// Axis based charts can annotate some horizontal and vertical regions,
  /// using [horizontalRangeAnnotations], and [verticalRangeAnnotations] respectively.
  RangeAnnotations({
    List<HorizontalRangeAnnotation>? horizontalRangeAnnotations,
    List<VerticalRangeAnnotation>? verticalRangeAnnotations,
  })  : horizontalRangeAnnotations = horizontalRangeAnnotations ?? const [],
        verticalRangeAnnotations = verticalRangeAnnotations ?? const [];

  /// Lerps a [RangeAnnotations] based on [t] value, check [Tween.lerp].
  static RangeAnnotations lerp(
      RangeAnnotations a, RangeAnnotations b, double t) {
    return RangeAnnotations(
      horizontalRangeAnnotations: lerpHorizontalRangeAnnotationList(
          a.horizontalRangeAnnotations, b.horizontalRangeAnnotations, t),
      verticalRangeAnnotations: lerpVerticalRangeAnnotationList(
          a.verticalRangeAnnotations, b.verticalRangeAnnotations, t),
    );
  }

  /// Copies current [RangeAnnotations] to a new [RangeAnnotations],
  /// and replaces provided values.
  RangeAnnotations copyWith({
    List<HorizontalRangeAnnotation>? horizontalRangeAnnotations,
    List<VerticalRangeAnnotation>? verticalRangeAnnotations,
  }) {
    return RangeAnnotations(
      horizontalRangeAnnotations:
          horizontalRangeAnnotations ?? this.horizontalRangeAnnotations,
      verticalRangeAnnotations:
          verticalRangeAnnotations ?? this.verticalRangeAnnotations,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        horizontalRangeAnnotations,
        verticalRangeAnnotations,
      ];
}

/// Defines an annotation region in y (vertical) axis.
class HorizontalRangeAnnotation with EquatableMixin {
  /// Determines starting point in vertical (y) axis.
  final double y1;

  /// Determines ending point in vertical (y) axis.
  final double y2;

  /// Fills the area with this color.
  final Color color;

  /// Annotates a horizontal region from most left to most right point of the chart, and
  /// from [y1] to [y2], and fills the area with [color].
  HorizontalRangeAnnotation({
    required double y1,
    required double y2,
    Color? color,
  })  : y1 = y1,
        y2 = y2,
        color = color ?? Colors.white;

  /// Lerps a [HorizontalRangeAnnotation] based on [t] value, check [Tween.lerp].
  static HorizontalRangeAnnotation lerp(
      HorizontalRangeAnnotation a, HorizontalRangeAnnotation b, double t) {
    return HorizontalRangeAnnotation(
      y1: lerpDouble(a.y1, b.y1, t)!,
      y2: lerpDouble(a.y2, b.y2, t)!,
      color: Color.lerp(a.color, b.color, t),
    );
  }

  /// Copies current [HorizontalRangeAnnotation] to a new [HorizontalRangeAnnotation],
  /// and replaces provided values.
  HorizontalRangeAnnotation copyWith({
    double? y1,
    double? y2,
    Color? color,
  }) {
    return HorizontalRangeAnnotation(
      y1: y1 ?? this.y1,
      y2: y2 ?? this.y2,
      color: color ?? this.color,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        y1,
        y2,
        color,
      ];
}

/// Defines an annotation region in x (horizontal) axis.
class VerticalRangeAnnotation with EquatableMixin {
  /// Determines starting point in horizontal (x) axis.
  final double x1;

  /// Determines ending point in horizontal (x) axis.
  final double x2;

  /// Fills the area with this color.
  final Color color;

  /// Annotates a vertical region from most bottom to most top point of the chart, and
  /// from [x1] to [x2], and fills the area with [color].
  VerticalRangeAnnotation({
    required double x1,
    required double x2,
    Color? color,
  })  : x1 = x1,
        x2 = x2,
        color = color ?? Colors.white;

  /// Lerps a [VerticalRangeAnnotation] based on [t] value, check [Tween.lerp].
  static VerticalRangeAnnotation lerp(
      VerticalRangeAnnotation a, VerticalRangeAnnotation b, double t) {
    return VerticalRangeAnnotation(
      x1: lerpDouble(a.x1, b.x1, t)!,
      x2: lerpDouble(a.x2, b.x2, t)!,
      color: Color.lerp(a.color, b.color, t),
    );
  }

  /// Copies current [VerticalRangeAnnotation] to a new [VerticalRangeAnnotation],
  /// and replaces provided values.
  VerticalRangeAnnotation copyWith({
    double? x1,
    double? x2,
    Color? color,
  }) {
    return VerticalRangeAnnotation(
      x1: x1 ?? this.x1,
      x2: x2 ?? this.x2,
      color: color ?? this.color,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        x1,
        x2,
        color,
      ];
}

/// Draws some straight horizontal or vertical lines in the [AxisChart]
class ExtraLinesData with EquatableMixin {
  final List<HorizontalLine> horizontalLines;
  final List<VerticalLine> verticalLines;

  final bool extraLinesOnTop;

  /// [AxisChart] draws some straight horizontal or vertical lines,
  /// you should set [AxisChartData.extraLinesData].
  /// Draws horizontal lines using [horizontalLines],
  /// and vertical lines using [verticalLines].
  ///
  /// If [extraLinesOnTop] sets true, it draws the line above the main bar lines, otherwise
  /// it draws them below the main bar lines.
  ExtraLinesData({
    List<HorizontalLine>? horizontalLines,
    List<VerticalLine>? verticalLines,
    bool? extraLinesOnTop,
  })  : horizontalLines = horizontalLines ?? const [],
        verticalLines = verticalLines ?? const [],
        extraLinesOnTop = extraLinesOnTop ?? true;

  /// Lerps a [ExtraLinesData] based on [t] value, check [Tween.lerp].
  static ExtraLinesData lerp(
      ExtraLinesData a, ExtraLinesData b, double t) {
    return ExtraLinesData(
      extraLinesOnTop: b.extraLinesOnTop,
      horizontalLines:
      lerpHorizontalLineList(a.horizontalLines, b.horizontalLines, t),
      verticalLines: lerpVerticalLineList(a.verticalLines, b.verticalLines, t),
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
    horizontalLines,
    verticalLines,
    extraLinesOnTop,
  ];
}

/// Holds data for drawing extra horizontal lines.
///
/// [AxisChart] draws some [HorizontalLine] (set by [AxisChartData.extraLinesData]),
/// in below or above of everything, it draws from left to right side of the chart.
class HorizontalLine extends FlLine with EquatableMixin {
  /// Draws from left to right of the chart using the [y] value.
  final double y;

  /// Use it for any kind of image, to draw it in left side of the chart.
  Image? image;

  /// Use it for vector images, to draw it in left side of the chart.
  SizedPicture? sizedPicture;

  /// Draws a text label over the line.
  final HorizontalLineLabel label;

  /// [AxisChart] draws horizontal lines from left to right side of the chart
  /// in the provided [y] value, and color it using [color].
  /// You can define the thickness using [strokeWidth]
  ///
  /// It draws a [label] over it.
  ///
  /// You can have a dashed line by filling [dashArray] with dash size and space respectively.
  ///
  /// It draws an image in left side of the chart, use [sizedPicture] for vectors,
  /// or [image] for any kind of image.
  HorizontalLine({
    required this.y,
    HorizontalLineLabel? label,
    Color? color,
    double? strokeWidth,
    List<int>? dashArray,
    this.image,
    this.sizedPicture,
  })  : label = label ?? HorizontalLineLabel(),
        super(
          color: color ?? Colors.black,
          strokeWidth: strokeWidth ?? 2,
          dashArray: dashArray);

  /// Lerps a [HorizontalLine] based on [t] value, check [Tween.lerp].
  static HorizontalLine lerp(HorizontalLine a, HorizontalLine b, double t) {
    return HorizontalLine(
      y: lerpDouble(a.y, b.y, t)!,
      label: HorizontalLineLabel.lerp(a.label, b.label, t),
      color: Color.lerp(a.color, b.color, t),
      strokeWidth: lerpDouble(a.strokeWidth, b.strokeWidth, t),
      dashArray: lerpIntList(a.dashArray, b.dashArray, t),
      image: b.image,
      sizedPicture: b.sizedPicture,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
    y,
    label,
    color,
    strokeWidth,
    dashArray,
    image,
    sizedPicture,
  ];
}

/// Holds data for drawing extra vertical lines.
///
/// [AxisChart] draws some [VerticalLine] (set by [AxisChartData.extraLinesData]),
/// in below or above of everything, it draws from bottom to top side of the chart.
class VerticalLine extends FlLine with EquatableMixin {
  /// Draws from bottom to top of the chart using the [x] value.
  final double x;

  /// Use it for any kind of image, to draw it in bottom side of the chart.
  Image? image;

  /// Use it for vector images, to draw it in bottom side of the chart.
  SizedPicture? sizedPicture;

  /// Draws a text label over the line.
  final VerticalLineLabel label;

  /// [AxisChart] draws vertical lines from bottom to top side of the chart
  /// in the provided [x] value, and color it using [color].
  /// You can define the thickness using [strokeWidth]
  ///
  /// It draws a [label] over it.
  ///
  /// You can have a dashed line by filling [dashArray] with dash size and space respectively.
  ///
  /// It draws an image in bottom side of the chart, use [sizedPicture] for vectors,
  /// or [image] for any kind of image.
  VerticalLine({
    required this.x,
    VerticalLineLabel? label,
    Color? color,
    double? strokeWidth,
    List<int>? dashArray,
    this.image,
    this.sizedPicture,
  })  : label = label ?? VerticalLineLabel(),
        super(
          color: color ?? Colors.black,
          strokeWidth: strokeWidth ?? 2,
          dashArray: dashArray);

  /// Lerps a [VerticalLine] based on [t] value, check [Tween.lerp].
  static VerticalLine lerp(VerticalLine a, VerticalLine b, double t) {
    return VerticalLine(
      x: lerpDouble(a.x, b.x, t)!,
      label: VerticalLineLabel.lerp(a.label, b.label, t),
      color: Color.lerp(a.color, b.color, t),
      strokeWidth: lerpDouble(a.strokeWidth, b.strokeWidth, t),
      dashArray: lerpIntList(a.dashArray, b.dashArray, t),
      image: b.image,
      sizedPicture: b.sizedPicture,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
    x,
    label,
    color,
    strokeWidth,
    dashArray,
    image,
    sizedPicture,
  ];
}

/// Shows a text label
abstract class FlLineLabel with EquatableMixin {
  /// Determines showing label or not.
  final bool show;

  /// Inner spaces around the drawing text.
  final EdgeInsetsGeometry padding;

  /// Sets style of the drawing text.
  final TextStyle? style;

  /// Aligns the text on the line.
  final Alignment alignment;

  /// Draws a title on the line, align it with [alignment] over the line,
  /// applies [padding] for spaces, and applies [style] for changing color,
  /// size, ... of the text.
  /// [show] determines showing label or not.
  FlLineLabel(
      {required this.show,
        required this.padding,
        required this.style,
        required this.alignment});

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
    show,
    padding,
    style,
    alignment,
  ];
}

/// Draws a title on the [HorizontalLine]
class HorizontalLineLabel extends FlLineLabel with EquatableMixin {
  /// Resolves a label for showing.
  final String Function(HorizontalLine) labelResolver;

  /// Returns the [HorizontalLine.y] as the drawing label.
  static String defaultLineLabelResolver(HorizontalLine line) =>
      line.y.toStringAsFixed(1);

  /// Draws a title on the [HorizontalLine], align it with [alignment] over the line,
  /// applies [padding] for spaces, and applies [style for changing color,
  /// size, ... of the text.
  /// Drawing text will retrieve through [labelResolver],
  /// you can override it with your custom data.
  /// /// [show] determines showing label or not.
  HorizontalLineLabel({
    EdgeInsets? padding,
    TextStyle? style,
    Alignment? alignment,
    bool show = false,
    String Function(HorizontalLine)? labelResolver,
  })  : labelResolver =
      labelResolver ?? HorizontalLineLabel.defaultLineLabelResolver,
        super(
        show: show,
        padding: padding ?? const EdgeInsets.all(6),
        style: style,
        alignment: alignment ?? Alignment.topLeft,
      );

  /// Lerps a [HorizontalLineLabel] based on [t] value, check [Tween.lerp].
  static HorizontalLineLabel lerp(
      HorizontalLineLabel a, HorizontalLineLabel b, double t) {
    return HorizontalLineLabel(
      padding:
      EdgeInsets.lerp(a.padding as EdgeInsets, b.padding as EdgeInsets, t),
      style: TextStyle.lerp(a.style, b.style, t),
      alignment: Alignment.lerp(a.alignment, b.alignment, t),
      labelResolver: b.labelResolver,
      show: b.show,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
    labelResolver,
    show,
    padding,
    style,
    alignment,
  ];
}

/// Draws a title on the [VerticalLine]
class VerticalLineLabel extends FlLineLabel with EquatableMixin {
  /// Resolves a label for showing.
  final String Function(VerticalLine) labelResolver;

  /// Returns the [VerticalLine.x] as the drawing label.
  static String defaultLineLabelResolver(VerticalLine line) =>
      line.x.toStringAsFixed(1);

  /// Draws a title on the [VerticalLine], align it with [alignment] over the line,
  /// applies [padding] for spaces, and applies [style for changing color,
  /// size, ... of the text.
  /// Drawing text will retrieve through [labelResolver],
  /// you can override it with your custom data.
  /// [show] determines showing label or not.
  VerticalLineLabel({
    EdgeInsets? padding,
    TextStyle? style,
    Alignment? alignment,
    bool? show,
    String Function(VerticalLine)? labelResolver,
  })  : labelResolver =
      labelResolver ?? VerticalLineLabel.defaultLineLabelResolver,
        super(
        show: show ?? false,
        padding: padding ?? const EdgeInsets.all(6),
        style: style ??
            const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
        alignment: alignment ?? Alignment.bottomRight,
      );

  /// Lerps a [VerticalLineLabel] based on [t] value, check [Tween.lerp].
  static VerticalLineLabel lerp(
      VerticalLineLabel a, VerticalLineLabel b, double t) {
    return VerticalLineLabel(
      padding:
      EdgeInsets.lerp(a.padding as EdgeInsets, b.padding as EdgeInsets, t),
      style: TextStyle.lerp(a.style, b.style, t),
      alignment: Alignment.lerp(a.alignment, b.alignment, t),
      labelResolver: b.labelResolver,
      show: b.show,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
    labelResolver,
    show,
    padding,
    style,
    alignment,
  ];
}
