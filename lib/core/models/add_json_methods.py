import os
import re

models_dir = r"c:\projects\cozyhealth\cozy-health-mobile-app-main-main\lib\core\models"

def replace_in_file(filepath, add_methods):
    with open(filepath, "r") as f:
        content = f.read()
    
    # insert before the last closing brace
    last_brace_idx = content.rfind('}')
    if last_brace_idx != -1:
        new_content = content[:last_brace_idx] + "\n" + add_methods + "\n" + content[last_brace_idx:]
        with open(filepath, "w") as f:
            f.write(new_content)

mood_entry_methods = """
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'mood': mood,
    };
    if (energyLevel != null) json['energy_level'] = energyLevel;
    if (bodySensations != null) json['body_sensations'] = bodySensations;
    if (triggers != null) json['triggers'] = triggers;
    if (customTrigger != null) json['custom_trigger'] = customTrigger;
    if (sleepQuality != null) json['sleep_quality'] = sleepQuality;
    if (note != null) json['note'] = note;
    if (copingStrategies != null) json['coping_strategies'] = copingStrategies;
    if (copingHelped != null) json['coping_helped'] = copingHelped;
    json['is_crisis_flagged'] = isCrisisFlagged;
    json['client_created_at'] = createdAt.toUtc().toIso8601String();
    if (updatedAt != null) json['client_updated_at'] = updatedAt!.toUtc().toIso8601String();
    return json;
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String,
      mood: json['mood'] as String,
      energyLevel: json['energy_level'] as int?,
      bodySensations: (json['body_sensations'] as List<dynamic>?)?.map((e) => e as String).toList(),
      triggers: (json['triggers'] as List<dynamic>?)?.map((e) => e as String).toList(),
      customTrigger: json['custom_trigger'] as String?,
      sleepQuality: json['sleep_quality'] as int?,
      note: json['note'] as String?,
      copingStrategies: (json['coping_strategies'] as List<dynamic>?)?.map((e) => e as String).toList(),
      copingHelped: json['coping_helped'] as String?,
      isCrisisFlagged: json['is_crisis_flagged'] as bool? ?? false,
      createdAt: json['client_created_at'] != null ? DateTime.parse(json['client_created_at']) : DateTime.now(),
      updatedAt: json['client_updated_at'] != null ? DateTime.parse(json['client_updated_at']) : null,
    );
  }
"""
replace_in_file(os.path.join(models_dir, "mood_entry.dart"), mood_entry_methods)

journal_entry_methods = """
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'type': type,
      'body': body,
      'word_count': wordCount,
      'is_crisis_flagged': isCrisisFlagged,
      'client_created_at': createdAt.toUtc().toIso8601String(),
    };
    if (title != null) json['title'] = title;
    if (voiceUrl != null) json['voice_url'] = voiceUrl;
    if (voiceDuration != null) json['voice_duration'] = voiceDuration;
    if (transcription != null) json['transcription'] = transcription;
    if (promptId != null) json['prompt_id'] = promptId;
    if (promptText != null) json['prompt_text'] = promptText;
    if (tags != null) json['tags'] = tags;
    if (linkedMoodEntryId != null) json['linked_mood_entry_id'] = linkedMoodEntryId;
    if (updatedAt != null) json['client_updated_at'] = updatedAt!.toUtc().toIso8601String();
    return json;
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'free',
      title: json['title'] as String?,
      body: json['body'] as String? ?? '',
      voiceUrl: json['voice_url'] as String?,
      voiceDuration: json['voice_duration'] as int?,
      transcription: json['transcription'] as String?,
      promptId: json['prompt_id'] as String?,
      promptText: json['prompt_text'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      linkedMoodEntryId: json['linked_mood_entry_id'] as String?,
      wordCount: json['word_count'] as int? ?? 0,
      isCrisisFlagged: json['is_crisis_flagged'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false, // Legacy
      createdAt: json['client_created_at'] != null ? DateTime.parse(json['client_created_at']) : DateTime.now(),
      updatedAt: json['client_updated_at'] != null ? DateTime.parse(json['client_updated_at']) : null,
    );
  }
"""
replace_in_file(os.path.join(models_dir, "journal_entry.dart"), journal_entry_methods)

chat_conversation_methods = """
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'title': title,
      'message_count': messageCount,
      'is_archived': isArchived,
      'client_updated_at': updatedAt.toUtc().toIso8601String(),
    };
    if (lastMessagePreview != null) json['last_message_preview'] = lastMessagePreview;
    return json;
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String,
      title: json['title'] as String,
      lastMessagePreview: json['last_message_preview'] as String?,
      messageCount: json['message_count'] as int? ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      updatedAt: json['client_updated_at'] != null ? DateTime.parse(json['client_updated_at']) : DateTime.now(),
    );
  }
"""
replace_in_file(os.path.join(models_dir, "chat_conversation.dart"), chat_conversation_methods)

chat_message_methods = """
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'conversation_id': conversationId,
      'role': role,
      'content': content,
      'status': status,
      'is_crisis_flagged': isCrisisFlagged,
      'client_created_at': createdAt.toUtc().toIso8601String(),
    };
    if (modelUsed != null) json['model_used'] = modelUsed;
    if (tokensUsed != null) json['tokens_used'] = tokensUsed;
    if (latencyMs != null) json['latency_ms'] = latencyMs;
    return json;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      status: json['status'] as String? ?? 'sent',
      isCrisisFlagged: json['is_crisis_flagged'] as bool? ?? false,
      modelUsed: json['model_used'] as String?,
      tokensUsed: json['tokens_used'] as int?,
      latencyMs: json['latency_ms'] as int?,
      createdAt: json['client_created_at'] != null ? DateTime.parse(json['client_created_at']) : DateTime.now(),
    );
  }
"""
replace_in_file(os.path.join(models_dir, "chat_message.dart"), chat_message_methods)

safety_plan_methods = """
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'is_complete': isComplete,
      'last_updated_at': lastUpdatedAt.toUtc().toIso8601String(),
    };
    if (warningSigns != null) json['warning_signs'] = warningSigns;
    if (copingStrategies != null) json['coping_strategies'] = copingStrategies;
    if (distractions != null) json['distractions'] = distractions;
    if (people != null) json['people'] = people;
    if (professionals != null) json['professionals'] = professionals;
    if (environmentSteps != null) json['environment_steps'] = environmentSteps;
    return json;
  }

  factory SafetyPlan.fromJson(Map<String, dynamic> json) {
    return SafetyPlan(
      id: json['id'] as String,
      warningSigns: (json['warning_signs'] as List<dynamic>?)?.map((e) => e as String).toList(),
      copingStrategies: (json['coping_strategies'] as List<dynamic>?)?.map((e) => e as String).toList(),
      distractions: (json['distractions'] as List<dynamic>?)?.map((e) => e as String).toList(),
      people: (json['people'] as List<dynamic>?)?.map((e) => Map<String, String>.from(e)).toList(),
      professionals: (json['professionals'] as List<dynamic>?)?.map((e) => Map<String, String>.from(e)).toList(),
      environmentSteps: (json['environment_steps'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isComplete: json['is_complete'] as bool? ?? false,
      lastUpdatedAt: json['last_updated_at'] != null ? DateTime.parse(json['last_updated_at']) : DateTime.now(),
    );
  }
"""
replace_in_file(os.path.join(models_dir, "safety_plan.dart"), safety_plan_methods)

user_profile_methods = """
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'theme': theme,
      'accent_color': accentColor,
      'language': language,
      'reduce_motion': reduceMotion,
      'high_contrast': highContrast,
      'haptics_enabled': hapticsEnabled,
      'text_size': textSize,
      'show_stats': showStats,
      'show_username': showUsername,
      'notifications_master': notificationsMaster,
      'daily_checkin_enabled': dailyCheckinEnabled,
      'daily_checkin_time': dailyCheckinTime,
      'journal_reminder_enabled': journalReminderEnabled,
      'comments_notifications': commentsNotifications,
      'achievements_notifications': achievementsNotifications,
      'marketing_notifications': marketingNotifications,
      'client_updated_at': updatedAt.toUtc().toIso8601String(),
    };
    if (username != null) json['username'] = username;
    if (avatarUrl != null) json['avatar_url'] = avatarUrl;
    if (bio != null) json['bio'] = bio;
    if (onboardingCompletedAt != null) json['onboarding_completed_at'] = onboardingCompletedAt!.toUtc().toIso8601String();
    return json;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      theme: json['theme'] as String? ?? 'system',
      accentColor: json['accent_color'] as String? ?? '#0460D8',
      language: json['language'] as String? ?? 'en',
      reduceMotion: json['reduce_motion'] as bool? ?? false,
      highContrast: json['high_contrast'] as bool? ?? false,
      hapticsEnabled: json['haptics_enabled'] as bool? ?? true,
      textSize: (json['text_size'] as num?)?.toDouble() ?? 1.0,
      showStats: json['show_stats'] as bool? ?? false,
      showUsername: json['show_username'] as bool? ?? true,
      notificationsMaster: json['notifications_master'] as bool? ?? true,
      dailyCheckinEnabled: json['daily_checkin_enabled'] as bool? ?? true,
      dailyCheckinTime: json['daily_checkin_time'] as String? ?? '09:00',
      journalReminderEnabled: json['journal_reminder_enabled'] as bool? ?? false,
      commentsNotifications: json['comments_notifications'] as bool? ?? true,
      achievementsNotifications: json['achievements_notifications'] as bool? ?? true,
      marketingNotifications: json['marketing_notifications'] as bool? ?? false,
      onboardingCompletedAt: json['onboarding_completed_at'] != null ? DateTime.parse(json['onboarding_completed_at']) : null,
      updatedAt: json['client_updated_at'] != null ? DateTime.parse(json['client_updated_at']) : DateTime.now(),
    );
  }
"""
replace_in_file(os.path.join(models_dir, "user_profile.dart"), user_profile_methods)

quiz_attempt_methods = """
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'quiz_slug': quizSlug,
      'quiz_title': quizTitle,
      'answers': answers,
      'score': score,
      'is_crisis_flagged': isCrisisFlagged,
      'completed_at': completedAt.toUtc().toIso8601String(),
    };
    if (interpretation != null) json['interpretation'] = interpretation;
    return json;
  }

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'] as String,
      quizSlug: json['quiz_slug'] as String,
      quizTitle: json['quiz_title'] as String,
      answers: Map<String, dynamic>.from(json['answers'] as Map),
      score: json['score'] as int,
      interpretation: json['interpretation'] as String?,
      isCrisisFlagged: json['is_crisis_flagged'] as bool? ?? false,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : DateTime.now(),
    );
  }
"""
replace_in_file(os.path.join(models_dir, "quiz_attempt.dart"), quiz_attempt_methods)

saved_article_methods = """
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'article_id': articleId,
      'article_slug': articleSlug,
      'title': title,
      'category': category,
      'read_time_minutes': readTimeMinutes,
      'saved_at': savedAt.toUtc().toIso8601String(),
    };
  }

  factory SavedArticle.fromJson(Map<String, dynamic> json) {
    return SavedArticle(
      id: json['id'] as String,
      articleId: json['article_id'] as String,
      articleSlug: json['article_slug'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      readTimeMinutes: json['read_time_minutes'] as int,
      savedAt: json['saved_at'] != null ? DateTime.parse(json['saved_at']) : DateTime.now(),
    );
  }
"""
replace_in_file(os.path.join(models_dir, "saved_article.dart"), saved_article_methods)

app_notification_methods = """
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'is_read': isRead,
      'client_created_at': createdAt.toUtc().toIso8601String(),
    };
    if (deepLink != null) json['deep_link'] = deepLink;
    if (data != null) json['data'] = data;
    if (readAt != null) json['read_at'] = readAt!.toUtc().toIso8601String();
    return json;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      deepLink: json['deep_link'] as String?,
      data: json['data'] != null ? Map<String, dynamic>.from(json['data'] as Map) : null,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: json['client_created_at'] != null ? DateTime.parse(json['client_created_at']) : DateTime.now(),
    );
  }
"""
replace_in_file(os.path.join(models_dir, "app_notification.dart"), app_notification_methods)

subscription_status_methods = """
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'plan': plan,
      'status': status,
    };
    if (platform != null) json['platform'] = platform;
    if (productId != null) json['product_id'] = productId;
    if (transactionId != null) json['transaction_id'] = transactionId;
    if (originalTransactionId != null) json['original_transaction_id'] = originalTransactionId;
    if (startedAt != null) json['started_at'] = startedAt!.toUtc().toIso8601String();
    if (expiresAt != null) json['expires_at'] = expiresAt!.toUtc().toIso8601String();
    if (cancelledAt != null) json['cancelled_at'] = cancelledAt!.toUtc().toIso8601String();
    if (trialEndsAt != null) json['trial_ends_at'] = trialEndsAt!.toUtc().toIso8601String();
    if (lastChecked != null) json['last_checked'] = lastChecked!.toUtc().toIso8601String();
    return json;
  }

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      id: json['id'] as String,
      plan: json['plan'] as String? ?? 'free',
      status: json['status'] as String? ?? 'active',
      platform: json['platform'] as String?,
      productId: json['product_id'] as String?,
      transactionId: json['transaction_id'] as String?,
      originalTransactionId: json['original_transaction_id'] as String?,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at']) : null,
      trialEndsAt: json['trial_ends_at'] != null ? DateTime.parse(json['trial_ends_at']) : null,
      lastChecked: json['last_checked'] != null ? DateTime.parse(json['last_checked']) : null,
    );
  }
"""
replace_in_file(os.path.join(models_dir, "subscription_status.dart"), subscription_status_methods)

print("Done")
