import { before, beforeEach, after, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';

import {
  collection,
  deleteField,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

const projectId = process.env.PRECISION_RULES_TEST_PROJECT;
const port = Number(process.env.PRECISION_RULES_TEST_PORT);
let environment;

// This suite must run through the local emulator command.
before(async () => {
  assert.match(projectId ?? '', /^demo-precision-rules-[a-z0-9]+$/, 'Use the isolated rules-test runner.');
  assert(Number.isInteger(port) && port > 1024 && port <= 65535);
  assert.equal(
    process.env.FIRESTORE_EMULATOR_HOST,
    `127.0.0.1:${port}`,
    'Run this suite through task rules:test.',
  );

  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port,
      rules: await readFile(
        new URL('../firestore.rules', import.meta.url),
        'utf8',
      ),
    },
  });
});

beforeEach(async () => {
  await environment.clearFirestore();
});

after(async () => {
  await environment?.cleanup();
});

function userDb(uid, verified = true) {
  return environment.authenticatedContext(uid, {
    email: `${uid}@example.test`,
    email_verified: verified,
    auth_time: Math.floor(Date.now() / 1000),
  }).firestore();
}

function projectRef(db, uid = 'alice', id = 'experiment-1') {
  return doc(db, 'users', uid, 'projects', id);
}

function validProject() {
  return {
    schemaVersion: 1,
    revision: 1,
    createdAt: Timestamp.fromMillis(1700000000000),
    updatedAt: serverTimestamp(),
    setupComplete: false,
    randomizeOrder: false,
    randomizeSequence: null,
    formModel: {
      projectTitle: 'Rules test',
      experimentStructure: 'simpleABComparison',
      riskLevel: 'tenPercent',
      sampleSizeOption: {
        numFactors: 1,
        numSets: 4,
        setSize: 2,
        family: 'simpleComparison',
      },
      factorDefinitions: Array.from({ length: 4 }, () => ({
        name: '',
        firstState: '',
        secondState: '',
      })),
      imputeMissingData: false,
    },
    matrixState: {},
  };
}

test('verified owner can create, read, update, and delete', async () => {
  const db = userDb('alice');
  const ref = projectRef(db);

  await assertSucceeds(setDoc(ref, validProject()));
  await assertSucceeds(getDoc(ref));

  await assertSucceeds(updateDoc(ref, {
    'formModel.projectTitle': 'Updated project',
    revision: 2,
    updatedAt: serverTimestamp(),
  }));

  const saved = await getDoc(ref);
  assert.equal(saved.data().revision, 2);

  await assertSucceeds(deleteDoc(ref));
});

test('signed-out users cannot read or create projects', async () => {
  await setDoc(projectRef(userDb('alice')), validProject());

  const db = environment.unauthenticatedContext().firestore();

  await assertFails(getDoc(projectRef(db)));
  await assertFails(
    setDoc(projectRef(db, 'alice', 'another-project'), validProject()),
  );
});

test('unverified users cannot access their own projects', async () => {
  await setDoc(projectRef(userDb('alice')), validProject());

  const db = userDb('alice', false);

  await assertFails(getDoc(projectRef(db)));
  await assertFails(
    setDoc(projectRef(db, 'alice', 'another-project'), validProject()),
  );
});

test('Bob cannot access Alice’s projects', async () => {
  await setDoc(projectRef(userDb('alice')), validProject());

  const db = userDb('bob');
  const aliceProject = projectRef(db);

  await assertFails(getDoc(aliceProject));
  await assertFails(updateDoc(aliceProject, {
    revision: 2,
    updatedAt: serverTimestamp(),
  }));
  await assertFails(deleteDoc(aliceProject));
  await assertFails(
    setDoc(projectRef(db, 'alice', 'another-project'), validProject()),
  );
});

test('creation rejects invalid fields and values', async () => {
  const db = userDb('alice');

  const extraField = validProject();
  extraField.isAdmin = true;

  const missingField = validProject();
  delete missingField.matrixState;

  const wrongType = validProject();
  wrongType.setupComplete = 'yes';

  const longTitle = validProject();
  longTitle.formModel.projectTitle = 'x'.repeat(201);

  const wrongRevision = validProject();
  wrongRevision.revision = 2;

  for (const [index, value] of [
    extraField,
    missingField,
    wrongType,
    longTitle,
    wrongRevision,
  ].entries()) {
    await assertFails(
      setDoc(projectRef(db, 'alice', `invalid-${index}`), value),
    );
  }
});

test('updates cannot bypass validation or revision checks', async () => {
  const db = userDb('alice');
  const ref = projectRef(db);
  await setDoc(ref, validProject());

  const invalidChanges = [
    { revision: 1 },
    { revision: 3 },
    { createdAt: Timestamp.fromMillis(1800000000000) },
    { setupComplete: 'yes' },
    { matrixState: 'not a map' },
    { randomizeSequence: Array(4097).fill(0) },
    { unexpectedField: true },
  ];

  for (const change of invalidChanges) {
    await assertFails(updateDoc(ref, {
      revision: 2,
      updatedAt: serverTimestamp(),
      ...change,
    }));
  }

  // A client-provided timestamp must not replace the server timestamp.
  await assertFails(updateDoc(ref, {
    revision: 2,
    updatedAt: Timestamp.fromMillis(1700000000000),
  }));
});

test('project list queries require a limit of at most 25', async () => {
  const db = userDb('alice');
  await setDoc(projectRef(db), validProject());

  const projects = collection(db, 'users', 'alice', 'projects');

  await assertSucceeds(getDocs(query(
    projects,
    orderBy('updatedAt', 'desc'),
    limit(25),
  )));

  await assertFails(getDocs(query(
    projects,
    orderBy('updatedAt', 'desc'),
  )));

  await assertFails(getDocs(query(
    projects,
    orderBy('updatedAt', 'desc'),
    limit(26),
  )));
});

test('an editing claim changes only the editor and revision', async () => {
  const owner = projectRef(userDb('alice'));
  const firstSession = 'a'.repeat(20);
  const secondSession = 'b'.repeat(20);
  await assertFails(setDoc(owner, { ...validProject(), editorSession: firstSession }));
  await setDoc(owner, validProject());
  const original = (await getDoc(owner)).data();

  const claim = { revision: 2, editorSession: firstSession };
  await assertFails(updateDoc(projectRef(userDb('bob')), claim));
  await assertFails(updateDoc(projectRef(userDb('alice', false)), claim));
  await assertFails(updateDoc(projectRef(environment.unauthenticatedContext().firestore()), claim));
  for (const editorSession of [1, null, '', 'a'.repeat(1000), '../other/workspace']) {
    await assertFails(updateDoc(owner, { ...claim, editorSession }));
  }
  await assertFails(updateDoc(owner, { ...claim, revision: 3 }));
  await assertFails(updateDoc(owner, { ...claim, matrixState: { range_0: '5' } }));
  await assertFails(updateDoc(owner, { ...claim, createdAt: serverTimestamp() }));
  await assertFails(updateDoc(owner, { ...claim, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(owner, { ...claim, ownerId: 'bob' }));
  await assertSucceeds(updateDoc(owner, claim));
  assert.deepEqual((await getDoc(owner)).data(), { ...original, ...claim });

  await assertFails(updateDoc(owner, { revision: 3, editorSession: deleteField() }));
  await assertFails(setDoc(owner, { ...validProject(), revision: 3 }));
  await assertSucceeds(updateDoc(owner, { revision: 3, editorSession: secondSession }));
  await assertSucceeds(updateDoc(owner, {
    revision: 4,
    matrixState: { range_0: '5' },
    updatedAt: serverTimestamp(),
  }));
});

test('import receipts are immutable', async () => {
  const db = userDb('alice');
  const migrationKey = 'a'.repeat(64);
  const targetId = `legacy_${migrationKey}`;

  const target = projectRef(db, 'alice', targetId);
  const receipt = doc(
    db, 'users', 'alice', 'imports', migrationKey,
  );

  const batch = writeBatch(db);
  batch.set(target, validProject());
  batch.set(receipt, {
    schemaVersion: 1,
    projectId: targetId,
    completedAt: serverTimestamp(),
  });

  await assertSucceeds(batch.commit());
  await assertSucceeds(getDoc(receipt));

  await assertFails(updateDoc(receipt, {
    projectId: 'something-else',
  }));
  await assertFails(deleteDoc(receipt));
});

test('a deletion request blocks new project writes', async () => {
  const db = userDb('alice');
  const existing = projectRef(db);
  await setDoc(existing, validProject());

  const request = doc(db, 'accountDeletionRequests', 'alice');

  await assertSucceeds(setDoc(request, {
    schemaVersion: 1,
    status: 'pending',
    requestedAt: serverTimestamp(),
  }));

  await assertFails(
    setDoc(projectRef(db, 'alice', 'new-project'), validProject()),
  );

  await assertFails(updateDoc(existing, {
    revision: 2,
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(existing, { revision: 2, editorSession: 'a'.repeat(20) }));

  await assertFails(deleteDoc(request));
  await assertFails(updateDoc(request, { status: 'completed' }));

  // The current policy intentionally still permits owner reads/deletes.
  await assertSucceeds(getDoc(existing));
  await assertSucceeds(deleteDoc(existing));
});

test('unrelated paths remain inaccessible', async () => {
  const db = userDb('alice');
  await assertFails(setDoc(doc(db, 'unrelated', 'document'), {
    value: 'not allowed',
  }));
});

test('ownership is enforced on list queries, not only individual documents', async () => {
  await setDoc(projectRef(userDb('alice')), validProject());
  for (const db of [userDb('bob'), userDb('alice', false), environment.unauthenticatedContext().firestore()]) {
    await assertFails(getDocs(query(collection(db, 'users', 'alice', 'projects'), limit(25))));
  }
});

test('unverified owners cannot update or delete existing projects', async () => {
  await setDoc(projectRef(userDb('alice')), validProject());
  const ref = projectRef(userDb('alice', false));
  await assertFails(updateDoc(ref, { revision: 2, updatedAt: serverTimestamp() }));
  await assertFails(deleteDoc(ref));
});

test('updates cannot remove required fields or corrupt nested form data', async () => {
  const db = userDb('alice');
  const ref = projectRef(db);
  await setDoc(ref, validProject());
  const missing = validProject();
  missing.revision = 2;
  delete missing.formModel;
  await assertFails(setDoc(ref, missing));
  await assertFails(updateDoc(ref, {
    'formModel.factorDefinitions': ['not a factor'], revision: 2, updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(ref, {
    matrixState: Object.fromEntries(Array.from({ length: 4097 }, (_, i) => [`cell-${i}`, '1'])),
    revision: 2, updatedAt: serverTimestamp(),
  }));
});

test('deletion requests require the owner and recent authentication', async () => {
  const oldSession = environment.authenticatedContext('alice', {
    email_verified: true, auth_time: Math.floor(Date.now() / 1000) - 600,
  }).firestore();
  const request = { schemaVersion: 1, status: 'pending', requestedAt: serverTimestamp() };
  await assertFails(setDoc(doc(oldSession, 'accountDeletionRequests', 'alice'), request));
  await assertFails(setDoc(doc(userDb('bob'), 'accountDeletionRequests', 'alice'), request));
});
