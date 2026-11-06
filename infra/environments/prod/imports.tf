# Adopt the production resources already used by the shipped app.
import {
  to = module.firebase.google_firebase_project.this
  id = "projects/bramwells-precision-test-kit"
}

import {
  to = module.firebase.google_firebase_hosting_site.web
  id = "projects/bramwells-precision-test-kit/sites/bramwells-precision-test-kit"
}

import {
  to = module.firebase.google_firebase_web_app.web
  id = "projects/bramwells-precision-test-kit/webApps/1:653363090089:web:060e48e9dc6b13acde0fb8"
}

import {
  to = module.firebase.google_firebase_android_app.android
  id = "projects/bramwells-precision-test-kit/androidApps/1:653363090089:android:231c811e0f166474de0fb8"
}

import {
  to = module.firebase.google_firebase_apple_app.apple["com.bramwell.bramwellsPrecisionTestKit"]
  id = "projects/bramwells-precision-test-kit/iosApps/1:653363090089:ios:eab2a50b414ebca9de0fb8"
}

import {
  to = module.firebase.google_firestore_database.projects
  id = "projects/bramwells-precision-test-kit/databases/(default)"
}

import {
  to = module.firebase.google_firebaserules_release.firestore
  id = "projects/bramwells-precision-test-kit/releases/cloud.firestore"
}
