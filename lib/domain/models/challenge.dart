import '../../utils/dates.dart';
import 'user_profile.dart';

/// Categoria visual/temática do desafio.
enum ChallengeCategory {
  nutrition('Alimentação'),
  reading('Leitura'),
  hydration('Hidratação'),
  sleep('Sono'),
  movement('Movimento'),
  mindfulness('Atenção plena'),
  morning('Rotina matinal');

  const ChallengeCategory(this.label);

  final String label;
}

/// Desafio temporário com amigos (ex.: "21 Dias Sem Açúcar").
class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startDate,
    required this.durationDays,
    required this.members,
    required this.createdBy,
    this.dailyGoal = '',
  });

  final String id;
  final String title;
  final String description;
  final ChallengeCategory category;
  final DateTime startDate;
  final int durationDays;
  final List<UserProfile> members;
  final String createdBy;

  /// Meta diária para um check-in ser válido (ex.: "Nenhum açúcar adicionado").
  final String dailyGoal;

  DateTime get endDate => Dates.addDays(startDate, durationDays - 1);

  /// Dia atual do desafio (1-based), limitado à duração.
  int currentDay(DateTime now) =>
      (Dates.daysBetween(startDate, now) + 1).clamp(0, durationDays);

  int daysLeft(DateTime now) =>
      (durationDays - currentDay(now)).clamp(0, durationDays);

  bool isActive(DateTime now) {
    final d = Dates.dateOnly(now);
    return !d.isBefore(Dates.dateOnly(startDate)) && !d.isAfter(endDate);
  }

  bool isFinished(DateTime now) => Dates.dateOnly(now).isAfter(endDate);

  double timeProgress(DateTime now) =>
      durationDays == 0 ? 0 : currentDay(now) / durationDays;

  Challenge copyWith({List<UserProfile>? members}) => Challenge(
    id: id,
    title: title,
    description: description,
    category: category,
    startDate: startDate,
    durationDays: durationDays,
    members: members ?? this.members,
    createdBy: createdBy,
    dailyGoal: dailyGoal,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category.name,
    'startDate': startDate.toIso8601String(),
    'durationDays': durationDays,
    'members': members.map((m) => m.toJson()).toList(),
    'createdBy': createdBy,
    'dailyGoal': dailyGoal,
  };

  factory Challenge.fromJson(Map<String, Object?> json) => Challenge(
    id: json['id']! as String,
    title: json['title']! as String,
    description: (json['description'] as String?) ?? '',
    category: ChallengeCategory.values.byName(json['category']! as String),
    startDate: DateTime.parse(json['startDate']! as String),
    durationDays: json['durationDays']! as int,
    members: (json['members']! as List<Object?>)
        .map((e) => UserProfile.fromJson(e! as Map<String, Object?>))
        .toList(),
    createdBy: json['createdBy']! as String,
    dailyGoal: (json['dailyGoal'] as String?) ?? '',
  );
}

/// Modelo sugerido na aba "Descobrir".
class ChallengeTemplate {
  const ChallengeTemplate({
    required this.title,
    required this.description,
    required this.category,
    required this.durationDays,
    required this.dailyGoal,
  });

  final String title;
  final String description;
  final ChallengeCategory category;
  final int durationDays;
  final String dailyGoal;
}

/// Comentário ("palavra de força") em um check-in.
class CheckInComment {
  const CheckInComment({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final UserProfile author;
  final String text;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'author': author.toJson(),
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CheckInComment.fromJson(Map<String, Object?> json) => CheckInComment(
    id: json['id']! as String,
    author: UserProfile.fromJson(json['author']! as Map<String, Object?>),
    text: json['text']! as String,
    createdAt: DateTime.parse(json['createdAt']! as String),
  );
}

/// Reações disponíveis nos check-ins.
enum Reaction {
  cheer('👏', 'Incentivar'),
  inspiring('✨', 'Inspirador'),
  fire('🔥', 'Foco total'),
  water('💧', 'Hidratado!');

  const Reaction(this.emoji, this.label);

  final String emoji;
  final String label;
}

/// Check-in fotográfico de um membro no desafio.
class CheckIn {
  const CheckIn({
    required this.id,
    required this.challengeId,
    required this.author,
    required this.createdAt,
    required this.caption,
    this.photoPath,
    this.tag,
    this.context,
    this.reactions = const {},
    this.myReactions = const {},
    this.comments = const [],
  });

  final String id;
  final String challengeId;
  final UserProfile author;
  final DateTime createdAt;
  final String caption;

  /// Caminho local da foto (null = card ilustrado).
  final String? photoPath;

  /// Selo sobre a foto (ex.: "Sem Açúcar Adicionado").
  final String? tag;

  /// Contexto (ex.: "Ritual Matinal").
  final String? context;
  final Map<Reaction, int> reactions;
  final Set<Reaction> myReactions;
  final List<CheckInComment> comments;

  CheckIn copyWith({
    Map<Reaction, int>? reactions,
    Set<Reaction>? myReactions,
    List<CheckInComment>? comments,
  }) => CheckIn(
    id: id,
    challengeId: challengeId,
    author: author,
    createdAt: createdAt,
    caption: caption,
    photoPath: photoPath,
    tag: tag,
    context: context,
    reactions: reactions ?? this.reactions,
    myReactions: myReactions ?? this.myReactions,
    comments: comments ?? this.comments,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'challengeId': challengeId,
    'author': author.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'caption': caption,
    'photoPath': photoPath,
    'tag': tag,
    'context': context,
    'reactions': {for (final e in reactions.entries) e.key.name: e.value},
    'myReactions': myReactions.map((r) => r.name).toList(),
    'comments': comments.map((c) => c.toJson()).toList(),
  };

  factory CheckIn.fromJson(Map<String, Object?> json) => CheckIn(
    id: json['id']! as String,
    challengeId: json['challengeId']! as String,
    author: UserProfile.fromJson(json['author']! as Map<String, Object?>),
    createdAt: DateTime.parse(json['createdAt']! as String),
    caption: (json['caption'] as String?) ?? '',
    photoPath: json['photoPath'] as String?,
    tag: json['tag'] as String?,
    context: json['context'] as String?,
    reactions: {
      for (final e
          in ((json['reactions'] as Map<String, Object?>?) ?? const {}).entries)
        Reaction.values.byName(e.key): e.value! as int,
    },
    myReactions: ((json['myReactions'] as List<Object?>?) ?? const [])
        .map((e) => Reaction.values.byName(e! as String))
        .toSet(),
    comments: ((json['comments'] as List<Object?>?) ?? const [])
        .map((e) => CheckInComment.fromJson(e! as Map<String, Object?>))
        .toList(),
  );
}

/// Mensagem no mural de incentivo ("Lembrança afetuosa").
class Encouragement {
  const Encouragement({
    required this.id,
    required this.challengeId,
    required this.from,
    required this.to,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String challengeId;
  final UserProfile from;
  final UserProfile to;
  final String message;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'challengeId': challengeId,
    'from': from.toJson(),
    'to': to.toJson(),
    'message': message,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Encouragement.fromJson(Map<String, Object?> json) => Encouragement(
    id: json['id']! as String,
    challengeId: json['challengeId']! as String,
    from: UserProfile.fromJson(json['from']! as Map<String, Object?>),
    to: UserProfile.fromJson(json['to']! as Map<String, Object?>),
    message: json['message']! as String,
    createdAt: DateTime.parse(json['createdAt']! as String),
  );
}

/// Linha do placar de consistência (calculada a partir dos check-ins).
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.member,
    required this.checkInDays,
    required this.elapsedDays,
    required this.currentStreak,
    required this.checkedInToday,
  });

  final UserProfile member;
  final int checkInDays;
  final int elapsedDays;
  final int currentStreak;
  final bool checkedInToday;

  double get consistency =>
      elapsedDays == 0 ? 0 : (checkInDays / elapsedDays).clamp(0.0, 1.0);

  /// Rótulo motivacional sem culpa.
  String get mood {
    final c = consistency;
    if (c >= 1) return 'Ritmo impecável';
    if (c >= 0.97) return 'Consistente';
    if (c >= 0.92) return 'Focado';
    if (c >= 0.8) return 'Em recuperação';
    return 'Recomeçando';
  }
}
