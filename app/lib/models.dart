class YoloObject {
  final String className;
  final double score;
  final List<double> bboxXYXY; // [x1,y1,x2,y2]
  final List<List<double>> polygon; // [[x,y],...]

  YoloObject({
    required this.className,
    required this.score,
    required this.bboxXYXY,
    required this.polygon,
  });

  factory YoloObject.fromJson(Map<String, dynamic> j) {
    return YoloObject(
      className: j['class_name'] ?? '',
      score: (j['score'] ?? 0).toDouble(),
      bboxXYXY: (j['bbox_xyxy'] as List).map((e) => (e as num).toDouble()).toList(),
      polygon: (j['polygon'] as List?)
              ?.map((pt) => (pt as List).map((e) => (e as num).toDouble()).toList())
              .toList()
          ?? [],
    );
  }
}

class PredictResponse {
  final List<YoloObject> objects;
  final Map<String, dynamic> summary;

  PredictResponse({required this.objects, required this.summary});

  factory PredictResponse.fromJson(Map<String, dynamic> j) {
    final objs = (j['objects'] as List? ?? [])
        .map((o) => YoloObject.fromJson(o as Map<String, dynamic>))
        .toList();
    return PredictResponse(objects: objs, summary: j['summary'] ?? {});
  }
}