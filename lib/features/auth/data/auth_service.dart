import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/response_data.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/guest_session_service.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/services/restore_service.dart';
import '../../../core/services/background_restore_service.dart';
import '../../../core/services/user_data_fetcher.dart';
import '../../../core/services/device_integrity_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/storage/device_proof_storage.dart';
import 'signin_security.dart';

class AuthLocalDataException implements Exception {
  const AuthLocalDataException();
  String get message =>
      'Your sign-in was accepted, but this device could not open your saved data. '
      'Please contact support before reinstalling.';
}

class AuthService {
  static Future<void>? _loggingOut;
  static Future<void>? _activating;

  static Future<void> _serializeActivation(Future<void> Function() work) {
    final previous = _activating;
    final next = previous == null
        ? Future<void>.sync(work)
        : previous.then((_) => work());
    final settled = next.catchError((Object _) {});
    _activating = settled;
    unawaited(
      settled.then((_) {
        if (identical(_activating, settled)) _activating = null;
      }),
    );
    return next;
  }

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final DeviceProofStorage _deviceProofs;
  final BackgroundRestoreService _backgroundRestore;

  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    DeviceProofStorage? deviceProofs,
    BackgroundRestoreService? backgroundRestore,
  }) : _apiClient = apiClient ?? ApiClient(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _deviceProofs = deviceProofs ?? DeviceProofStorage(),
       _backgroundRestore =
           backgroundRestore ?? BackgroundRestoreService.instance;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool stayLoggedIn = false,
  }) async {
    final generation = TokenStorage.generation;
    final proof = await _deviceProofs.forEmail(email);
    _checkAttempt(generation);
    final response = await _apiClient.post(
      ApiConstants.login,
      withAuth: false,
      body: {
        'email': email,
        'password': password,
        'device_id': await _tokenStorage.deviceId(),
        'device_name': defaultTargetPlatform.name,
        if (proof != null) 'device_proof': proof,
      },
    );

    final data = _payload(responseMap(response));
    return _completeOrChallenge(
      data,
      stayLoggedIn: stayLoggedIn,
      generation: generation,
    );
  }

  Future<Map<String, dynamic>> loginWithGoogle(
    String idToken, {
    bool stayLoggedIn = true,
    String? identityHint,
  }) async {
    final generation = TokenStorage.generation;
    final proof = identityHint == null
        ? null
        : await _deviceProofs.forHint(identityHint);
    _checkAttempt(generation);
    final response = await _apiClient.post(
      ApiConstants.googleLogin,
      withAuth: false,
      body: {
        'id_token': idToken,
        'device_name': defaultTargetPlatform.name,
        'device_id': await _tokenStorage.deviceId(),
        if (proof != null) 'device_proof': proof,
      },
    );
    final data = _payload(responseMap(response));
    return _completeOrChallenge(
      data,
      stayLoggedIn: stayLoggedIn,
      generation: generation,
      identityHint: identityHint,
    );
  }

  Future<Map<String, dynamic>> loginWithApple({
    required String identityToken,
    String? authorizationCode,
    String? fullName,
    String? email,
    bool stayLoggedIn = true,
    String? identityHint,
  }) async {
    final generation = TokenStorage.generation;
    final proof = identityHint == null
        ? null
        : await _deviceProofs.forHint(identityHint);
    _checkAttempt(generation);
    final response = await _apiClient.post(
      ApiConstants.appleLogin,
      withAuth: false,
      body: {
        'identity_token': identityToken,
        if (authorizationCode != null && authorizationCode.isNotEmpty)
          'authorization_code': authorizationCode,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        if (email != null && email.isNotEmpty) 'email': email,
        'device_name': defaultTargetPlatform.name,
        'device_id': await _tokenStorage.deviceId(),
        if (proof != null) 'device_proof': proof,
      },
    );
    final data = _payload(responseMap(response));
    return _completeOrChallenge(
      data,
      stayLoggedIn: stayLoggedIn,
      generation: generation,
      identityHint: identityHint,
    );
  }

  Future<Map<String, dynamic>> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    required String confirmPassword,
    String? dateOfBirth,
    String? residenceCountry,
  }) async {
    final generation = TokenStorage.generation;
    final name = '$firstname $lastname'.trim();
    final response = await _apiClient.post(
      ApiConstants.register,
      withAuth: false,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': confirmPassword,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (residenceCountry != null) 'residence_country': residenceCountry,
        'device_id': await _tokenStorage.deviceId(),
        'device_name': defaultTargetPlatform.name,
      },
    );

    final data = _payload(responseMap(response));
    return _completeOrChallenge(
      data,
      stayLoggedIn: true,
      generation: generation,
      registration: true,
    );
  }

  void _checkAttempt(int generation) {
    if (generation != TokenStorage.generation) {
      throw const SignInAttemptChanged();
    }
  }

  Future<Map<String, dynamic>> _completeOrChallenge(
    Map<String, dynamic> data, {
    required bool stayLoggedIn,
    required int generation,
    bool registration = false,
    String? identityHint,
  }) async {
    _checkAttempt(generation);
    if (data['challenge_required'] == true) {
      final user = data['user'];
      throw SignInChallengeRequired(
        PendingSignIn(
          challenge: SignInChallenge.fromJson(data),
          generation: generation,
          stayLoggedIn: stayLoggedIn,
          newAccount: registration || data['is_new_user'] == true,
          expectedAccountId: user is Map ? user['id']?.toString() : null,
          identityHint: identityHint,
        ),
      );
    }
    await _acceptSession(
      data,
      stayLoggedIn: stayLoggedIn,
      registration: registration || data['is_new_user'] == true,
      expectedGeneration: generation,
    );
    return data;
  }

  Future<PendingSignIn> resendSignIn(PendingSignIn attempt) async {
    _checkAttempt(attempt.generation);
    final response = await _apiClient.post(
      '/auth/challenge/resend',
      withAuth: false,
      body: {'challenge_token': attempt.challenge.token},
    );
    _checkAttempt(attempt.generation);
    return attempt.withChallenge(
      SignInChallenge.fromJson(_payload(responseMap(response))),
    );
  }

  Future<VerifiedSignIn> verifySignIn(
    PendingSignIn attempt, {
    String? code,
    Map<String, String>? answers,
  }) async {
    _checkAttempt(attempt.generation);
    final response = await _apiClient.post(
      '/auth/challenge/verify',
      withAuth: false,
      body: {
        'challenge_token': attempt.challenge.token,
        if (code != null) 'code': code,
        if (answers != null) 'answers': answers,
      },
    );
    _checkAttempt(attempt.generation);
    return VerifiedSignIn(
      data: _payload(responseMap(response)),
      attempt: attempt,
    );
  }

  Options? _provisionalOptions(VerifiedSignIn? provisional) =>
      provisional == null
      ? null
      : Options(
          headers: {'Authorization': 'Bearer ${provisional.data['token']}'},
        );

  Future<SignInPreferences> signInPreferences({
    VerifiedSignIn? provisional,
  }) async {
    final generation =
        provisional?.attempt.generation ?? TokenStorage.generation;
    _checkAttempt(generation);
    final response = await _apiClient.get(
      '/auth/security',
      withAuth: provisional == null,
      options: _provisionalOptions(provisional),
    );
    _checkAttempt(generation);
    return SignInPreferences.fromJson(_payload(responseMap(response)));
  }

  Future<SignInChallenge> verifySecuritySettings(String password) async {
    final generation = TokenStorage.generation;
    final response = await _apiClient.post(
      '/auth/security/reauthenticate',
      body: {'password': password},
    );
    _checkAttempt(generation);
    return SignInChallenge.fromJson(_payload(responseMap(response)));
  }

  Future<String> confirmSecuritySettings(
    SignInChallenge challenge,
    String code,
  ) async {
    final generation = TokenStorage.generation;
    final response = await _apiClient.post(
      '/auth/challenge/verify',
      withAuth: false,
      body: {'challenge_token': challenge.token, 'code': code},
    );
    _checkAttempt(generation);
    final data = _payload(responseMap(response));
    final ticket = data['security_settings_token'];
    if (data['verified'] != true ||
        ticket is! String ||
        !SignInChallenge.tokenPattern.hasMatch(ticket)) {
      throw const FormatException('Invalid settings verification.');
    }
    return ticket;
  }

  Future<SignInPreferences> saveSignInPreferences({
    required String method,
    required String settingsToken,
    List<Map<String, String>>? questions,
    VerifiedSignIn? provisional,
  }) async {
    final generation =
        provisional?.attempt.generation ?? TokenStorage.generation;
    _checkAttempt(generation);
    final response = await _apiClient.put(
      '/auth/security',
      withAuth: provisional == null,
      options: _provisionalOptions(provisional),
      body: {
        'method': method,
        'security_settings_token': settingsToken,
        if (questions != null) 'questions': questions,
      },
    );
    _checkAttempt(generation);
    return SignInPreferences.fromJson(_payload(responseMap(response)));
  }

  Future<Map<String, dynamic>> finishVerifiedSignIn(
    VerifiedSignIn verified,
  ) async {
    final attempt = verified.attempt;
    _checkAttempt(attempt.generation);
    if (verified.requiresEnrollment &&
        !(await signInPreferences(provisional: verified)).enrolled) {
      throw StateError('Choose your sign-in protection before continuing.');
    }
    _checkAttempt(attempt.generation);
    final user = Map<String, dynamic>.from(verified.data['user'] as Map);
    final proof = verified.data['device_proof'];
    final remembered =
        proof is String &&
        await _deviceProofs.remember(
          accountId: user['id'].toString(),
          email: user['email'] as String,
          proof: proof,
          identityHint: attempt.identityHint,
        );
    _checkAttempt(attempt.generation);
    final data = {
      ...verified.data,
      'is_new_user': attempt.newAccount,
      'device_remembered': remembered,
    };
    await _acceptSession(
      data,
      stayLoggedIn: attempt.stayLoggedIn,
      registration: attempt.newAccount,
      expectedGeneration: attempt.generation,
    );
    return data;
  }

  Future<Map<String, dynamic>> me() async {
    return _payload(responseMap(await _apiClient.get(ApiConstants.me)));
  }

  Future<bool> resumeStoredSession() async {
    await _loggingOut;
    final generation = TokenStorage.generation;
    var restored = false;
    await _serializeActivation(() async {
      _checkAttempt(generation);
      final profile = await me();
      _checkAttempt(generation);
      final userId = profile['user_id']?.toString();
      if (userId == null) {
        throw const FormatException('Missing account identity.');
      }
      final local = LocalDbService();
      local.syncPaused = true;
      try {
        await local.waitForSyncIdle();
        _checkAttempt(generation);
        await _activateAuthenticatedAccount(
          userId,
          email: profile['email']?.toString(),
          generation: generation,
        );
        _checkOwner(userId, generation);
        await GuestSessionService().exitGuestSession();
        _checkOwner(userId, generation);
        restored = await RestoreService.prepare(userId);
        _checkOwner(userId, generation);
      } finally {
        local.syncPaused = _loggingOut != null;
      }
      unawaited(local.processSyncQueue(force: true));
      _restoreInBackground(userId);
    });
    return restored;
  }

  Future<void> logout() => _loggingOut ??= _logout().whenComplete(() {
    _loggingOut = null;
  });

  Future<void> _logout() async {
    final local = LocalDbService.instance;
    local.syncPaused = true;
    final token = _tokenStorage.activeToken;
    final device = _tokenStorage.deviceId();
    _apiClient.cancelSessionRequests();
    // Invalidate immediately, before waiting for storage or account activation.
    final clearing = _tokenStorage.clearToken();
    try {
      await clearing;
      await _activating;
      await GuestSessionService().exitGuestSession();
      await local.activateGuest();
    } finally {
      local.syncPaused = false;
      if (token != null) {
        unawaited(
          device
              .then(
                (deviceId) => _apiClient.post(
                  ApiConstants.logout,
                  withAuth: false,
                  data: {'device_id': deviceId},
                  options: Options(
                    headers: {'Authorization': 'Bearer $token'},
                    sendTimeout: const Duration(seconds: 5),
                    receiveTimeout: const Duration(seconds: 5),
                  ),
                ),
              )
              .timeout(const Duration(seconds: 5))
              .then<void>((_) {}, onError: (Object _) {}),
        );
      }
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return _payload(
      responseMap(
        await _apiClient.post(
          ApiConstants.forgotPassword,
          withAuth: false,
          body: {'email': email},
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return _payload(
      responseMap(
        await _apiClient.post(
          ApiConstants.resetPassword,
          withAuth: false,
          body: {'email': email, 'token': otp, 'password': newPassword},
        ),
      ),
    );
  }

  Map<String, dynamic> _payload(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map<String, dynamic> ? data : response;
  }

  void _checkOwner(String owner, int generation) {
    _checkAttempt(generation);
    if (LocalDbService().activeUserId != owner) {
      throw const SignInAttemptChanged();
    }
  }

  Future<void> _cacheUserProfile(
    dynamic user,
    String owner,
    int generation,
  ) async {
    _checkOwner(owner, generation);
    if (user is! Map) return;

    final json = Map<String, dynamic>.from(user);
    final id = json['id']?.toString();
    final email = json['email']?.toString();
    final name = json['name']?.toString();

    if (id == null || email == null || name == null || name.isEmpty) return;

    final cached = LocalDbService.instance.getUserProfile();
    if (cached != null) return;

    await LocalDbService.instance.saveUserProfile(
      UserProfile(
        id: id,
        name: name,
        email: email,
        username: json['username']?.toString(),
        avatarUrl:
            json['avatar_url']?.toString() ??
            LocalDbService.instance.getUserProfile()?.avatarUrl,
        avatarRevision:
            LocalDbService.instance.getUserProfile()?.avatarRevision ?? 0,
        updatedAt:
            DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
            DateTime.now(),
      ),
    );
    _checkOwner(owner, generation);
    final settings = await LocalDbService().settingsBox();
    _checkOwner(owner, generation);
    await settings.put('auth_profile_placeholder', true);
  }

  Future<void> _acceptSession(
    Map<String, dynamic> data, {
    required bool stayLoggedIn,
    bool registration = false,
    int? expectedGeneration,
  }) async {
    await _loggingOut;
    if (expectedGeneration != null) _checkAttempt(expectedGeneration);
    await _serializeActivation(
      () => _installSession(
        data,
        stayLoggedIn: stayLoggedIn,
        registration: registration,
        expectedGeneration: expectedGeneration,
      ),
    );
  }

  Future<void> _installSession(
    Map<String, dynamic> data, {
    required bool stayLoggedIn,
    required bool registration,
    int? expectedGeneration,
  }) async {
    if (expectedGeneration != null) _checkAttempt(expectedGeneration);
    final token = data['token']?.toString();
    final user = data['user'];
    if (token == null || token.isEmpty || user is! Map || user['id'] == null) {
      throw const FormatException('Missing session identity.');
    }
    final local = LocalDbService();
    final owner = user['id'].toString();
    local.syncPaused = true;
    try {
      _apiClient.cancelSessionRequests();
      final transitionGeneration = TokenStorage.generation + 1;
      await _tokenStorage.clearToken();
      _checkAttempt(transitionGeneration);
      await local.waitForSyncIdle();
      _checkAttempt(transitionGeneration);
      await _activateAuthenticatedAccount(
        owner,
        email: user['email']?.toString(),
        registration: registration,
        generation: transitionGeneration,
      );
      _checkOwner(owner, transitionGeneration);
      final installedGeneration = await _tokenStorage.saveSession(
        token,
        refreshToken: data['refresh_token']?.toString(),
        stayLoggedIn: stayLoggedIn,
      );
      _checkOwner(owner, installedGeneration);
      await _tokenStorage.recordActivity();
      _checkOwner(owner, installedGeneration);
      unawaited(DeviceIntegrityService.instance.reportIfDetected());
      await GuestSessionService().exitGuestSession();
      _checkOwner(owner, installedGeneration);
      final settings = await local.settingsBox();
      _checkOwner(owner, installedGeneration);
      await settings.put('device_user_id', user['id'].toString());
      _checkOwner(owner, installedGeneration);
      await _cacheUserProfile(user, owner, installedGeneration);
      _checkOwner(owner, installedGeneration);
      await settings.put(
        'new_account_tour_pending',
        registration || data['is_new_user'] == true,
      );
      _checkOwner(owner, installedGeneration);
      await RestoreService.prepare(
        user['id'].toString(),
        registration: registration,
      );
      _checkOwner(owner, installedGeneration);
    } finally {
      local.syncPaused = _loggingOut != null;
    }
    _restoreInBackground(user['id'].toString());
    unawaited(local.processSyncQueue(force: true));
  }

  Future<void> _activateAuthenticatedAccount(
    String userId, {
    String? email,
    bool registration = false,
    int? generation,
  }) async {
    try {
      final local = LocalDbService();
      await local.prepareAuthenticatedAccount(userId);
      if (generation != null) _checkAttempt(generation);
      await local.activateAccount(
        userId,
        email: email,
        registration: registration,
      );
    } on SignInAttemptChanged {
      rethrow;
    } catch (_) {
      throw const AuthLocalDataException();
    }
  }

  void _restoreInBackground(String owner) {
    unawaited(
      _backgroundRestore
          .start(owner)
          .then((_) async {
            if (LocalDbService().activeUserId == owner &&
                await _tokenStorage.getToken() != null) {
              await UserDataFetcher().fetchSubscription();
            }
          })
          .catchError((Object _) {
            /* Home remains usable with its cached information. */
          }),
    );
  }
}
