import 'package:intl/intl.dart';

class DailyQuotes {
  static const List<String> _quotes = [
    "Suffer the pain of discipline or the pain of regret.",
    "Procrastination is the arrogant assumption that God owes you another chance.",
    "Do today what others won't, so tomorrow you can do what others can't.",
    "You don't have to be extreme, just consistent.",
    "Action cures fear. Inaction creates terror.",
    "We are what we repeatedly do. Excellence, then, is not an act, but a habit.",
    "Motivation gets you going, but discipline keeps you growing.",
    "Stop stopping yourself. The comeback is always stronger than the setback.",
    "Your future is created by what you do today, not tomorrow.",
    "The cost of procrastination is the life you could've lived."
  ];

  // Get a quote based on the current day of the year so it changes daily but stays consistent for the day
  static String get todaysQuote {
    final dayOfYear = int.parse(DateFormat("D").format(DateTime.now()));
    final index = dayOfYear % _quotes.length;
    return _quotes[index];
  }
}
