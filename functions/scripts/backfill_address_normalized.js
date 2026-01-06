const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const { FieldPath } = admin.firestore;

function normalizeAddress(address) {
  if (!address) return '';
  return address
    .trim()
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

async function run() {
  let scanned = 0;
  let updated = 0;
  let lastDoc = null;
  const pageSize = 500;

  while (true) {
    let query = db
      .collection('users')
      .where('userType', '==', 'employee')
      .orderBy(FieldPath.documentId())
      .limit(pageSize);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();
    if (snapshot.empty) break;

    let batch = db.batch();
    let batchCount = 0;

    for (const doc of snapshot.docs) {
      scanned += 1;
      const data = doc.data() || {};
      const normalized = normalizeAddress(data.address || '');
      if (!normalized) continue;

      if (data.addressNormalized !== normalized) {
        batch.update(doc.ref, { addressNormalized: normalized });
        batchCount += 1;
      }

      if (batchCount >= 400) {
        await batch.commit();
        updated += batchCount;
        batch = db.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
      updated += batchCount;
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1];
  }

  console.log(`Scanned: ${scanned}, Updated: ${updated}`);
}

run()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Backfill failed:', error);
    process.exit(1);
  });
