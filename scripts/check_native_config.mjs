import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';

for (const environment of ['dev', 'prod']) {
  const expectedProject = environment === 'dev' ? 'bramwellsprecisiontestkitdev' : 'bramwells-precision-test-kit';
  const suffix = environment === 'dev' ? '.dev' : '';
  const android = JSON.parse(readFileSync(`android/app/src/${environment}/google-services.json`, 'utf8'));
  assert.equal(android.project_info.project_id, expectedProject);
  assert(android.client.some((client) => client.client_info.android_client_info.package_name === `com.bramwell.bramwells_precision_test_kit${suffix}`));
  for (const platform of ['ios', 'macos']) {
    const file = `${platform}/Firebase/${environment}/GoogleService-Info.plist`;
    const apple = JSON.parse(execFileSync('plutil', ['-convert', 'json', '-o', '-', file], { encoding: 'utf8' }));
    assert.equal(apple.PROJECT_ID, expectedProject);
    assert.equal(apple.BUNDLE_ID, `com.bramwell.bramwellsPrecisionTestKit${suffix}`);
    const project = JSON.parse(execFileSync('plutil', ['-convert', 'json', '-o', '-', `${platform}/Runner.xcodeproj/project.pbxproj`], { encoding: 'utf8' }));
    const objects = project.objects;
    const runner = Object.values(objects).find((object) => object.isa === 'PBXNativeTarget' && object.name === 'Runner');
    const configs = objects[runner.buildConfigurationList].buildConfigurations.map((id) => objects[id]);
    for (const mode of ['Debug', 'Profile', 'Release']) {
      const config = configs.find((entry) => entry.name === `${mode}-${environment}`);
      assert(config, `Missing ${platform} ${mode}-${environment}`);
      assert.equal(config.buildSettings.PRODUCT_BUNDLE_IDENTIFIER, apple.BUNDLE_ID);
      assert.equal(config.buildSettings.FIREBASE_ENV, environment);
      assert(String(config.buildSettings.OTHER_LDFLAGS).includes('-ObjC'), `Missing Firebase linker flag in ${platform} ${config.name}`);
    }
    assert.equal(runner.buildPhases.filter((id) => objects[id].name === 'Select Firebase environment').length, 1);
    const scheme = readFileSync(`${platform}/Runner.xcodeproj/xcshareddata/xcschemes/${environment}.xcscheme`, 'utf8');
    for (const mode of ['Debug', 'Profile', 'Release']) assert(scheme.includes(`buildConfiguration="${mode}-${environment}"`));
    const destination = `/private/tmp/precision-native-check-${platform}-${environment}`;
    execFileSync('sh', ['scripts/select_firebase_apple.sh'], {
      env: { ...process.env, FIREBASE_ENV: environment, SRCROOT: `${process.cwd()}/${platform}`,
        PRODUCT_BUNDLE_IDENTIFIER: apple.BUNDLE_ID, TARGET_BUILD_DIR: destination,
        UNLOCALIZED_RESOURCES_FOLDER_PATH: 'App.app/Resources' },
    });
    assert.equal(readFileSync(`${destination}/App.app/Resources/GoogleService-Info.plist`, 'utf8'), readFileSync(file, 'utf8'));
  }
  console.log(`Native ${environment} config and Apple plist selection passed.`);
}
for (const file of ['android/app/google-services.json', 'ios/Runner/GoogleService-Info.plist', 'macos/Runner/GoogleService-Info.plist']) {
  assert(!existsSync(file), `Ambiguous default Firebase config remains: ${file}`);
}

// A mismatched bundle must fail before a plist can be bundled.
assert.throws(() => execFileSync('sh', ['scripts/select_firebase_apple.sh'], {
  stdio: 'pipe', env: { ...process.env, FIREBASE_ENV: 'prod', SRCROOT: `${process.cwd()}/ios`,
    PRODUCT_BUNDLE_IDENTIFIER: 'com.bramwell.bramwellsPrecisionTestKit.dev',
    TARGET_BUILD_DIR: '/private/tmp/precision-native-negative', UNLOCALIZED_RESOURCES_FOLDER_PATH: 'App.app' },
}));
console.log('Mismatched Apple environment correctly rejected.');
