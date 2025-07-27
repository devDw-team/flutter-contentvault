import 'package:drift/drift.dart';

import 'contents_table.dart';

@DataClassName('AiAnalysis')
class AiAnalysisTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get contentId => text().references(ContentsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get summary => text().nullable()(); // AI 생성 요약
  TextColumn get keywords => text().nullable()(); // JSON 배열 형태의 키워드
  TextColumn get sentiment => text().nullable()(); // 감정 분석 결과
  TextColumn get category => text().nullable()(); // AI 추천 카테고리
  RealColumn get relevanceScore => real().nullable()(); // 관련성 점수
  DateTimeColumn get analyzedAt => dateTime()();
} 