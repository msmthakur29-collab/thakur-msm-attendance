# THAKUR MSM Attendance V6

Firebase-connected Flutter starter for the THAKUR MSM attendance app.

## Included
- Firebase initialization using android/app/google-services.json
- Email/password login
- Role-based Admin vs Employee routing using `users/{uid}.role`
- Employee check-in/check-out writes to `attendance`
- Admin live attendance list

## Important
This is source code, not a compiled APK. Run `flutter create .` once to generate the standard Android/iOS folders if needed, then `flutter pub get` and `flutter run`.

Create the Firebase Android app with package `com.thakurmsm.attendance`.
Do not put passwords or service-account private keys in the app.
