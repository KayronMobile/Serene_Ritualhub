import 'dart:math';

/// Utilitários de data sem dependências externas (pt-BR).
abstract final class Dates {
  static const weekdayShort = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  static const weekdayLetter = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
  static const weekdayLong = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];
  static const monthLong = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  static const monthShort = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  /// Remove o horário mantendo apenas a data local.
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Chave estável `yyyy-MM-dd` usada na persistência.
  static String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime parseKey(String key) {
    final parts = key.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  /// Soma dias de calendário (seguro contra mudanças de horário de verão).
  static DateTime addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  /// Segunda-feira da semana de [d].
  static DateTime startOfWeek(DateTime d) =>
      addDays(dateOnly(d), -(d.weekday - DateTime.monday));

  /// Diferença em dias de calendário (usa UTC para ignorar DST).
  static int daysBetween(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// "Quarta-feira, 24 de outubro"
  static String longDate(DateTime d) =>
      '${weekdayLong[d.weekday - 1]}, ${d.day} de ${monthLong[d.month - 1]}';

  /// "18 - 24 Out"
  static String weekRange(DateTime start) {
    final end = addDays(start, 6);
    if (start.month == end.month) {
      return '${start.day} - ${end.day} ${monthShort[end.month - 1]}';
    }
    return '${start.day} ${monthShort[start.month - 1]} - '
        '${end.day} ${monthShort[end.month - 1]}';
  }

  /// "22 de outubro"
  static String dayMonth(DateTime d) => '${d.day} de ${monthLong[d.month - 1]}';

  /// Minutos desde a meia-noite -> "07:00"
  static String hhmm(int minutesOfDay) {
    final h = (minutesOfDay ~/ 60) % 24;
    final m = minutesOfDay % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Segundos -> "04:29"
  static String mmss(int seconds) {
    final s = max(0, seconds);
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  /// Minutos -> "7h 45m"
  static String hoursMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  /// "Há 25 min", "Há 1h", "Ontem"
  static String relative(DateTime from, DateTime now) {
    final diff = now.difference(from);
    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ontem';
    return 'Há ${diff.inDays} dias';
  }
}

/// Gera identificadores únicos sem dependências externas.
abstract final class Ids {
  static final _random = Random();

  static String generate([String prefix = 'id']) {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rnd = _random.nextInt(1 << 32).toRadixString(36);
    return '${prefix}_$ts$rnd';
  }
}
