import 'package:celechron/model/course.dart';
import 'package:celechron/model/exam.dart';
import 'package:celechron/model/grade.dart';
import 'package:celechron/model/practice_score_item.dart';
import 'package:celechron/model/scholar.dart';
import 'package:celechron/model/semester.dart';
import 'package:celechron/model/session.dart';

const academicSemester = '2026-2027秋冬';
const academicAlternateSemester = '2025-2026春夏';
const academicCourse = '演示课程 01';
const academicCourseId = '(2026-2027-1)-DEMO01-01';

Scholar academicFixture() {
  final now = DateTime.now();
  final scholar = Scholar()
    ..username = '3-demo'
    ..lastUpdateTimeCourse = now
    ..lastUpdateTimeGrade = now
    ..lastUpdateTimeHomework = now
    ..gpa = [4.8, 4.2, 4.0, 95]
    ..majorGpaAndCredit = [4.8, 3]
    ..pt2 = 1.5
    ..isPracticeScoresGet = true
    ..practiceDetailsAvailable = true
    ..practiceUpdatedAt = now
    ..practiceScoreItems = [
      PracticeScoreItem.fromJson({
        'id': 1,
        'categoryId': 1,
        'categoryName': '第二课堂',
        'projectName': '演示实践项目',
        'score': 1.5,
        'approved': true,
        'statusLabel': '审核通过',
      }),
    ];
  final semester = Semester(academicSemester)..gpa = [4.8, 4.2, 4.0, 95];
  final alternateSemester = Semester(academicAlternateSemester);
  for (var index = 1; index <= 24; index++) {
    final number = index.toString().padLeft(2, '0');
    final grade = Grade.fromJson({
      'id': '(2026-2027-1)-DEMO$number-01',
      'name': '演示课程 $number',
      'original': '95',
      'credit': 3.0,
      'fivePoint': 4.8,
      'fourPoint': 4.2,
      'fourPointLegacy': 4.0,
      'hundredPoint': 95,
      'gpaIncluded': true,
      'creditIncluded': true,
    })
      ..major = true;
    final start = DateTime(now.year, now.month, now.day + index + 7, 10);
    final exam = Exam.empty()
      ..id = grade.id
      ..name = grade.name
      ..time = [start, start.add(const Duration(hours: 2))]
      ..location = '演示考场 $number'
      ..seat = '$index';
    final course = Course.fromUgrsGrade(grade)
      ..teacher = '演示教师'
      ..exams = [exam];
    semester.courses[grade.id] = course;
    semester.grades.add(grade);
    semester.exams.add(exam);
    scholar.grades[grade.realId] = [grade];
  }
  final session = Session.fromJson({
    'id': academicCourseId,
    'name': academicCourse,
    'teacher': '演示教师',
    'firstHalf': true,
    'secondHalf': true,
    'day': 1,
    'time': [1, 2],
    'location': '演示教室',
  });
  semester.sessions.add(session);
  semester.courses[academicCourseId]!.sessions.add(session);
  final earlierExam = Exam.empty()
    ..id = '(2025-2026-2)-DEMO-01'
    ..name = '往期演示课程'
    ..time = [now, now.add(const Duration(hours: 2))]
    ..location = '往期考场';
  alternateSemester.exams.add(earlierExam);
  scholar.semesters = [semester, alternateSemester];
  return scholar;
}
