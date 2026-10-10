import '../models/app_notification.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';

/// Review fixtures. Never persist these to an account or enqueue them for sync.
class PlaceholderData {
  static List<Map<String, dynamic>> posts() => List.generate(
    8,
    (i) => {
      'id': 'demo-post-$i',
      'username': ['sarahchen', 'mike', 'jordan', 'alex'][i % 4],
      'isAnonymous': i == 1 || i == 4,
      'timeAgo': ['2h', '4h', '6h', '1d', '1d', '2d', '2d', '3d'][i],
      'topic': [
        'Anxiety',
        'Self-compassion',
        'Depression',
        'Trauma',
        'Sleep',
        'Anxiety',
        'Self-compassion',
        'Sleep',
      ][i],
      'content': [
        'I took a short walk today and noticed the birds. A small pause helped me feel more settled.',
        'I am practising speaking to myself the way I would speak to a friend. Today I started with one kind sentence.',
        'Some days move slowly. I made myself lunch and that feels like a small win worth keeping.',
        'I made time for a quiet cup of tea today. Finding a comfortable routine is helping me take things at my own pace.',
        'Putting my phone aside before bed helped me make room for rest. What gentle evening routines do you enjoy?',
        'Before a busy morning I tried a few slow breaths. It gave me a moment to choose my next step.',
        'I wrote down three things I appreciated today, including a friendly message. Small moments count.',
        'I am trying a regular bedtime this week. I am keeping it flexible and noticing how I feel each morning.',
      ][i],
      'likes': [12, 28, 5, 8, 16, 4, 11, 7][i],
      'comments': [4, 9, 7, 2, 12, 3, 6, 5][i],
      'isLiked': false,
    },
  );

  static List<MoodEntry> moods({DateTime? now}) {
    final current = now ?? DateTime.now();
    return List.generate(14, (i) {
      final scheduled = DateTime(
        current.year,
        current.month,
        current.day - i,
        18,
        30,
      );
      final date = scheduled.isAfter(current) ? current : scheduled;
      return MoodEntry(
        id: 'demo-mood-$i',
        mood: ['good', 'calm', 'okay', 'anxious', 'sad'][i % 5],
        intensity: [8, 7, 6, 5, 4, 7, 6, 5, 4, 3, 6, 5, 4, 6][i],
        triggers: [
          if (i % 3 == 0) 'Work Stress',
          if (i % 4 == 0) 'Exam Stress',
          if (i % 2 == 0) 'Poor Sleep',
        ],
        sleepQuality: 3 + i % 3,
        energyLevel: 5 + i % 4,
        createdAt: date,
        updatedAt: date,
      );
    });
  }

  static List<JournalEntry> journals({DateTime? now}) {
    final current = now ?? DateTime.now();
    return List.generate(5, (i) {
      final scheduled = DateTime(current.year, current.month, current.day - i, 19);
      final date = scheduled.isAfter(current) ? current : scheduled;
      final text = [
        'I made space for a quiet moment today. I want to remember that small steps are enough.',
        'A conversation with a friend helped me feel connected. I appreciated being heard.',
        'I noticed I was rushing, so I paused for a glass of water and a little fresh air.',
        'Today felt busy. Tomorrow I would like to leave some room between tasks.',
        'I enjoyed a familiar song and a warm meal. These small comforts helped me unwind.',
      ][i];
      return JournalEntry(
        id: 'demo-journal-$i',
        type: 'free',
        title: 'A small moment',
        body: text,
        tags: [
          ['good'],
          ['calm'],
          ['okay'],
          ['anxious'],
          ['sad'],
        ][i],
        linkedMoodEntryId: 'demo-mood-$i',
        wordCount: text.split(' ').length,
        createdAt: date,
        updatedAt: date,
      );
    });
  }

  static List<AppNotification> notifications({DateTime? now}) {
    final current = now ?? DateTime.now();
    return List.generate(
      6,
      (i) => AppNotification(
        id: 'demo-notification-$i',
        type: [
          'reminder',
          'reply',
          'like',
          'system',
          'achievement',
          'crisis',
        ][i],
        title: [
          'Evening check-in',
          'A new reply',
          'Community support',
          'Welcome',
          'A small milestone',
          'Support is here',
        ][i],
        body: [
          'Time for your evening check-in.',
          'Someone replied to your post.',
          'Your post got 5 new likes.',
          'Welcome to Cozy Health.',
          "You're on a 3-day streak!",
          'Crisis resources are always here.',
        ][i],
        read: i >= 4,
        createdAt: current.subtract(Duration(hours: i * 4)),
      ),
    );
  }

  static List<Map<String, String>> articles() => List.generate(
    6,
    (i) => {
      'id': 'demo-article-$i',
      'title': [
        'Mental Health 101: Understanding Anxiety, Depression, and Stress',
        'Balancing Productivity and Mental Health: How to Avoid Burnout',
        'The Link Between Diet, Exercise, and Mental Health',
        'The Role of Gratitude in Improving Mental Health',
        "Sleep and Mood: What's the Connection?",
        'Building a Support System',
      ][i],
      'readTime': '${4 + i % 3} min read',
      'category': [
        'Anxiety',
        'Work & Life',
        'Wellbeing',
        'Self-compassion',
        'Sleep',
        'Relationships',
      ][i],
      'image': 'assets/svg/journaling.svg',
      'excerpt': [
        'Learn the words we use for common experiences and find a gentle place to start.',
        'Make room for rest alongside the things you want to get done.',
        'Notice how everyday routines support your sense of wellbeing.',
        'A simple reflection on the small things you appreciate.',
        'Explore a gentle evening routine and notice how you feel.',
        'Think about the people and places where you feel heard.',
      ][i],
      'body': [
        'Start by noticing how you feel without judging it. A brief check-in can help you find words for your experience. You can ask someone you trust for support when you need it.',
        'Choose one task that matters today and leave room for a break. A short walk, a drink of water, or stepping away from a screen can make a useful pause. Let your plan remain flexible.',
        'Everyday routines can offer comfort. Try noticing how you feel after a meal, a short walk, or a moment of rest. There is no perfect routine; start with what feels manageable for you.',
        'Write down one thing you appreciated today. It can be as small as a warm drink or a kind message. Making room for difficult feelings and moments of gratitude can happen together.',
        'A familiar evening routine can help create space for rest. You might put your phone aside, dim a light, or read a few pages. Notice what feels comfortable and adjust your routine gently.',
        'A support system can begin with one trusted person. Think about who helps you feel heard and what kind of support you would like. You can start a conversation with a small, specific request.',
      ][i],
    },
  );

  static const activity = {
    'moodTrend': 15,
    'writingStreak': 3,
    'triggers': [
      {'name': 'Work Stress', 'percent': 64, 'impact': 'Medium impact'},
      {'name': 'Exam Stress', 'percent': 80, 'impact': 'High impact'},
      {'name': 'Poor Sleep', 'percent': 75, 'impact': 'Medium impact'},
    ],
  };
}
