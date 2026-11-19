import 'dart:async';

import 'package:get/get.dart';

import 'package:celechron/model/semester.dart';
import 'package:celechron/model/scholar.dart';
import 'package:celechron/model/exam.dart';

class ExamListController extends GetxController {
  final _scholar = Get.find<Rx<Scholar>>(tag: 'scholar');
  late final RxInt semesterIndex;
  final Rx<Duration> _durationToLastUpdate = const Duration().obs;
  Timer? _timer;

  ExamListController({required String initialName}) {
    semesterIndex = semesters.indexWhere((e) => e.name == initialName).obs;
  }

  int get selectedIndex {
    final index = semesterIndex.value;
    return index >= 0 && index < semesters.length ? index : 0;
  }

  List<Semester> get semesters => _scholar.value.semesters;
  Duration get durationToLastUpdate => _durationToLastUpdate.value;

  List<List<Exam>> get exams {
    if (semesters.isEmpty) return [];
    final semester = semesters[selectedIndex];
    final sorted = [...semester.exams]..sort((a, b) {
        final startA = a.time.firstOrNull;
        final startB = b.time.firstOrNull;
        if (startA == null) return startB == null ? 0 : 1;
        return startB == null ? -1 : startA.compareTo(startB);
      });
    final groupedExams = <String, List<Exam>>{};
    for (final exam in sorted) {
      groupedExams.putIfAbsent(_examDayKey(exam), () => []).add(exam);
    }
    return groupedExams.values.toList();
  }

  String _examDayKey(Exam exam) {
    if (exam.dateLabel != null) return 'label:${exam.dateLabel}';
    if (exam.time.isEmpty) return 'unknown';
    final date = exam.time[0];
    return 'date:${date.year}-${date.month}-${date.day}';
  }

  @override
  void onReady() {
    super.onReady();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _durationToLastUpdate.value =
          DateTime.now().difference(_scholar.value.lastUpdateTimeCourse);
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
