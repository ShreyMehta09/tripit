import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  GoogleSignIn _getGoogleSignIn() {
    _googleSignIn ??= GoogleSignIn(
      scopes: ['email'],
    );
    return _googleSignIn!;
  }

  bool get _isDesktopPlatform {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await result.user?.updateDisplayName(displayName);
      await result.user?.reload();
      _user = _auth.currentUser;

      // Send email verification to newly created user
      try {
        await _user?.sendEmailVerification();
      } catch (_) {}

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // After sign in, refresh user and ensure email verification is considered by caller
      await _auth.currentUser?.reload();
      _user = _auth.currentUser;

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      if (kIsWeb) {
        await _auth.signInWithPopup(GoogleAuthProvider());
        return true;
      }

      if (_isDesktopPlatform) {
        _setError(
          'Google sign-in is not configured for desktop in this build. Use the web app or add a desktop OAuth client.',
        );
        return false;
      }

      // Reset any stale cached Google session before starting a fresh interactive flow.
      await _getGoogleSignIn().signOut();

      GoogleSignInAccount? googleUser;
      try {
        // Trigger the authentication flow
        googleUser = await _getGoogleSignIn().signIn();
      } on PlatformException catch (e) {
        final details = '${e.code} ${e.message} ${e.details}';
        if (details.contains('sign_in_failed') &&
            (details.contains('ApiException: 10') || details.contains('10'))) {
          _setError(
            'Google Sign-In is not configured correctly for Android (Error 10). Add your app SHA-1/SHA-256 in Firebase, download new google-services.json, then rebuild.',
          );
          return false;
        }
        rethrow;
      }

      if (googleUser == null) {
        // Retry once in case the previous cached state interrupted the first attempt.
        googleUser = await _getGoogleSignIn().signIn();
      }

      if (googleUser == null) {
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        _setError(
          'Google Sign-In did not return an ID token. Please check Firebase Android OAuth configuration.',
        );
        return false;
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      await _auth.signInWithCredential(credential);

      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? _getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Failed to sign in with Google: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in with Google
      if (_googleSignIn != null && await _googleSignIn!.isSignedIn()) {
        await _googleSignIn!.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      _setError('Failed to sign out. Please try again.');
    }
  }

  // Send verification email to current user
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      // ignore
    }
  }

  // Check whether current user's email is verified (reloads current user)
  Future<bool> isEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
      final u = _auth.currentUser;
      _user = u;
      return u?.emailVerified ?? false;
    } catch (e) {
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      await _auth.sendPasswordResetEmail(email: email.trim());

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'popup-closed-by-user':
        return 'Sign-in popup was closed before completing.';
      case 'popup-blocked':
        return 'The Google sign-in popup was blocked by the browser.';
      case 'network-request-failed':
        return 'A network error occurred during sign-in. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
