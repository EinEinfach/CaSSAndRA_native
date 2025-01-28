enum Pattern { lines, squares, rings }

final mowPattern = {
  Pattern.lines: 'lines',
  Pattern.squares: 'squares',
  Pattern.rings: 'rings',
};

class MowParameters {
  MowParameters({
    required this.mowPattern,
    required this.width,
    required this.angle,
    required this.distanceToBorder,
    required this.borderLaps,
    required this.mowArea,
    required this.mowExclusionBorder,
    required this.mowBorderCcw,
  });

  final Pattern mowPattern;
  final double width;
  final int angle;
  final int distanceToBorder;
  final int borderLaps;
  final bool mowArea;
  final bool mowExclusionBorder;
  final bool mowBorderCcw;

  Map<String, dynamic> toJson() => {
        'mowPattern': mowPattern.name,
        'width': width,
        'angle': angle,
        'distanceToBorder': distanceToBorder,
        'borderLaps': borderLaps,
        'mowArea': mowArea,
        'mowExclusionBorder': mowExclusionBorder,
        'mowBorderCcw': mowBorderCcw,
      };

  factory MowParameters.fromJson(Map<String, dynamic> json) {
    return MowParameters(
      mowPattern: Pattern.values.byName(json['mowPattern']),
      width: json['width'],
      angle: json['angle'],
      distanceToBorder: json['distanceToBorder'],
      borderLaps: json['borderLaps'],
      mowArea: json['mowArea']?? false,
      mowExclusionBorder: json['mowExclusionBorder']?? false,
      mowBorderCcw: json['mowBorderCcw']?? false,
    );
  }


}
