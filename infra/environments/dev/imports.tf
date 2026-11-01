# Adopt existing registrations recorded in firebase.json on October 29, 2026.
# Import blocks are evaluated by plan/apply, not by init or validate.
import {
  to = module.firebase.google_firebase_project.this
  id = "projects/bramwellsprecisiontestkitdev"
}

import {
  to = module.firebase.google_firebase_web_app.web
  id = "projects/bramwellsprecisiontestkitdev/webApps/1:723783645502:web:0afce571413c389a6c146f"
}

import {
  to = module.firebase.google_firebase_android_app.android
  id = "projects/bramwellsprecisiontestkitdev/androidApps/1:723783645502:android:46f1aaa714fe25fc6c146f"
}

import {
  to = module.firebase.google_firebase_apple_app.apple["com.bramwell.bramwellsPrecisionTestKit"]
  id = "projects/bramwellsprecisiontestkitdev/iosApps/1:723783645502:ios:d1e41e502b0a1d4c6c146f"
}
