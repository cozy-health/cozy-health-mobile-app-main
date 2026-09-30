class PersonalizationQuestion {
  final String title;
  final String subtitle;
  final PersonalizationQuestionType type;
  final List<String> options;

  PersonalizationQuestion({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.options,
  });

  static List<PersonalizationQuestion> get questions => [
        PersonalizationQuestion(
          title: 'Personalizing cozy for you ...',
          subtitle: 'Add challenges you would like cozy to help you with',
          type: PersonalizationQuestionType.challenges,
          options: [
            'Anxiety',
            'Grief',
            'Pregnancy',
            'Trauma',
            'Health Issues',
            'Relationships',
            'Work Stress',
            'Depression',
            'Motivation',
            'Anger',
            'Sleep',
            'Loneliness',
            'Burnout',
            'Parenting',
            'Self-esteem',
          ],
        ),
        PersonalizationQuestion(
          title: 'What would you like to do?',
          subtitle: 'You can pick as much as you want',
          type: PersonalizationQuestionType.goals,
          options: [
            'Reflection and journaling',
            'Reduce stress and anxiety',
            'Improve mood',
            'Improve sleep quality',
            'Increase productivity',
            'Boost positive thinking',
          ],
        ),
        PersonalizationQuestion(
          title: 'How old are you?',
          subtitle: 'This will help cozy understand you better',
          type: PersonalizationQuestionType.age,
          options: [
            'Under 18',
            '18-24',
            '25-34',
            '35-44',
            '45-54',
            '55-64',
            'Over 64',
          ],
        ),
        PersonalizationQuestion(
          title: 'What gender are you?',
          subtitle: 'This will help cozy understand you better',
          type: PersonalizationQuestionType.gender,
          options: [
            'Male',
            'Female',
          ],
        ),
      ];
}

enum PersonalizationQuestionType {
  challenges,
  goals,
  age,
  gender,
}