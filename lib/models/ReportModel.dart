// models/report_model.dart
class ReportModel {
  final int adID;
  final String reportType;
  final String description;

  ReportModel({
    required this.adID,
    required this.reportType,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'adID': adID,
      'reportType': reportType,
      'description': description,
    };
  }
}