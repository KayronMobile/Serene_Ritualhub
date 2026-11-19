import 'dart:math';

import '../../domain/models/challenge.dart';
import '../../domain/models/health.dart';
import '../../domain/models/ritual.dart';
import '../../domain/models/user_profile.dart';
import '../../utils/dates.dart';

/// Dados de demonstração usados pelos repositórios locais no primeiro uso.
///
/// Todas as datas são relativas a "agora", para que o app sempre abra com
/// uma história coerente (streaks, desafios em andamento, relatório semanal).
abstract final class SeedData {
  // ---------------------------------------------------------------------------
  // Pessoas
  // ---------------------------------------------------------------------------

  /// Placeholder do usuário local nos desafios (id fixo "me").
  static const me = UserProfile(id: 'me', name: 'Você', email: '');

  static const camila = UserProfile(
    id: 'f_camila',
    name: 'Camila Duarte',
    email: 'camila@serene.app',
  );
  static const gabriel = UserProfile(
    id: 'f_gabriel',
    name: 'Gabriel Santos',
    email: 'gabriel@serene.app',
  );
  static const beatriz = UserProfile(
    id: 'f_beatriz',
    name: 'Beatriz Lima',
    email: 'beatriz@serene.app',
  );
  static const marina = UserProfile(
    id: 'f_marina',
    name: 'Marina Alves',
    email: 'marina@serene.app',
  );
  static const rafael = UserProfile(
    id: 'f_rafael',
    name: 'Rafael Costa',
    email: 'rafael@serene.app',
  );
  static const juliana = UserProfile(
    id: 'f_juliana',
    name: 'Juliana Rocha',
    email: 'juliana@serene.app',
  );
  static const pedro = UserProfile(
    id: 'f_pedro',
    name: 'Pedro Henrique',
    email: 'pedro@serene.app',
  );

  static const friends = [
    camila,
    gabriel,
    beatriz,
    marina,
    rafael,
    juliana,
    pedro,
  ];

  /// Probabilidade de cada amigo fazer check-in em um dia (simulação).
  static const reliability = {
    'f_camila': 0.97,
    'f_gabriel': 0.93,
    'f_beatriz': 0.88,
    'f_marina': 0.9,
    'f_rafael': 0.84,
    'f_juliana': 0.95,
    'f_pedro': 0.8,
  };

  // ---------------------------------------------------------------------------
  // Rituais
  // ---------------------------------------------------------------------------

  static List<Ritual> rituals() => const [
    Ritual(
      id: 'ritual_morning',
      name: 'Ritual do Despertar Solar',
      period: RitualPeriod.morning,
      activeWeekdays: {1, 2, 3, 4, 5},
      startMinutes: 7 * 60,
      reminderEnabled: true,
      reminderLeadMinutes: 15,
      focusMode: true,
      linkedChallengeId: 'ch_morning_club',
      shareWithTribe: true,
      steps: [
        RitualStep(
          id: 'm1',
          title: 'Hidratação Matinal',
          type: StepType.hydration,
          durationSeconds: 120,
          description: '500ml de água morna com limão',
          instruction:
              'Beba devagar, em pequenos goles, sentindo a água morna '
              'despertar o corpo de dentro para fora.',
          tip: 'Deixe a garrafa ao lado da cama na noite anterior.',
          waterMl: 500,
        ),
        RitualStep(
          id: 'm2',
          title: 'Alongamento & Mobilidade',
          type: StepType.movement,
          durationSeconds: 420,
          description: 'Fluxo suave de 7 minutos para coluna e pescoço',
          instruction:
              'Inspire pelo nariz por 4 segundos, solte os ombros e mantenha '
              'a coluna alinhada. Permita que a tensão saia do corpo '
              'suavemente.',
          ambientSound: 'Chuva Suave na Floresta',
          tip: 'Libere a mandíbula e relaxe os músculos faciais.',
        ),
        RitualStep(
          id: 'm3',
          title: 'Respiração Focada & Leitura',
          type: StepType.reading,
          durationSeconds: 600,
          description: '10 minutos de serenidade',
          instruction:
              'Comece com três ciclos 4-4-6: inspire 4s, segure 4s, expire '
              '6s. Depois leia 10 páginas com calma, sem pressa de terminar.',
          tip: 'Leia em papel: a luz da tela atrasa o despertar natural.',
          pages: 10,
        ),
      ],
    ),
    Ritual(
      id: 'ritual_afternoon',
      name: 'Pausa Ativa da Tarde',
      period: RitualPeriod.afternoon,
      activeWeekdays: {1, 2, 3, 4, 5},
      startMinutes: 15 * 60,
      reminderEnabled: true,
      reminderLeadMinutes: 5,
      steps: [
        RitualStep(
          id: 'a1',
          title: 'Copo d’Água',
          type: StepType.hydration,
          durationSeconds: 60,
          description: '300ml para recarregar a atenção',
          instruction: 'Pause o que estiver fazendo e beba um copo inteiro.',
          waterMl: 300,
        ),
        RitualStep(
          id: 'a2',
          title: 'Caminhada Leve',
          type: StepType.movement,
          durationSeconds: 600,
          description: '10 minutos de movimento ao ar livre',
          instruction:
              'Caminhe em ritmo confortável, observando três coisas novas '
              'ao seu redor.',
          tip: 'Se estiver chovendo, suba e desça escadas devagar.',
        ),
        RitualStep(
          id: 'a3',
          title: 'Micro-pausa de 1 Minuto',
          type: StepType.breathing,
          durationSeconds: 60,
          description: 'Inspire 4s, retenha 4s, expire 6s',
          instruction:
              'Inspire 4s, retenha 4s e expire em 6s para regular seu ritmo '
              'cardíaco.',
        ),
      ],
    ),
    Ritual(
      id: 'ritual_night',
      name: 'Ritual de Desaceleração',
      period: RitualPeriod.night,
      activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
      startMinutes: 21 * 60 + 30,
      reminderEnabled: true,
      reminderLeadMinutes: 10,
      focusMode: true,
      steps: [
        RitualStep(
          id: 'n1',
          title: 'Chá Calmante',
          type: StepType.custom,
          durationSeconds: 300,
          description: 'Camomila ou erva-cidreira, sem pressa',
          instruction:
              'Segure a xícara com as duas mãos e sinta o calor. Beba '
              'devagar, sem telas por perto.',
          ambientSound: 'Lareira ao Longe',
        ),
        RitualStep(
          id: 'n2',
          title: 'Desconexão de Telas',
          type: StepType.breathing,
          durationSeconds: 120,
          description: 'Celular no modo avião, fora do quarto',
          instruction:
              'Ative o modo avião, deixe o celular carregando longe da cama '
              'e faça cinco respirações lentas.',
        ),
        RitualStep(
          id: 'n3',
          title: 'Leitura Leve',
          type: StepType.reading,
          durationSeconds: 900,
          description: '15 minutos de leitura em papel',
          instruction:
              'Escolha algo leve. Se o sono chegar antes, aceite o convite.',
          pages: 12,
        ),
      ],
    ),
  ];

  /// Histórico das últimas 4 semanas (com sexta-feira noturna mais frágil,
  /// para o insight de "dia de maior falha").
  static List<RitualLog> ritualLogs(List<Ritual> rituals, DateTime now) {
    final rnd = Random(42);
    final today = Dates.dateOnly(now);
    final logs = <RitualLog>[];

    for (var back = 27; back >= 1; back--) {
      final day = Dates.addDays(today, -back);
      final recent = back <= 14;
      for (final ritual in rituals) {
        if (!ritual.isScheduledOn(day)) continue;

        var p = switch (ritual.period) {
          RitualPeriod.morning => 0.9,
          RitualPeriod.afternoon => 0.78,
          RitualPeriod.night => 0.86,
        };
        if (ritual.period == RitualPeriod.night &&
            day.weekday == DateTime.friday) {
          p = 0.3;
        }
        // Garante a sequência recente de consistência.
        final forced =
            recent &&
            ((ritual.period == RitualPeriod.morning) ||
                (ritual.period == RitualPeriod.night && day.weekday >= 6));
        final roll = rnd.nextDouble();
        final complete = forced || roll < p;

        final steps = ritual.steps;
        final doneCount = complete
            ? steps.length
            : (roll < p + 0.25 ? rnd.nextInt(steps.length) : 0);
        if (doneCount == 0 && !complete) continue;

        final done = steps.take(doneCount).map((s) => s.id).toSet();
        final skipped = complete && rnd.nextDouble() < 0.15
            ? {steps.last.id}
            : <String>{};
        final guided = steps
            .where((s) => done.contains(s.id))
            .fold<int>(0, (sum, s) => sum + s.durationSeconds);
        final finish = DateTime(
          day.year,
          day.month,
          day.day,
        ).add(Duration(minutes: ritual.startMinutes + ritual.totalMinutes));

        logs.add(
          RitualLog(
            ritualId: ritual.id,
            date: day,
            completedStepIds: done,
            skippedStepIds: skipped,
            totalSteps: steps.length,
            completedAt: complete
                ? finish.add(Duration(minutes: rnd.nextInt(10) - 4))
                : null,
            guidedSeconds: guided,
          ),
        );
      }
    }

    // Hoje: primeiro bloco do ritual matinal concluído ("1/3 concluído").
    final morning = rituals.firstWhere(
      (r) => r.period == RitualPeriod.morning,
      orElse: () => rituals.first,
    );
    if (morning.isScheduledOn(today) && now.hour >= 7) {
      logs.add(
        RitualLog(
          ritualId: morning.id,
          date: today,
          completedStepIds: {morning.steps.first.id},
          skippedStepIds: const {},
          totalSteps: morning.steps.length,
          guidedSeconds: morning.steps.first.durationSeconds,
        ),
      );
    }
    return logs;
  }

  // ---------------------------------------------------------------------------
  // Saúde
  // ---------------------------------------------------------------------------

  static List<DailyHealthLog> healthLogs(DateTime now, HealthGoals goals) {
    final rnd = Random(7);
    final today = Dates.dateOnly(now);
    final logs = <DailyHealthLog>[];
    for (var back = 27; back >= 1; back--) {
      final day = Dates.addDays(today, -back);
      final hydrated = back <= 11; // sequência do "Guardião da Hidratação"
      logs.add(
        DailyHealthLog(
          date: day,
          waterMl: hydrated
              ? goals.waterMl + rnd.nextInt(5) * 100
              : 1700 + rnd.nextInt(10) * 100,
          sleepMinutes: 400 + rnd.nextInt(90),
          deepSleepPercent: 78 + rnd.nextInt(18),
          activityMinutes: 20 + rnd.nextInt(45),
          readingMinutes: 10 + rnd.nextInt(30),
          updatedAt: day.add(const Duration(hours: 22)),
        ),
      );
    }
    logs.add(
      DailyHealthLog(
        date: today,
        waterMl: now.hour < 9 ? 500 : 1450,
        sleepMinutes: 465,
        deepSleepPercent: 92,
        activityMinutes: now.hour < 9 ? 0 : 25,
        readingMinutes: now.hour < 9 ? 0 : 18,
        updatedAt: now.subtract(const Duration(minutes: 12)),
      ),
    );
    return logs;
  }

  // ---------------------------------------------------------------------------
  // Desafios
  // ---------------------------------------------------------------------------

  static List<Challenge> challenges(DateTime now) {
    final today = Dates.dateOnly(now);
    return [
      Challenge(
        id: 'ch_sugar',
        title: '21 Dias Sem Açúcar & Mais Energia',
        description:
            'Redescobrindo a disposição natural com apoio e partilha diária.',
        category: ChallengeCategory.nutrition,
        startDate: Dates.addDays(today, -11),
        durationDays: 21,
        members: const [me, camila, gabriel, beatriz, marina, rafael],
        createdBy: camila.id,
        dailyGoal: 'Nenhum açúcar adicionado no dia',
      ),
      Challenge(
        id: 'ch_morning_club',
        title: 'Clube das 06:00',
        description: 'Conexão matinal antes do sol nascer.',
        category: ChallengeCategory.morning,
        startDate: Dates.addDays(today, -7),
        durationDays: 30,
        members: const [me, camila, juliana, pedro, rafael],
        createdBy: me.id,
        dailyGoal: 'Concluir o ritual matinal antes das 07:30',
      ),
      Challenge(
        id: 'ch_reading',
        title: '30 Dias de Leitura',
        description: 'Dez páginas por dia, juntos, sem pressa.',
        category: ChallengeCategory.reading,
        startDate: Dates.addDays(today, -45),
        durationDays: 30,
        members: const [me, gabriel, marina],
        createdBy: gabriel.id,
        dailyGoal: 'Ler ao menos 10 páginas',
      ),
    ];
  }

  /// Check-ins do próprio usuário (histórico) + posts em destaque de hoje.
  static List<CheckIn> checkIns(List<Challenge> challenges, DateTime now) {
    final today = Dates.dateOnly(now);
    final list = <CheckIn>[];

    for (final c in challenges) {
      final lastDay = c.isFinished(now) ? c.endDate : Dates.addDays(today, -1);
      var day = c.startDate;
      var i = 0;
      while (!day.isAfter(lastDay)) {
        // O usuário pulou 2 dias no desafio de leitura (já encerrado)
        // e 1 dia no Clube das 06:00.
        final skip =
            (c.id == 'ch_reading' && (i == 9 || i == 20)) ||
            (c.id == 'ch_morning_club' && i == 3);
        if (!skip) {
          list.add(
            CheckIn(
              id: 'seed_me_${c.id}_$i',
              challengeId: c.id,
              author: me,
              createdAt: day.add(const Duration(hours: 8, minutes: 10)),
              caption: captionFor(c.category, i),
              context: 'Check-in diário',
            ),
          );
        }
        day = Dates.addDays(day, 1);
        i++;
      }
    }

    list.addAll([
      CheckIn(
        id: 'seed_today_camila',
        challengeId: 'ch_sugar',
        author: camila,
        createdAt: now.subtract(const Duration(minutes: 25)),
        caption:
            'Café sem adoçante e frutas vermelhas! Mais um dia concluído 💪 '
            'Energia limpa e mente leve.',
        tag: 'Sem Açúcar Adicionado',
        context: 'Ritual Matinal',
        reactions: const {Reaction.cheer: 14, Reaction.inspiring: 8},
        comments: [
          CheckInComment(
            id: 'cm1',
            author: gabriel,
            text: 'Que combinação linda! Vou testar amanhã.',
            createdAt: now.subtract(const Duration(minutes: 20)),
          ),
          CheckInComment(
            id: 'cm2',
            author: marina,
            text: 'Inspiração pura ✨',
            createdAt: now.subtract(const Duration(minutes: 15)),
          ),
          CheckInComment(
            id: 'cm3',
            author: rafael,
            text: 'Bora que hoje é dia 12!',
            createdAt: now.subtract(const Duration(minutes: 8)),
          ),
        ],
      ),
      CheckIn(
        id: 'seed_today_gabriel',
        challengeId: 'ch_sugar',
        author: gabriel,
        createdAt: now.subtract(const Duration(hours: 1)),
        caption:
            'Primeiro litro do dia batido às 09:30. A diferença na clareza '
            'mental quando trocamos o refrigerante por água saborizada é '
            'gigante!',
        tag: 'Meta: 3 Litros',
        context: 'Hidratação Consciente',
        reactions: const {Reaction.water: 9, Reaction.fire: 5},
        comments: [
          CheckInComment(
            id: 'cm4',
            author: camila,
            text: 'Água saborizada salva! 💧',
            createdAt: now.subtract(const Duration(minutes: 40)),
          ),
        ],
      ),
    ]);
    return list;
  }

  static const _captions = {
    ChallengeCategory.nutrition: [
      'Mais um dia limpo! Troquei a sobremesa por frutas.',
      'Foi difícil no café da tarde, mas segurei firme 🙌',
      'Descobri que gosto de café puro. Quem diria!',
      'Energia estável o dia inteiro, sem aquele pico.',
    ],
    ChallengeCategory.morning: [
      'Acordei antes do despertador hoje ☀️',
      'Ritual matinal completo. Que silêncio bom.',
      'Alongamento + chá e o dia já começou leve.',
    ],
    ChallengeCategory.reading: [
      '10 páginas antes de dormir ✔️',
      'Terminei um capítulo inteiro hoje!',
      'Leitura no café da manhã, sem celular.',
    ],
    ChallengeCategory.hydration: [
      'Garrafa cheia de novo 💧',
      'Meta batida antes do almoço!',
    ],
    ChallengeCategory.sleep: [
      'Telas desligadas às 21h30. Dormi como pedra.',
      'Quarto escuro e silencioso: 8h de sono!',
    ],
    ChallengeCategory.movement: [
      'Caminhada de 30 min no parque 🌳',
      'Yoga leve antes do trabalho.',
    ],
    ChallengeCategory.mindfulness: [
      '10 minutos de meditação guiada.',
      'Respiração 4-4-6 antes de uma reunião difícil. Funcionou!',
    ],
  };

  static String captionFor(ChallengeCategory category, int seed) {
    final pool = _captions[category] ?? const ['Check-in feito!'];
    return pool[seed % pool.length];
  }

  /// Hash FNV-1a estável (não depende de `String.hashCode`).
  static int stableHash(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  /// 0..1 determinístico por chave.
  static double unitRandom(String key) => stableHash(key) / 0xFFFFFFFF;

  /// Modelos de desafio da aba "Descobrir".
  static const templates = [
    ChallengeTemplate(
      title: '21 Dias Sem Açúcar',
      description: 'Energia constante e presença.',
      category: ChallengeCategory.nutrition,
      durationDays: 21,
      dailyGoal: 'Nenhum açúcar adicionado no dia',
    ),
    ChallengeTemplate(
      title: '30 Dias de Leitura',
      description: 'Dez páginas por dia, em boa companhia.',
      category: ChallengeCategory.reading,
      durationDays: 30,
      dailyGoal: 'Ler ao menos 10 páginas',
    ),
    ChallengeTemplate(
      title: '14 Dias de Hidratação',
      description: 'Bata sua meta de água todos os dias.',
      category: ChallengeCategory.hydration,
      durationDays: 14,
      dailyGoal: 'Atingir a meta diária de água',
    ),
    ChallengeTemplate(
      title: 'Telas Off às 22h',
      description: 'Higiene do sono coletiva por 21 noites.',
      category: ChallengeCategory.sleep,
      durationDays: 21,
      dailyGoal: 'Desligar as telas até 22h',
    ),
    ChallengeTemplate(
      title: '10 Mil Passos',
      description: 'Movimento leve e diário por 30 dias.',
      category: ChallengeCategory.movement,
      durationDays: 30,
      dailyGoal: 'Caminhar 10 mil passos ou 45 min',
    ),
    ChallengeTemplate(
      title: 'Clube das 06:00',
      description: 'Conexão matinal antes do sol nascer.',
      category: ChallengeCategory.morning,
      durationDays: 30,
      dailyGoal: 'Concluir o ritual matinal antes das 07:30',
    ),
  ];
}
