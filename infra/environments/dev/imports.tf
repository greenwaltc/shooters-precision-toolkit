# Adopt the existing dev Firebase resources.
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
  to = module.firebase.google_firebase_android_app.dev[0]
  id = "projects/bramwellsprecisiontestkitdev/androidApps/1:723783645502:android:cd195adeff518d046c146f"
}

import {
  to = module.firebase.google_firebase_apple_app.apple["com.bramwell.bramwellsPrecisionTestKit"]
  id = "projects/bramwellsprecisiontestkitdev/iosApps/1:723783645502:ios:d1e41e502b0a1d4c6c146f"
}

import {
  to = module.firebase.google_firebase_apple_app.apple["com.bramwell.bramwellsPrecisionTestKit.dev"]
  id = "projects/bramwellsprecisiontestkitdev/iosApps/1:723783645502:ios:3be1097bbdd9289b6c146f"
}

import {
  to = module.firebase.google_firebase_hosting_site.web
  id = "projects/bramwellsprecisiontestkitdev/sites/bramwellsprecisiontestkitdev"
}

import {
  to = module.firebase.google_firestore_database.projects
  id = "projects/bramwellsprecisiontestkitdev/databases/(default)"
}

import {
  to = module.firebase.google_firestore_field.unqueried_payload["formModel"]
  id = "projects/bramwellsprecisiontestkitdev/databases/(default)/collectionGroups/projects/fields/formModel"
}

import {
  to = module.firebase.google_firestore_field.unqueried_payload["matrixState"]
  id = "projects/bramwellsprecisiontestkitdev/databases/(default)/collectionGroups/projects/fields/matrixState"
}

import {
  to = module.firebase.google_firestore_field.unqueried_payload["randomizeSequence"]
  id = "projects/bramwellsprecisiontestkitdev/databases/(default)/collectionGroups/projects/fields/randomizeSequence"
}

import {
  to = module.firebase.google_firebaserules_release.firestore
  id = "projects/bramwellsprecisiontestkitdev/releases/cloud.firestore"
}
