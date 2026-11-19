import 'package:flutter/foundation.dart';

import '../../../domain/models/challenge.dart';
import '../../../domain/models/user_profile.dart';
import '../../../utils/result.dart';

/// Fonte da verdade dos desafios coletivos, feed de check-ins e mural de
/// incentivo.
abstract class ChallengeRepository extends ChangeNotifier {
  Future<Result<List<Challenge>>> getChallenges();

  Future<Result<Challenge>> getChallenge(String id);

  Future<Result<Challenge>> createChallenge({
    required String title,
    required String description,
    required ChallengeCategory category,
    required int durationDays,
    required String dailyGoal,
    required DateTime startDate,
    required UserProfile creator,
    required List<UserProfile> invited,
  });

  /// Amigos que podem ser convidados.
  Future<Result<List<UserProfile>>> getFriends();

  Future<Result<List<ChallengeTemplate>>> getTemplates();

  /// Check-ins do desafio, mais recentes primeiro.
  Future<Result<List<CheckIn>>> getCheckIns(String challengeId);

  Future<Result<CheckIn>> addCheckIn(CheckIn checkIn);

  Future<Result<CheckIn>> toggleReaction(String checkInId, Reaction reaction);

  Future<Result<CheckIn>> addComment(String checkInId, CheckInComment comment);

  Future<Result<List<Encouragement>>> getEncouragements(String challengeId);

  Future<Result<Encouragement>> sendEncouragement(Encouragement encouragement);
}
