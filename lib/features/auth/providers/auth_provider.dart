/// Firebase Authentication Provider
/// Handles user authentication with Firebase Auth
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tulasihotels/core/config/razorpay_config.dart';
import 'package:tulasihotels/core/constants/app_constants.dart';
import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:tulasihotels/core/services/cloud_function_helper.dart';
import 'package:tulasihotels/core/services/demo_data_service.dart';
import 'package:tulasihotels/core/services/offline_storage_service.dart';
import 'package:tulasihotels/features/referral/services/referral_service.dart';
import 'package:tulasihotels/core/services/payment_link_service.dart';
import 'package:tulasihotels/features/subscription/models/plan_config.dart';
import 'package:tulasihotels/firebase_options.dart';
import 'package:tulasihotels/features/settings/providers/theme_settings_provider.dart';
import 'package:tulasihotels/features/settings/providers/settings_provider.dart';
import 'package:tulasihotels/features/notifications/services/fcm_token_service.dart';
import 'package:tulasihotels/features/notifications/services/notification_service.dart';
import 'package:tulasihotels/features/notifications/services/windows_notification_service.dart';
import 'package:tulasihotels/models/user_model.dart';

/// Google sign-in instance (shared for sign-out)
final googleSignInProvider = Provider<GoogleSignIn>((ref) => GoogleSignIn());

/// Sentinel value for distinguishing "not provided" from "set to null" in copyWith
const _sentinel = Object();

/// Auth state
enum AuthStatus { unauthenticated, authenticated }

/// Auth state class
class AuthState {
  final AuthStatus status;
  final User? firebaseUser;
  final UserModel? user;
  final bool isLoggedIn;
  final bool isShopSetupComplete;
  final bool isEmailVerified;
  final bool isDemoMode;
  final bool isLoading;
  final String? error;

  /// Desktop auth: current link code (A19)
  final String? desktopLinkCode;

  /// Desktop auth: when the link code expires (A19)
  final DateTime? desktopLinkExpiresAt;

  /// Desktop auth: URL for embedded WebView login (Windows)
  final String? desktopLoginUrl;

  /// Account linking: email of the account that needs linking
  final String? pendingLinkEmail;

  /// Account linking: true when a password dialog should be shown
  final bool pendingAccountLink;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.firebaseUser,
    this.user,
    this.isLoggedIn = false,
    this.isShopSetupComplete = false,
    this.isEmailVerified = false,
    this.isDemoMode = false,
    this.isLoading = true,
    this.error,
    this.desktopLinkCode,
    this.desktopLinkExpiresAt,
    this.desktopLoginUrl,
    this.pendingLinkEmail,
    this.pendingAccountLink = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    Object? firebaseUser = _sentinel,
    Object? user = _sentinel,
    bool? isLoggedIn,
    bool? isShopSetupComplete,
    bool? isEmailVerified,
    bool? isDemoMode,
    bool? isLoading,
    String? error,
    String? desktopLinkCode,
    DateTime? desktopLinkExpiresAt,
    Object? desktopLoginUrl = _sentinel,
    Object? pendingLinkEmail = _sentinel,
    bool? pendingAccountLink,
  }) {
    return AuthState(
      status: status ?? this.status,
      firebaseUser: firebaseUser == _sentinel
          ? this.firebaseUser
          : firebaseUser as User?,
      user: user == _sentinel ? this.user : user as UserModel?,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isShopSetupComplete: isShopSetupComplete ?? this.isShopSetupComplete,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      desktopLinkCode: desktopLinkCode ?? this.desktopLinkCode,
      desktopLinkExpiresAt: desktopLinkExpiresAt ?? this.desktopLinkExpiresAt,
      desktopLoginUrl: desktopLoginUrl == _sentinel
          ? this.desktopLoginUrl
          : desktopLoginUrl as String?,
      pendingLinkEmail: pendingLinkEmail == _sentinel
          ? this.pendingLinkEmail
          : pendingLinkEmail as String?,
      pendingAccountLink: pendingAccountLink ?? this.pendingAccountLink,
    );
  }
}

/// Firebase Auth Notifier
class FirebaseAuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref _ref;
  StreamSubscription<User?>? _authSub;
  bool _profileLoaded = false;
  bool _authResolved = false;
  bool _pendingReauth = false;
  bool _signOutTriggered = false;
  bool _profileLoadInProgress = false;
  Completer<void>? _profileLoadCompleter;

  /// Stores a Google credential while waiting for password to complete linking
  AuthCredential? _pendingGoogleCredential;

  /// Desktop auth: cancellation support
  Completer<bool>? _desktopAuthCompleter;
  StreamSubscription<DocumentSnapshot>? _desktopAuthSub;
  Timer? _desktopAuthTimer;

  FirebaseAuthNotifier(this._ref) : super(const AuthState()) {
    _init();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  /// Rebuild settings/theme providers so they pick up the new user's data.
  /// Called after login and logout instead of having those providers watch auth.
  /// Deferred to a microtask so it doesn't run in the middle of a state setter.
  void _refreshSettingsProviders() {
    Future.microtask(() {
      _ref.invalidate(settingsProvider);
      _ref.invalidate(themeSettingsProvider);
    });
  }

  /// Initialize - listen to auth state changes
  void _init() {
    // Safety timeout: if authStateChanges doesn't fire within 5 seconds,
    // resolve loading state based on currentUser
    Future.delayed(const Duration(seconds: 5), () async {
      if (state.isLoading && !_profileLoaded && !_authResolved) {
        _authResolved = true;
        final user = _auth.currentUser;
        try {
          if (user != null) {
            await _loadUserProfile(user);
          } else {
            state = const AuthState(isLoading: false);
          }
        } catch (e) {
          debugPrint('🔐 Auth timeout handler error: $e');
          state = const AuthState(isLoading: false);
        }
      }
    });

    // Ultimate safety net: if still loading after 10 seconds, force-resolve
    Future.delayed(const Duration(seconds: 10), () {
      if (state.isLoading) {
        state = const AuthState(isLoading: false);
      }
    });

    // Handle redirect result when page returns from Google sign-in (Layer 3 fallback)
    // On web, getRedirectResult() can block authStateChanges from firing its first event,
    // so we add a timeout to prevent it from hanging indefinitely.
    if (kIsWeb) {
      _auth
          .getRedirectResult()
          .timeout(const Duration(seconds: 5))
          .then((result) async {
            if (result.user != null) {
              debugPrint(
                '🔐 Google redirect sign-in complete: ${result.user!.email}',
              );
              await _ensureFirestoreDoc(result.user!);
            }
          })
          .catchError((e) {
            if (e is FirebaseAuthException &&
                e.code == 'account-exists-with-different-credential') {
              _pendingGoogleCredential = e.credential;
              state = state.copyWith(
                isLoading: false,
                pendingAccountLink: true,
                pendingLinkEmail: e.email,
              );
              return;
            }
            debugPrint('🔐 Redirect result check: $e');
          });
    }
    _authSub = _auth.authStateChanges().listen(
      (User? user) async {
        if (user != null) {
          if (_authResolved && !_pendingReauth) {
            return; // Prevent double load from timeout + listener race
          }
          _authResolved = true;
          _pendingReauth = false;
          _profileLoaded = true;
          await _loadUserProfile(user);
        } else {
          // On web, Firebase can emit a spurious null after a valid user event.
          // Only treat as logout if we haven't successfully loaded a profile,
          // or if a deliberate sign-out was triggered.
          if (_profileLoaded && !_signOutTriggered) {
            return;
          }
          _authResolved = true;
          _signOutTriggered = false;
          state = const AuthState(isLoading: false);
        }
      },
      onError: (Object error) {
        debugPrint('🔐 authStateChanges stream error: $error');
        if (state.isLoading) {
          _authResolved = true;
          state = const AuthState(isLoading: false);
        }
      },
    );
  }

  /// Ensure Firestore user document exists (called after redirect sign-in)
  Future<void> _ensureFirestoreDoc(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email?.toLowerCase() ?? '',
          'ownerName': user.displayName ?? '',
          'phone': user.phoneNumber ?? '',
          'photoUrl': user.photoURL ?? '',
          'isShopSetupComplete': false,
          'emailVerified': true,
          'phoneVerified': false,
          'authProvider': 'google',
          'appType': 'hotels',
          'createdAt': FieldValue.serverTimestamp(),
          'subscription': {
            'plan': 'free',
            'startDate': FieldValue.serverTimestamp(),
          },
          'limits': {
            'productsCount': 0,
            'productsLimit': PlanConfig.free.productsLimitFirestore,
            'billsThisMonth': 0,
            'billsLimit': PlanConfig.free.billsLimitFirestore,
            'customersCount': 0,
            'customersLimit': PlanConfig.free.customersLimitFirestore,
            'staffCount': 0,
            'staffLimit': PlanConfig.free.staffLimitFirestore,
            'tablesCount': 0,
            'tablesLimit': PlanConfig.free.tablesLimitFirestore,
          },
        });
        debugPrint('✅ Created Firestore doc for redirect user: ${user.email}');
      } else {
        // Tag existing user for Hotels app if not already tagged
        final data = doc.data()!;
        final appType = data['appType'] as String? ?? '';
        final updates = <String, dynamic>{};
        if (appType != 'hotels') {
          updates['appType'] = 'hotels';
        }
        if (!(data['emailVerified'] as bool? ?? false)) {
          updates['emailVerified'] = true;
        }
        if (user.photoURL != null && user.photoURL!.isNotEmpty) {
          updates['photoUrl'] = user.photoURL;
        }
        if (updates.isNotEmpty) {
          await _firestore.collection('users').doc(user.uid).update(updates);
        }
      }
    } catch (e) {
      debugPrint('🔐 Error ensuring Firestore doc: $e');
    }
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile(User firebaseUser) async {
    if (_profileLoadInProgress) {
      // Another call already loading — wait for it to finish instead of
      // returning immediately. This prevents signIn() from returning true
      // before authState.user is populated (web race condition where
      // authStateChanges listener starts _loadUserProfile first).
      await _profileLoadCompleter?.future;
      return;
    }
    _profileLoadInProgress = true;
    _profileLoadCompleter = Completer<void>();
    try {
      debugPrint('🔐 _loadUserProfile: START for ${firebaseUser.uid}');
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get()
          .timeout(const Duration(seconds: 10));
      debugPrint('🔐 _loadUserProfile: Firestore doc exists=${doc.exists}');

      // Google sign-in users are always email-verified
      final isGoogleUser = firebaseUser.providerData.any(
        (p) => p.providerId == 'google.com',
      );

      if (doc.exists) {
        final data = doc.data()!;

        // Guard: a ghost store doc was auto-created for team members who logged
        // in before this fix. Detect it by checking for ownerUid — real owners
        // always have ownerUid; ghost docs (from old auto-create) don't.
        final ownerUid = data['ownerUid'] as String?;
        final isGhostDoc = ownerUid == null || ownerUid.isEmpty;

        if (isGhostDoc) {
          // Verify they are actually a team member (has hotel entries they
          // were invited to, but no owned store)
          bool hasOwnedHotel = false;
          try {
            final hotelEntries = await _firestore
                .collection('user_hotels/${firebaseUser.uid}/hotels')
                .where('role', isEqualTo: 'owner')
                .limit(1)
                .get();
            hasOwnedHotel = hotelEntries.docs.isNotEmpty;
          } catch (_) {}

          if (!hasOwnedHotel) {
            // Team member with a stale ghost doc — treat as team member
            debugPrint(
              '🔐 _loadUserProfile: Ghost store doc detected for team member — treating as member',
            );
            state = AuthState(
              status: AuthStatus.authenticated,
              firebaseUser: firebaseUser,
              isLoggedIn: true,
              isShopSetupComplete: true,
              isEmailVerified: isGoogleUser || firebaseUser.emailVerified,
              isLoading: false,
              user: UserModel(
                id: firebaseUser.uid,
                shopName: '',
                ownerName:
                    firebaseUser.displayName ??
                    (data['ownerName'] as String? ?? ''),
                email: firebaseUser.email,
                phone: '',
                settings: const UserSettings(),
                createdAt: DateTime.now(),
              ),
            );
            _refreshSettingsProviders();
            return;
          }
          // They DO have owned hotels — backfill ownerUid so we don't re-check next time
          unawaited(
            _firestore.collection('users').doc(firebaseUser.uid).set({
              'ownerUid': firebaseUser.uid,
            }, SetOptions(merge: true)),
          );
        }

        // Fall back to shopName presence — covers legacy users whose
        // Firestore doc never got the boolean set.
        final isShopSetupComplete =
            (data['isShopSetupComplete'] as bool? ?? false) ||
            (data['shopName'] as String? ?? '').isNotEmpty;

        // Backfill limits for users missing productsLimit (required by Firestore rules)
        final limits = data['limits'] as Map<String, dynamic>?;
        if (limits == null || limits['productsLimit'] == null) {
          unawaited(
            _firestore.collection('users').doc(firebaseUser.uid).set({
              'limits': {
                'productsCount': limits?['productsCount'] ?? 0,
                'productsLimit': PlanConfig.free.productsLimitFirestore,
                'billsThisMonth': limits?['billsThisMonth'] ?? 0,
                'billsLimit': PlanConfig.free.billsLimitFirestore,
                'customersCount': limits?['customersCount'] ?? 0,
                'customersLimit': PlanConfig.free.customersLimitFirestore,
                'staffCount': limits?['staffCount'] ?? 0,
                'staffLimit': PlanConfig.free.staffLimitFirestore,
                'tablesCount': limits?['tablesCount'] ?? 0,
                'tablesLimit': PlanConfig.free.tablesLimitFirestore,
              },
            }, SetOptions(merge: true)),
          );
        }

        // Load this user's cloud settings into local SharedPreferences
        debugPrint('🔐 _loadUserProfile: Loading cloud settings...');
        await OfflineStorageService.loadAllSettingsFromCloud();
        debugPrint('🔐 _loadUserProfile: Cloud settings loaded');

        final emailVerified =
            isGoogleUser ||
            (data['emailVerified'] as bool?) == true ||
            firebaseUser.emailVerified;

        state = AuthState(
          status: AuthStatus.authenticated,
          firebaseUser: firebaseUser,
          isLoggedIn: true,
          isShopSetupComplete: isShopSetupComplete,
          isEmailVerified: emailVerified,
          isLoading: false,
          user: UserModel(
            id: firebaseUser.uid,
            shopName: data['shopName'] as String? ?? '',
            ownerName: data['ownerName'] as String? ?? '',
            email: firebaseUser.email,
            phone: data['phone'] as String? ?? '',
            address: data['address'] as String?,
            gstNumber: data['gstNumber'] as String?,
            shopLogoPath: data['shopLogoPath'] as String?,
            profileImagePath: data['profileImagePath'] as String?,
            photoUrl: data['photoUrl'] as String? ?? firebaseUser.photoURL,
            upiId: data['upiId'] as String?,
            settings: UserSettings.fromMap(
              (data['settings'] as Map<String, dynamic>?) ?? {},
            ),
            phoneVerified: (data['phoneVerified'] as bool?) ?? false,
            emailVerified: emailVerified,
            phoneVerifiedAt: (data['phoneVerifiedAt'] as Timestamp?)?.toDate(),
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            consentVersion: data['consentVersion'] as String?,
          ),
        );
        // Keep Razorpay checkout title up to date with user's shop name
        RazorpayConfig.setShopName(data['shopName'] as String? ?? '');
        _refreshSettingsProviders();
        debugPrint(
          '🔐 _loadUserProfile: State set isLoggedIn=true, isShopSetup=$isShopSetupComplete',
        );

        // Save FCM token for push notifications (non-blocking)
        // ignore: unawaited_futures
        FCMTokenService.initAndSaveToken(firebaseUser.uid);
        // Start FCM foreground message listener (Android/Web only)
        NotificationService.initMessageListeners();
        // Start Windows desktop notification listener
        WindowsNotificationService.startListening(firebaseUser.uid);
        // Load UPI ID from user document into PaymentLinkService
        final userUpiId = data['upiId'] as String? ?? '';
        if (userUpiId.isNotEmpty) {
          PaymentLinkService.setUpiId(userUpiId);
        }
      } else {
        debugPrint(
          '🔐 _loadUserProfile: No Firestore doc — checking if team member',
        );

        // A team member (invited via inviteMember) has NO users/{uid} store doc.
        // If we auto-create one they'll be treated as an owner on every future login.
        // Detect team members by checking:
        //   1. user_hotels/{uid}/hotels — already linked with a real UID
        //   2. pending_member_invites   — invited but not yet resolved
        bool isTeamMember = false;

        try {
          final hotelEntries = await _firestore
              .collection('user_hotels/${firebaseUser.uid}/hotels')
              .limit(1)
              .get();
          if (hotelEntries.docs.isNotEmpty) isTeamMember = true;
        } catch (_) {}

        if (!isTeamMember && firebaseUser.email != null) {
          try {
            final invites = await _firestore
                .collection('pending_member_invites')
                .where('email', isEqualTo: firebaseUser.email)
                .limit(1)
                .get();
            if (invites.docs.isNotEmpty) isTeamMember = true;
          } catch (_) {}
        }

        if (isTeamMember) {
          // ── Team member login ──
          // Don't create a store doc. Authenticate with their display name only.
          debugPrint(
            '🔐 _loadUserProfile: Team member detected — skipping store creation',
          );
          state = AuthState(
            status: AuthStatus.authenticated,
            firebaseUser: firebaseUser,
            isLoggedIn: true,
            isShopSetupComplete: true, // skip shop setup for team members
            isEmailVerified: isGoogleUser || firebaseUser.emailVerified,
            isLoading: false,
            user: UserModel(
              id: firebaseUser.uid,
              shopName: '',
              ownerName: firebaseUser.displayName ?? '',
              email: firebaseUser.email,
              phone: '',
              settings: const UserSettings(),
              createdAt: DateTime.now(),
            ),
          );
          _refreshSettingsProviders();
        } else {
          // ── New owner / first-time user ──
          debugPrint('🔐 _loadUserProfile: New user — creating store doc');
          final defaultShopName = firebaseUser.displayName ?? 'My Hotel';
          final newUserData = {
            'shopName': defaultShopName,
            'ownerName': firebaseUser.displayName ?? '',
            'email': firebaseUser.email,
            'phone': '',
            'appType': 'hotels',
            'isShopSetupComplete': true,
            'ownerUid': firebaseUser.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'limits': {
              'productsCount': 0,
              'productsLimit': PlanConfig.free.productsLimitFirestore,
              'billsThisMonth': 0,
              'billsLimit': PlanConfig.free.billsLimitFirestore,
              'customersCount': 0,
              'customersLimit': PlanConfig.free.customersLimitFirestore,
              'staffCount': 0,
              'staffLimit': PlanConfig.free.staffLimitFirestore,
              'tablesCount': 0,
              'tablesLimit': PlanConfig.free.tablesLimitFirestore,
            },
          };
          unawaited(
            _firestore
                .collection('users')
                .doc(firebaseUser.uid)
                .set(newUserData, SetOptions(merge: true)),
          );
          state = AuthState(
            status: AuthStatus.authenticated,
            firebaseUser: firebaseUser,
            isLoggedIn: true,
            isShopSetupComplete: true,
            isEmailVerified: isGoogleUser || firebaseUser.emailVerified,
            isLoading: false,
            user: UserModel(
              id: firebaseUser.uid,
              shopName: defaultShopName,
              ownerName: firebaseUser.displayName ?? '',
              email: firebaseUser.email,
              phone: '',
              settings: const UserSettings(),
              createdAt: DateTime.now(),
            ),
          );
          _refreshSettingsProviders();
        }
      }
    } catch (e) {
      debugPrint('🔐 Error loading user profile: $e');
      state = AuthState(
        status: AuthStatus.authenticated,
        firebaseUser: firebaseUser,
        isLoggedIn: true,
        isLoading: false,
        error: 'Failed to load user profile',
      );
      _refreshSettingsProviders();
    } finally {
      _profileLoadInProgress = false;
      _profileLoadCompleter?.complete();
      _profileLoadCompleter = null;
    }
  }

  /// Sign in with Google — multi-layer approach for maximum reliability
  /// Web: signInWithPopup → GoogleSignIn package → signInWithRedirect
  /// Mobile: GoogleSignIn package directly
  /// Desktop: Try GoogleSignIn package, fall back to helpful message
  Future<bool> signInWithGoogle() async {
    try {
      // Allow authStateChanges listener to process this new sign-in
      _pendingReauth = true;
      _profileLoaded = false;
      if (kIsWeb) {
        return await _googleSignInWeb();
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        // Windows: open Edge app-mode window for Google auth
        return await signInDesktop(autoGoogle: true);
      } else {
        return await _googleSignInMobile();
      }
    } catch (e) {
      debugPrint('🔐 Google sign-in error (all layers failed): $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Google sign-in failed. Please try again.',
      );
      return false;
    }
  }

  /// Web Layer 1: Firebase signInWithPopup
  Future<bool> _googleSignInWeb() async {
    // --- Layer 1: signInWithPopup ---
    try {
      debugPrint('🔐 Google Sign-In: Trying Layer 1 (signInWithPopup)...');
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      final userCredential = await _auth
          .signInWithPopup(googleProvider)
          .timeout(const Duration(seconds: 60));
      final user = userCredential.user;
      if (user != null) {
        await _ensureFirestoreDoc(user);
        // Load profile directly — authStateChanges may not fire reliably
        // on web (especially with 3rd-party cookie blocking in Chrome).
        _authResolved = true;
        _pendingReauth = false;
        _profileLoaded = true;
        await _loadUserProfile(user);
        debugPrint('✅ Google Sign-In Layer 1 success: ${user.email}');
        return true;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('🔐 Layer 1 failed: ${e.code} - ${e.message}');

      // popup-closed-by-user can be a false positive when 3rd-party cookies
      // are blocked: the popup authenticates the user but can't communicate
      // the result back. Check if the user is actually signed in.
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        // Give Firebase a moment to sync the auth state internally
        await Future.delayed(const Duration(seconds: 2));
        // Reload to pick up any sign-in that completed in the popup
        await _auth.currentUser?.reload();
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          debugPrint(
            '🔐 Popup closed but user IS authenticated: ${currentUser.email}',
          );
          await _ensureFirestoreDoc(currentUser);
          _authResolved = true;
          _pendingReauth = false;
          _profileLoaded = true;
          await _loadUserProfile(currentUser);
          return true;
        }
        debugPrint('🔐 Popup closed — no user found, trying Layer 2');
        // Don't return false — try Layer 2 instead
      }

      // Account conflict — save credential for linking after password entry
      if (e.code == 'account-exists-with-different-credential') {
        _pendingGoogleCredential = e.credential;
        state = state.copyWith(
          isLoading: false,
          pendingAccountLink: true,
          pendingLinkEmail: e.email,
        );
        return false;
      }

      // For popup-blocked or other errors, try Layer 2
    } on TimeoutException {
      debugPrint('🔐 Layer 1 timed out');
      // Popup may have authenticated the user but hung communicating back
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint(
          '🔐 Popup timed out but user IS authenticated: ${currentUser.email}',
        );
        await _ensureFirestoreDoc(currentUser);
        _authResolved = true;
        _pendingReauth = false;
        _profileLoaded = true;
        await _loadUserProfile(currentUser);
        return true;
      }
      // Continue to Layer 2
    } catch (e) {
      debugPrint('🔐 Layer 1 failed: $e');
      // Continue to Layer 2
    }

    // --- Layer 2: GoogleSignIn package (GIS flow) ---
    try {
      debugPrint('🔐 Google Sign-In: Trying Layer 2 (GoogleSignIn package)...');
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId:
            '883551466761-9s896hmfvmilcj85v70a90jhea1j8g90.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // Check if user is already authenticated (popup may have succeeded
        // but GIS package failed to return the result)
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          debugPrint(
            '🔐 GIS returned null but user IS authenticated: ${currentUser.email}',
          );
          await _ensureFirestoreDoc(currentUser);
          _authResolved = true;
          _pendingReauth = false;
          _profileLoaded = true;
          await _loadUserProfile(currentUser);
          return true;
        }
        debugPrint('🔐 Layer 2 cancelled & no currentUser — trying Layer 3');
      } else {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;
        if (user != null) {
          await _ensureFirestoreDoc(user);
          _authResolved = true;
          _pendingReauth = false;
          _profileLoaded = true;
          await _loadUserProfile(user);
          debugPrint('✅ Google Sign-In Layer 2 success: ${user.email}');
          return true;
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        _pendingGoogleCredential = e.credential;
        state = state.copyWith(
          isLoading: false,
          pendingAccountLink: true,
          pendingLinkEmail: e.email,
        );
        return false;
      }
      debugPrint('🔐 Layer 2 failed: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('🔐 Layer 2 failed: $e');
      // Continue to Layer 3
    }

    // --- Layer 3: signInWithRedirect (last resort) ---
    try {
      debugPrint('🔐 Google Sign-In: Trying Layer 3 (signInWithRedirect)...');
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      await _auth.signInWithRedirect(googleProvider);
      // Page will redirect — on return, authStateChanges handles login
      return true;
    } catch (e) {
      debugPrint('🔐 Layer 3 failed: $e');
      state = state.copyWith(
        isLoading: false,
        error:
            'Google sign-in failed. Please check your internet connection and try again.',
      );
      return false;
    }
  }

  /// Windows Desktop: Web-based auth via Edge app mode
  /// Opens the hosted web app in a clean Edge window for auth
  /// then listens on Firestore for a custom auth token.
  Future<bool> signInDesktop({bool autoGoogle = false}) async {
    try {
      state = state.copyWith(isLoading: true);
      debugPrint('🖥️ Desktop: Starting web-based auth flow...');

      // 1. Generate a random 8-character link code
      final random = math.Random.secure();
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No ambiguous chars
      final linkCode = List.generate(
        8,
        (_) => chars[random.nextInt(chars.length)],
      ).join();

      debugPrint('🖥️ Desktop: Link code: $linkCode');

      // Derive a simple device identifier for session binding
      final deviceId =
          '${defaultTargetPlatform.name}_${DateTime.now().millisecondsSinceEpoch}';

      // 2. Store pending session in Firestore with TTL + device binding
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      await _firestore.collection('desktop_auth_sessions').doc(linkCode).set({
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'deviceId': deviceId,
      });

      // 3. Set login URL in state — UI shows embedded WebView (no browser needed)
      // restaurants.tulasierp.com may not resolve on some networks/devices.
      // Use Firebase Hosting canonical domain for reliable desktop auth.
      const webAppUrl = 'https://login1-aa21c.web.app/desktop-login';
      final fullUrl = '$webAppUrl?code=$linkCode';

      state = state.copyWith(
        isLoading: true,
        desktopLinkCode: linkCode,
        desktopLinkExpiresAt: expiresAt,
        desktopLoginUrl: fullUrl,
      );

      debugPrint('🖥️ Desktop: Login URL set, waiting for auth token...');

      // 4. Listen for auth token via real-time snapshot (not polling)
      final completer = Completer<bool>();
      _desktopAuthCompleter = completer;

      // Safety timeout after 10 minutes
      _desktopAuthTimer = Timer(const Duration(minutes: 10), () {
        if (!completer.isCompleted) {
          debugPrint('🖥️ Desktop: Auth timed out');
          _desktopAuthSub?.cancel();
          _firestore.collection('desktop_auth_sessions').doc(linkCode).delete();
          state = state.copyWith(
            isLoading: false,
            desktopLoginUrl: null,
            error: 'Sign-in timed out. Please try again.',
          );
          completer.complete(false);
        }
      });

      _desktopAuthSub = _firestore
          .collection('desktop_auth_sessions')
          .doc(linkCode)
          .snapshots()
          .listen(
            (snapshot) async {
              if (completer.isCompleted) return;

              if (!snapshot.exists) {
                debugPrint('🖥️ Desktop: Session deleted (expired)');
                _desktopAuthTimer?.cancel();
                unawaited(_desktopAuthSub?.cancel());
                state = state.copyWith(
                  isLoading: false,
                  desktopLoginUrl: null,
                  error: 'Session expired. Please try again.',
                );
                completer.complete(false);
                return;
              }

              final data = snapshot.data();
              if (data?['status'] == 'ready' && data?['customToken'] != null) {
                final customToken = data!['customToken'] as String;
                debugPrint('🖥️ Desktop: Got custom token, signing in...');

                try {
                  // Sign in with the custom token
                  final credential = await _auth.signInWithCustomToken(
                    customToken,
                  );

                  // Desktop auth stream callbacks can occasionally be delayed or
                  // dropped due platform-channel timing. Load profile directly to
                  // guarantee loading state resolves and router can continue.
                  if (credential.user != null) {
                    _authResolved = true;
                    _pendingReauth = false;
                    _profileLoaded = true;
                    await _loadUserProfile(credential.user!);
                  } else {
                    state = state.copyWith(
                      isLoading: false,
                      desktopLoginUrl: null,
                      error: 'Sign-in failed. Please try again.',
                    );
                    _desktopAuthTimer?.cancel();
                    unawaited(_desktopAuthSub?.cancel());
                    if (!completer.isCompleted) completer.complete(false);
                    return;
                  }

                  // Clean up the session document
                  await _firestore
                      .collection('desktop_auth_sessions')
                      .doc(linkCode)
                      .delete();

                  debugPrint('✅ Desktop: Signed in successfully!');
                  _desktopAuthTimer?.cancel();
                  unawaited(_desktopAuthSub?.cancel());
                  // Clear WebView URL — UI will dismiss the overlay
                  state = state.copyWith(desktopLoginUrl: null);
                  if (!completer.isCompleted) completer.complete(true);
                } catch (e) {
                  debugPrint('🖥️ Desktop: signInWithCustomToken failed: $e');
                  _desktopAuthTimer?.cancel();
                  unawaited(_desktopAuthSub?.cancel());
                  state = state.copyWith(
                    isLoading: false,
                    desktopLoginUrl: null,
                    error: 'Sign-in failed. Please try again.',
                  );
                  if (!completer.isCompleted) completer.complete(false);
                }
              }
            },
            onError: (e) {
              debugPrint('🖥️ Desktop: Snapshot listener error: $e');
              _desktopAuthTimer?.cancel();
              if (!completer.isCompleted) {
                state = state.copyWith(
                  isLoading: false,
                  desktopLoginUrl: null,
                  error: 'Sign-in failed. Please try again.',
                );
                completer.complete(false);
              }
            },
          );

      return await completer.future;
    } catch (e) {
      debugPrint('🖥️ Desktop auth error: $e');
      final msg = e.toString();
      state = state.copyWith(
        isLoading: false,
        error:
            msg.contains('permission-denied') ||
                msg.contains('PERMISSION_DENIED')
            ? 'Firestore permission denied. Please update security rules and redeploy.'
            : 'Sign-in failed. Please try again.',
      );
      return false;
    }
  }

  /// Cancel an in-progress desktop auth flow (user closed the WebView)
  void cancelDesktopAuth() {
    _desktopAuthTimer?.cancel();
    _desktopAuthSub?.cancel();
    if (_desktopAuthCompleter != null && !_desktopAuthCompleter!.isCompleted) {
      _desktopAuthCompleter!.complete(false);
    }
    // Clean up Firestore session
    final linkCode = state.desktopLinkCode;
    if (linkCode != null) {
      _firestore.collection('desktop_auth_sessions').doc(linkCode).delete();
    }
    // Force-clear nullable fields using a fresh state
    state = AuthState(
      status: state.status,
      firebaseUser: state.firebaseUser,
      user: state.user,
      isLoggedIn: state.isLoggedIn,
      isShopSetupComplete: state.isShopSetupComplete,
      isEmailVerified: state.isEmailVerified,
      isDemoMode: state.isDemoMode,
      isLoading: false,
      error: state.error,
      pendingLinkEmail: state.pendingLinkEmail,
      pendingAccountLink: state.pendingAccountLink,
      // desktopLinkCode, desktopLinkExpiresAt, desktopLoginUrl → null
    );
  }

  /// Mobile: GoogleSignIn package
  Future<bool> _googleSignInMobile() async {
    final googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: '883551466761-9s896hmfvmilcj85v70a90jhea1j8g90.apps.googleusercontent.com',
    );
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return false;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await _ensureFirestoreDoc(user);
        _authResolved = true;
        _pendingReauth = false;
        _profileLoaded = true;
        await _loadUserProfile(user);
        debugPrint('✅ Google Sign-In: ${user.email}');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        _pendingGoogleCredential = credential;
        state = state.copyWith(
          isLoading: false,
          pendingAccountLink: true,
          pendingLinkEmail: googleUser.email,
        );
        return false;
      }
      rethrow;
    }
  }

  /// Sign in with email and password
  /// On Windows desktop, uses Firebase Auth REST API (platform channel is buggy)
  Future<bool> signIn({
    String? email,
    String? phone,
    required String password,
  }) async {
    if (email == null && phone == null) {
      state = state.copyWith(error: 'Email is required');
      return false;
    }

    try {
      state = state.copyWith(isLoading: true);
      // Allow authStateChanges listener to process this new sign-in
      _pendingReauth = true;
      _profileLoaded = false;
      final loginEmail = (email ?? phone)!.trim();

      // On Windows desktop, use REST API to bypass buggy platform channel
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        return await _signInWithRestApi(loginEmail, password);
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      if (credential.user != null) {
        debugPrint('✅ User signed in: ${credential.user!.email}');
        // Load profile directly — authStateChanges may not fire reliably
        // for re-sign-in with the same user (especially on web).
        // _profileLoadInProgress guard prevents double-loading if the
        // stream listener already started _loadUserProfile.
        _authResolved = true;
        _pendingReauth = false;
        _profileLoaded = true;
        await _loadUserProfile(credential.user!);
        return true;
      }
      _pendingReauth = false;
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '🔐 FirebaseAuthException: code=${e.code}, message=${e.message}',
      );
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Invalid email or password.';
          break;
        case 'wrong-password':
          message = 'Invalid email or password.';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled. Please contact support.';
          break;
        case 'channel-error':
          message =
              'Connection error. Please check your internet and try again.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;
        default:
          message = 'Login failed (${e.code}). Please check your credentials.';
      }
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      debugPrint('🔐 Login error (generic): $e');
      state = state.copyWith(isLoading: false, error: 'Login failed: $e');
      return false;
    }
  }

  /// Windows-only: Sign in via Firebase Auth REST API
  /// Bypasses the broken platform channel on Windows desktop
  Future<bool> _signInWithRestApi(String email, String password) async {
    try {
      // Use the web API key from Firebase options
      final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
      );

      debugPrint('🖥️ Windows: Using REST API for email sign-in...');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        // Parse Firebase REST API error
        final error = data['error'] as Map<String, dynamic>?;
        final errorMessage = error?['message'] as String? ?? 'Unknown error';
        debugPrint('🖥️ Windows REST API error: $errorMessage');

        String message;
        switch (errorMessage) {
          case 'EMAIL_NOT_FOUND':
            message = 'Invalid email or password.';
            break;
          case 'INVALID_PASSWORD':
          case 'INVALID_LOGIN_CREDENTIALS':
            message = 'Invalid email or password.';
            break;
          case 'USER_DISABLED':
            message = 'This account has been disabled.';
            break;
          case 'TOO_MANY_ATTEMPTS_TRY_LATER':
            message = 'Too many attempts. Please try again later.';
            break;
          default:
            message = 'Login failed: $errorMessage';
        }
        state = state.copyWith(isLoading: false, error: message);
        return false;
      }

      // Success — sign in with the custom token
      final idToken = data['idToken'] as String;
      debugPrint(
        '🖥️ Windows: REST API sign-in successful, exchanging token...',
      );

      // Use signInWithCredential with the returned tokens
      // Create a custom credential using the email link approach won't work,
      // so we use signInWithCustomToken via Cloud Function
      // Instead, let's try signInWithEmailAndPassword one more time — the REST
      // API already authenticated, so we just need to establish the local session.
      // Actually, we can use the idToken directly with a Cloud Function.

      // Simplest approach: The REST API verified credentials, now try to
      // use signInWithEmailAndPassword which should work since the user exists
      // OR use a Cloud Function to generate a custom token from the idToken.

      // Use signInWithEmailLink is not viable. Let's call the cloud function
      // to exchange the idToken for a customToken
      try {
        final data = await CloudFunctionHelper.call('exchangeIdToken', {
          'idToken': idToken,
        });
        final customToken = data['customToken'] as String;
        final cred = await _auth.signInWithCustomToken(customToken);
        debugPrint('✅ Windows: Signed in with custom token');
        if (cred.user != null) {
          _authResolved = true;
          _pendingReauth = false;
          _profileLoaded = true;
          await _loadUserProfile(cred.user!);
        }
        return true;
      } catch (cfError) {
        debugPrint(
          '🖥️ Windows: Cloud Function not available, trying direct auth: $cfError',
        );
        // Fallback: try direct signInWithEmailAndPassword one more time
        try {
          final cred = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          debugPrint('✅ Windows: Direct auth succeeded on retry');
          if (cred.user != null) {
            _authResolved = true;
            _pendingReauth = false;
            _profileLoaded = true;
            await _loadUserProfile(cred.user!);
          }
          return true;
        } catch (retryError) {
          debugPrint('🖥️ Windows: Direct auth retry also failed: $retryError');
          // The REST API confirmed the credentials are correct
          // but we can't establish a local session
          state = state.copyWith(
            isLoading: false,
            error:
                'Credentials verified but session could not be created. Please try Google Sign-In.',
          );
          return false;
        }
      }
    } catch (e) {
      debugPrint('🖥️ Windows REST API error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed. Please check your internet connection.',
      );
      return false;
    }
  }

  /// Register with email and password
  /// On Windows desktop, uses Firebase Auth REST API (platform channel is buggy)
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    bool emailVerified = false,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      // On Windows desktop, use REST API to bypass buggy platform channel
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        return await _registerWithRestApi(
          email: email,
          password: password,
          name: name,
          emailVerified: emailVerified,
        );
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(name.trim());

        // Send email verification only if not already verified via OTP
        if (!emailVerified) {
          try {
            await user.sendEmailVerification();
            debugPrint('📧 Verification email sent to: ${user.email}');
          } catch (e) {
            debugPrint('📧 Failed to send verification email: $e');
          }
        }

        // Create Firestore doc
        await _createUserFirestoreDoc(
          uid: user.uid,
          email: email,
          name: name,
          emailVerified: emailVerified,
        );

        // Load user profile so isLoading becomes false and router can navigate.
        // authStateChanges listener may skip this if _authResolved is already true.
        _authResolved = true;
        _profileLoaded = true;
        await _loadUserProfile(user);

        debugPrint('✅ User registered: ${user.email}');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists with this email. Please login.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        default:
          message = 'Registration failed. Please try again later.';
      }
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      debugPrint('🔐 Registration error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. Please try again.',
      );
      return false;
    }
  }

  /// Create user document in Firestore (shared by normal + REST API register)
  Future<void> _createUserFirestoreDoc({
    required String uid,
    required String email,
    required String name,
    required bool emailVerified,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email.trim().toLowerCase(),
      'ownerName': name.trim(),
      'phone': '',
      'photoUrl': '',
      'isShopSetupComplete': false,
      'emailVerified': emailVerified,
      'phoneVerified': false,
      'authProvider': 'email',
      'createdAt': FieldValue.serverTimestamp(),
      'subscription': {
        'plan': 'free',
        'startDate': FieldValue.serverTimestamp(),
      },
    });
  }

  /// Windows-only: Register via Firebase Auth REST API
  Future<bool> _registerWithRestApi({
    required String email,
    required String password,
    required String name,
    required bool emailVerified,
  }) async {
    try {
      final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
      );

      debugPrint('🖥️ Windows: Using REST API for registration...');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.trim(),
          'password': password,
          'displayName': name.trim(),
          'returnSecureToken': true,
        }),
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        final error = data['error'] as Map<String, dynamic>?;
        final errorMessage = error?['message'] as String? ?? 'Unknown error';
        debugPrint('🖥️ Windows REST API register error: $errorMessage');

        String message;
        switch (errorMessage) {
          case 'EMAIL_EXISTS':
            message =
                'An account already exists with this email. Please login.';
            break;
          case 'WEAK_PASSWORD : Password should be at least 6 characters':
            message = 'Password is too weak. Use at least 6 characters.';
            break;
          case 'INVALID_EMAIL':
            message = 'Invalid email format.';
            break;
          default:
            message = 'Registration failed: $errorMessage';
        }
        state = state.copyWith(isLoading: false, error: message);
        return false;
      }

      // Success — exchange idToken for customToken
      final idToken = data['idToken'] as String;
      debugPrint(
        '🖥️ Windows: REST API registration successful, exchanging token...',
      );

      try {
        final data = await CloudFunctionHelper.call('exchangeIdToken', {
          'idToken': idToken,
        });
        final customToken = data['customToken'] as String;
        await _auth.signInWithCustomToken(customToken);

        // Create Firestore doc after successful auth
        final user = _auth.currentUser;
        if (user != null) {
          await _createUserFirestoreDoc(
            uid: user.uid,
            email: email,
            name: name,
            emailVerified: emailVerified,
          );
          _authResolved = true;
          _profileLoaded = true;
          await _loadUserProfile(user);
        }

        debugPrint('✅ Windows: Registered and signed in with custom token');
        return true;
      } catch (cfError) {
        debugPrint('🖥️ Windows: Cloud Function error: $cfError');
        state = state.copyWith(
          isLoading: false,
          error: 'Account created but sign-in failed. Please try logging in.',
        );
        return false;
      }
    } catch (e) {
      debugPrint('🖥️ Windows REST API register error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. Please check your internet connection.',
      );
      return false;
    }
  }

  /// Send password reset email
  /// On Windows desktop, uses Firebase Auth REST API (platform channel is buggy)
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      state = state.copyWith(isLoading: true);

      // On Windows desktop, use REST API to bypass buggy platform channel
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        return await _sendPasswordResetWithRestApi(email.trim());
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      state = state.copyWith(isLoading: false);
      debugPrint('✅ Password reset email sent to: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = 'Failed to send reset email. Please try again later.';
      }
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      debugPrint('🔐 Password reset error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send reset email. Please try again.',
      );
      return false;
    }
  }

  /// Windows-only: Send password reset email via REST API
  Future<bool> _sendPasswordResetWithRestApi(String email) async {
    try {
      final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$apiKey',
      );

      debugPrint('🖥️ Windows: Using REST API for password reset...');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'requestType': 'PASSWORD_RESET', 'email': email}),
      );

      if (response.statusCode == 200) {
        state = state.copyWith(isLoading: false);
        debugPrint('✅ Windows: Password reset email sent to: $email');
        return true;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final error = data['error'] as Map<String, dynamic>?;
      final errorMessage = error?['message'] as String? ?? 'Unknown error';
      debugPrint('🖥️ Windows REST API reset error: $errorMessage');

      String message;
      switch (errorMessage) {
        case 'EMAIL_NOT_FOUND':
          message = 'No account found with this email.';
          break;
        case 'INVALID_EMAIL':
          message = 'Invalid email format.';
          break;
        default:
          message = 'Failed to send reset email: $errorMessage';
      }
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      debugPrint('🖥️ Windows REST API reset error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send reset email. Please check your internet.',
      );
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Capture userId before clearing state
      final userId = state.firebaseUser?.uid;

      // 1. Mark as deliberate sign-out and reset auth state
      _signOutTriggered = true;
      _profileLoaded = false;
      _authResolved = false;
      _pendingReauth = false;
      ActiveStoreManager.clear();
      state = const AuthState(isLoading: false);

      // 2. Sign out of Firebase Auth first
      try {
        await _ref.read(googleSignInProvider).signOut();
      } catch (e) {
        debugPrint('⚠️ Google sign-out failed (non-fatal): $e');
      }
      await _auth.signOut();

      // 3. Cleanup (fire-and-forget — none of these should block logout)
      if (userId != null) {
        try {
          await FCMTokenService.removeToken(
            userId,
          ).timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint('🔐 FCM cleanup skipped: $e');
        }
      }
      WindowsNotificationService.stopListening();
      try {
        await OfflineStorageService.clearUserLocalSettings();
      } catch (e) {
        debugPrint('⚠️ Sign-out: clearUserLocalSettings failed: $e');
      }
      _refreshSettingsProviders();
      // Skip clearPersistence — it fails with active listeners and
      // calling terminate() breaks Firestore for the auth state listener.
      // Firestore cache will be replaced on next login anyway.
    } catch (e) {
      debugPrint('🔐 Error signing out: $e');
      // Force reset state even if something failed
      state = const AuthState(isLoading: false);
      _refreshSettingsProviders();
    }
  }

  /// Delete account and ALL user data (DPDP Act + Google Play policy)
  ///
  /// Calls Cloud Function which recursively deletes:
  /// - All sub-collections (bills, products, customers, transactions, etc.)
  /// - Storage files (profile images, shop logos)
  /// - User document
  /// - Firebase Auth account
  ///
  /// This is IRREVERSIBLE.
  Future<bool> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      state = state.copyWith(isLoading: true);

      // Re-authenticate to verify identity (Firebase requires recent auth for account deletion)
      // The caller should ensure re-authentication before calling this.

      // Call Cloud Function to delete all data
      await CloudFunctionHelper.call('deleteUserAccount');

      // Clean up local state
      try {
        await OfflineStorageService.clearUserLocalSettings();
      } catch (e) {
        debugPrint('⚠️ Delete account: clearUserLocalSettings failed: $e');
      }

      _ref.read(themeSettingsProvider.notifier).resetToDefault();
      WindowsNotificationService.stopListening();

      // Clear auth state
      state = const AuthState(isLoading: false);

      debugPrint('✅ Account deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Account deletion failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete account: ${e.toString().split('\n').first}',
      );
      return false;
    }
  }

  /// Complete shop setup
  Future<bool> completeShopSetup({
    required String shopName,
    required String ownerName,
    String? phone,
    bool phoneVerified = false,
    String? address,
    String? gstNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final alreadyVerified = state.user?.phoneVerified ?? false;
      final effectivePhoneVerified = phoneVerified || alreadyVerified;

      final data = <String, dynamic>{
        'shopName': shopName,
        'ownerName': ownerName,
        'address': address,
        'gstNumber': gstNumber,
        'isShopSetupComplete': true,
      };
      if (phone != null && phone.isNotEmpty) {
        data['phone'] = phone;
        data['phoneVerified'] = effectivePhoneVerified;
        if (effectivePhoneVerified) {
          data['phoneVerifiedAt'] = FieldValue.serverTimestamp();
        }
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      // Sync hotel name — create the default entry if it doesn't exist yet,
      // or update it if it does. This prevents the hotel selector from creating
      // a duplicate ghost entry on next load.
      try {
        final hotelRef = _firestore
            .collection('user_hotels/${user.uid}/hotels')
            .doc(user.uid);
        final hotelDoc = await hotelRef.get();
        final slug = shopName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
        if (hotelDoc.exists) {
          await hotelRef.update({'name': shopName, 'slug': slug});
        } else {
          // Only create if user has NO hotels at all (prevent duplicate)
          final anyHotels = await _firestore
              .collection('user_hotels/${user.uid}/hotels')
              .limit(1)
              .get();
          if (anyHotels.docs.isEmpty) {
            await hotelRef.set({
              'id': user.uid,
              'name': shopName,
              'slug': slug,
              'role': 'owner',
              'status': 'active',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } catch (_) {}

      // Generate referral code for this new user (idempotent — skips if exists)
      unawaited(ReferralService.getOrCreateCode());

      state = state.copyWith(
        isShopSetupComplete: true,
        user: state.user?.copyWith(
          shopName: shopName,
          ownerName: ownerName,
          phone: phone ?? state.user?.phone,
          phoneVerified: effectivePhoneVerified,
          address: address,
          gstNumber: gstNumber,
        ),
      );

      return true;
    } catch (e) {
      debugPrint('🔐 Hotel setup error: $e');
      state = state.copyWith(
        error:
            'Failed to save restaurant details. Please check your internet and try again.',
      );
      return false;
    }
  }

  /// Update shop details
  Future<bool> updateShopDetails({
    required String shopName,
    required String ownerName,
    String? address,
    String? gstNumber,
  }) async {
    return completeShopSetup(
      shopName: shopName,
      ownerName: ownerName,
      address: address,
      gstNumber: gstNumber,
    );
  }

  /// Update shop info with optional fields (for partial updates)
  Future<bool> updateShopInfo({
    String? shopName,
    String? ownerName,
    String? phone,
    String? address,
    String? gstNumber,
    String? email,
    String? upiId,
    String? currency,
    String? timezone,
    String? receiptFooter,
    double? taxRate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Determine which store doc to update: the currently selected restaurant,
    // falling back to the owner's own doc (uid) for single-restaurant users.
    final activeStoreId = ActiveStoreManager.storeId ?? user.uid;

    try {
      final updates = <String, dynamic>{};
      if (shopName != null) updates['shopName'] = shopName;
      if (ownerName != null) updates['ownerName'] = ownerName;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      if (gstNumber != null) updates['gstNumber'] = gstNumber;
      if (email != null) updates['email'] = email;
      if (upiId != null) updates['upiId'] = upiId;
      if (currency != null) updates['currency'] = currency;
      if (timezone != null) updates['timezone'] = timezone;
      if (receiptFooter != null) {
        updates['settings.receiptFooter'] = receiptFooter;
      }
      if (taxRate != null) {
        updates['settings.taxRate'] = taxRate;
      }

      if (updates.isEmpty) return true;

      // Update the active store doc — offline-safe with 8s timeout.
      final write = _firestore.collection('users').doc(activeStoreId).update(updates);
      try {
        await write.timeout(const Duration(seconds: 8));
      } catch (_) {
        // Timeout or offline — SDK queues the write and syncs when online
      }

      // Sync restaurant name in user_hotels — fire-and-forget so it never
      // blocks the UI or hangs during offline/slow-network scenarios.
      if (shopName != null && shopName.isNotEmpty) {
        unawaited(() async {
          try {
            final hotelDoc = await _firestore
                .collection('user_hotels/${user.uid}/hotels')
                .doc(activeStoreId)
                .get()
                .timeout(const Duration(seconds: 8));
            if (hotelDoc.exists) {
              await _firestore
                  .collection('user_hotels/${user.uid}/hotels')
                  .doc(activeStoreId)
                  .update({
                'name': shopName,
                'slug': shopName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-'),
              }).timeout(const Duration(seconds: 8));
            }
          } catch (_) {}
        }());
      }

      // Update in-memory PaymentLinkService so reminders use new UPI ID immediately
      if (upiId != null && upiId.isNotEmpty) {
        PaymentLinkService.setUpiId(upiId);
      }

      // Update local state
      if (state.user != null) {
        state = state.copyWith(
          user: state.user!.copyWith(
            shopName: shopName ?? state.user!.shopName,
            ownerName: ownerName ?? state.user!.ownerName,
            phone: phone ?? state.user!.phone,
            address: address ?? state.user!.address,
            gstNumber: gstNumber ?? state.user!.gstNumber,
            email: email ?? state.user!.email,
            upiId: upiId ?? state.user!.upiId,
            currency: currency ?? state.user!.currency,
            timezone: timezone ?? state.user!.timezone,
            settings: (receiptFooter != null || taxRate != null)
                ? state.user!.settings.copyWith(
                    receiptFooter: receiptFooter,
                    taxRate: taxRate,
                  )
                : state.user!.settings,
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint('🔐 Error updating hotel info: $e');
      return false;
    }
  }

  /// Update local user settings state (for notification preferences toggle)
  void updateLocalUserSettings(UserSettings newSettings) {
    if (state.user != null) {
      state = state.copyWith(user: state.user!.copyWith(settings: newSettings));
    }
  }

  /// Toggle a notification preference and persist to Firestore (S6)
  Future<bool> toggleNotifPref(String key, bool value) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      await _firestore.collection('users').doc(uid).update({
        'settings.$key': value,
      });

      final currentUser = state.user;
      if (currentUser != null) {
        final newSettings = switch (key) {
          'lowStockAlerts' => currentUser.settings.copyWith(
            lowStockAlerts: value,
          ),
          'subscriptionAlerts' => currentUser.settings.copyWith(
            subscriptionAlerts: value,
          ),
          'dailySummary' => currentUser.settings.copyWith(dailySummary: value),
          _ => currentUser.settings,
        };
        updateLocalUserSettings(newSettings);
      }
      return true;
    } catch (e) {
      debugPrint('🔐 Error toggling notification pref $key: $e');
      return false;
    }
  }

  /// Update shop logo
  Future<bool> updateShopLogo(String logoPath) async {
    try {
      final user = state.firebaseUser;
      if (user == null) return false;

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'shopLogoPath': logoPath,
      });

      // Update local state
      if (state.user != null) {
        state = state.copyWith(
          user: state.user!.copyWith(shopLogoPath: logoPath),
        );
      }

      return true;
    } catch (e) {
      debugPrint('🔐 Error updating hotel logo: $e');
      return false;
    }
  }

  /// Update user profile image (separate from shop logo)
  Future<bool> updateProfileImage(String imagePath) async {
    try {
      final user = state.firebaseUser;
      if (user == null) return false;

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'profileImagePath': imagePath,
      });

      // Update local state
      if (state.user != null) {
        state = state.copyWith(
          user: state.user!.copyWith(profileImagePath: imagePath),
        );
      }

      return true;
    } catch (e) {
      debugPrint('🔐 Error updating profile image: $e');
      return false;
    }
  }

  /// Link a phone credential to the current email/password account
  /// This allows future phone-based login to reach the same account
  Future<bool> linkPhoneToAccount(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await user.linkWithCredential(credential);
      debugPrint('📱 Phone credential linked to account: ${user.email}');
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        debugPrint('📱 Phone already linked to another account');
      } else if (e.code == 'provider-already-linked') {
        debugPrint('📱 Phone provider already linked to this account');
      } else {
        debugPrint('📱 Failed to link phone: ${e.code} - ${e.message}');
      }
      // Non-fatal: phone is still saved in Firestore even if linking fails
      return false;
    } catch (e) {
      debugPrint('📱 Failed to link phone credential: $e');
      return false;
    }
  }

  /// Send registration OTP via Cloud Function (no auth required)
  Future<bool> sendRegistrationOTP(String email) async {
    try {
      final data = await CloudFunctionHelper.call('sendRegistrationOTP', {
        'email': email.trim().toLowerCase(),
      });

      if (data['success'] == true) {
        debugPrint('📧 Registration OTP sent to $email');
        return true;
      } else {
        final error = data['error'] as String? ?? 'Failed to send code';
        debugPrint('📧 OTP send failed: $error');
        state = state.copyWith(error: error);
        return false;
      }
    } catch (e) {
      debugPrint('📧 Failed to send registration OTP: $e');
      state = state.copyWith(
        error: 'Failed to send verification code. Please try again.',
      );
      return false;
    }
  }

  /// Verify registration OTP via Cloud Function (no auth required)
  Future<bool> verifyRegistrationOTP(String email, String otp) async {
    try {
      final data = await CloudFunctionHelper.call('verifyRegistrationOTP', {
        'email': email.trim().toLowerCase(),
        'otp': otp,
      });

      if (data['success'] == true) {
        debugPrint('✅ Registration OTP verified for $email');
        return true;
      } else {
        final error = data['error'] as String? ?? 'Invalid code';
        state = state.copyWith(error: error);
        return false;
      }
    } catch (e) {
      debugPrint('📧 OTP verification error: $e');
      state = state.copyWith(error: 'Verification failed. Please try again.');
      return false;
    }
  }

  /// Mark the user's email as verified in Firestore and local state
  Future<void> markEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'emailVerified': true,
      });

      state = state.copyWith(
        isEmailVerified: true,
        user: state.user?.copyWith(emailVerified: true),
      );
      debugPrint('✅ Email marked as verified for ${user.email}');
    } catch (e) {
      debugPrint('🔐 Error marking email verified: $e');
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith();
  }

  /// Set a custom error message
  void setError(String message) {
    state = state.copyWith(error: message);
  }

  /// Look up a user's verified phone number from Firestore by email
  /// Used for phone-based password reset
  Future<String?> getPhoneForEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .where('phoneVerified', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data()['phone'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('🔐 Error looking up phone for email: $e');
      return null;
    }
  }

  /// Update phone verified status in Firestore
  Future<bool> updatePhoneVerified({required String phone}) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'phoneVerified': true,
        'phone': phone,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
      });

      if (state.user != null) {
        state = state.copyWith(
          user: state.user!.copyWith(
            phoneVerified: true,
            phone: phone,
            phoneVerifiedAt: DateTime.now(),
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint('🔐 Error updating phone verified status: $e');
      return false;
    }
  }

  /// Check if a phone number is already used by another store/account
  /// Returns true if phone is taken by a different user
  Future<bool> isPhoneAlreadyUsed(String phone) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return false;

    try {
      // Normalize phone to E.164 format (+91XXXXXXXXXX)
      final normalizedPhone = phone.startsWith(AppConstants.countryCode)
          ? phone
          : '${AppConstants.countryCode}$phone';

      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: normalizedPhone)
          .where('phoneVerified', isEqualTo: true)
          .limit(2) // D10: Only need to know if ≥1 other user has this phone
          .get();

      // Check if any result belongs to a different user
      for (final doc in query.docs) {
        if (doc.id != currentUid) {
          debugPrint(
            '📱 Phone $normalizedPhone already used by user: ${doc.id}',
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('🔐 Error checking phone uniqueness: $e');
      // Fail open — allow user to proceed on error; linkWithCredential
      // will catch actual duplicates server-side (credential-already-in-use)
      return false;
    }
  }

  /// Change password (requires re-authentication)
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('User not logged in');
    }

    // Re-authenticate with current password
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Current password is incorrect');
      }
      debugPrint('🔐 Change password error: ${e.code} - ${e.message}');
      throw Exception('Failed to change password. Please try again.');
    }
  }

  // ── Account Linking ─────────────────────────────────────────────────────

  /// Complete account linking: user enters their email/password,
  /// then the pending Google credential is linked to that account.
  Future<bool> completeLinkWithPassword(String password) async {
    final pendingCredential = _pendingGoogleCredential;
    final email = state.pendingLinkEmail;
    if (pendingCredential == null || email == null) return false;

    try {
      state = state.copyWith(isLoading: true);

      // Sign in with existing email+password account
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Sign-in failed. Please try again.',
        );
        return false;
      }

      // Link the Google credential to this account
      await user.linkWithCredential(pendingCredential);
      debugPrint('✅ Google account linked to email/password account');

      // Clear pending state
      _pendingGoogleCredential = null;
      state = state.copyWith(pendingAccountLink: false, pendingLinkEmail: null);

      // Update Firestore doc (mark emailVerified, add photoUrl if available)
      await _ensureFirestoreDoc(user);

      // Let authStateChanges pick up the signed-in user
      _pendingReauth = true;
      _profileLoaded = false;
      _authResolved = false;
      await _loadUserProfile(user);
      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Wrong password. Please try again.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try later.';
          break;
        case 'provider-already-linked':
          // Already linked — just sign in normally
          _pendingGoogleCredential = null;
          state = state.copyWith(
            pendingAccountLink: false,
            pendingLinkEmail: null,
          );
          _pendingReauth = true;
          _profileLoaded = false;
          _authResolved = false;
          await _loadUserProfile(_auth.currentUser!);
          return true;
        default:
          message = 'Linking failed. Please try again.';
      }
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      debugPrint('🔐 completeLinkWithPassword error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Linking failed. Please try again.',
      );
      return false;
    }
  }

  /// Cancel the pending account link dialog
  void cancelPendingLink() {
    _pendingGoogleCredential = null;
    state = state.copyWith(pendingAccountLink: false, pendingLinkEmail: null);
  }

  /// Start demo mode (keeps local data for demo)
  Future<void> startDemoMode() async {
    // Load demo data BEFORE setting state
    DemoDataService.loadDemoData();

    state = AuthState(
      status: AuthStatus.authenticated,
      isLoggedIn: true,
      isShopSetupComplete: true,
      isEmailVerified: true,
      isDemoMode: true,
      isLoading: false,
      user: UserModel(
        id: 'demo_user',
        shopName: 'Demo Restaurant',
        ownerName: 'Demo Owner',
        email: 'demo@tulasihotels.com',
        phone: '9876543210',
        settings: const UserSettings(),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Exit demo mode
  Future<void> exitDemoMode() async {
    // Clear demo data
    DemoDataService.clearDemoData();
    state = const AuthState(isLoading: false);
  }
}

/// Auth provider (Firebase mode)
final authNotifierProvider =
    StateNotifierProvider<FirebaseAuthNotifier, AuthState>(
      (ref) => FirebaseAuthNotifier(ref),
    );

/// Current user provider
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authNotifierProvider).user;
});

/// Is logged in provider
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isLoggedIn;
});

/// Is shop setup complete provider
final isShopSetupCompleteProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isShopSetupComplete;
});

/// Auth error provider
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).error;
});

/// Is demo mode provider
final isDemoModeProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isDemoMode;
});
