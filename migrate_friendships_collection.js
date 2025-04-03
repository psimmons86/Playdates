const admin = require('firebase-admin');

// --- Configuration ---
// Uses the same service account key file as before
const serviceAccount = require('./serviceAccountKey.json');
// ---------------------

console.log("Initializing Firebase Admin SDK...");
try {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log("Firebase Admin SDK Initialized Successfully.");
} catch (error) {
    // Handle cases where it might already be initialized if run in the same process
    if (error.code !== 'app/duplicate-app') {
        console.error("Error initializing Firebase Admin SDK:", error);
        console.error("Please ensure 'serviceAccountKey.json' is in the correct directory and is valid.");
        process.exit(1);
    } else {
        console.log("Firebase Admin SDK already initialized.");
    }
}

const db = admin.firestore();
const friendshipsRef = db.collection('friendships');
const usersRef = db.collection('users');

async function migrateFriendshipsCollection() {
    console.log("Starting migration from 'friendships' collection to 'users/{userID}/friends' subcollections...");
    let processedFriendships = 0;
    let successfulMigrations = 0;
    let errorsEncountered = 0;

    try {
        const snapshot = await friendshipsRef.get();
        if (snapshot.empty) {
            console.log("No documents found in the 'friendships' collection. Nothing to migrate.");
            return;
        }

        console.log(`Found ${snapshot.size} documents in 'friendships'. Processing migration...`);

        const migrationPromises = snapshot.docs.map(async (friendshipDoc) => {
            const friendshipId = friendshipDoc.id;
            const friendshipData = friendshipDoc.data();
            const participants = friendshipData.participants;

            if (!Array.isArray(participants) || participants.length !== 2) {
                console.warn(`Friendship Doc ${friendshipId}: Invalid or missing 'participants' array. Skipping.`);
                return;
            }

            const userA_ID = participants[0];
            const userB_ID = participants[1];

            if (!userA_ID || !userB_ID) {
                 console.warn(`Friendship Doc ${friendshipId}: One or both participant IDs are invalid. Skipping.`);
                 return;
            }

            console.log(`Friendship Doc ${friendshipId}: Migrating friendship between ${userA_ID} and ${userB_ID}.`);

            const friendSince = friendshipData.createdAt instanceof admin.firestore.Timestamp
                ? friendshipData.createdAt
                : admin.firestore.Timestamp.now(); // Use original creation time if available

            // Create batch write for this friendship
            const batch = db.batch();

            // Add userB to userA's friends subcollection
            const userAFriendRef = usersRef.doc(userA_ID).collection('friends').doc(userB_ID);
            batch.set(userAFriendRef, { friendSince: friendSince });

            // Add userA to userB's friends subcollection
            const userBFriendRef = usersRef.doc(userB_ID).collection('friends').doc(userA_ID);
            batch.set(userBFriendRef, { friendSince: friendSince });

            try {
                await batch.commit();
                console.log(`Friendship Doc ${friendshipId}: Successfully created subcollection entries for ${userA_ID} <-> ${userB_ID}.`);
                successfulMigrations++;

                // Optional: Delete the old friendship document after successful migration
                // try {
                //     await friendshipsRef.doc(friendshipId).delete();
                //     console.log(`Friendship Doc ${friendshipId}: Successfully deleted old document.`);
                // } catch (deleteError) {
                //     console.error(`Friendship Doc ${friendshipId}: Failed to delete old document:`, deleteError);
                // }

            } catch (batchError) {
                console.error(`Friendship Doc ${friendshipId}: Error committing batch write for ${userA_ID} <-> ${userB_ID}:`, batchError);
                errorsEncountered++;
            }
            processedFriendships++;
        });

        await Promise.all(migrationPromises);

        console.log("\n--- Migration Summary ---");
        console.log(`Processed ${processedFriendships} documents from 'friendships' collection.`);
        console.log(`Successfully created subcollection entries for ${successfulMigrations} friendships.`);
        if (errorsEncountered > 0) {
            console.warn(`Encountered errors during migration for ${errorsEncountered} friendships. Check logs above.`);
        }
        console.log("------------------------");
        console.log("'friendships' collection migration completed.");

    } catch (error) {
        console.error("Error fetching 'friendships' collection:", error);
        console.log("Migration failed.");
    }
}

migrateFriendshipsCollection().then(() => {
    console.log("Script finished.");
}).catch((error) => {
    console.error("Unhandled error during migration:", error);
});
