const admin = require('firebase-admin');

// --- Configuration ---
// IMPORTANT: Place your downloaded service account key file in the same directory
//            and rename it to 'serviceAccountKey.json'
const serviceAccount = require('./serviceAccountKey.json');
// ---------------------

console.log("Initializing Firebase Admin SDK...");
try {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log("Firebase Admin SDK Initialized Successfully.");
} catch (error) {
    console.error("Error initializing Firebase Admin SDK:", error);
    console.error("Please ensure 'serviceAccountKey.json' is in the correct directory and is valid.");
    process.exit(1);
}


const db = admin.firestore();
const usersRef = db.collection('users');

async function migrateFriends() {
    console.log("Starting friend data migration...");
    let migratedUsersCount = 0;
    let totalFriendsMigrated = 0;
    let usersWithErrors = 0;

    try {
        const snapshot = await usersRef.get();
        if (snapshot.empty) {
            console.log("No users found in the 'users' collection. Nothing to migrate.");
            return;
        }

        console.log(`Found ${snapshot.size} users. Processing migration...`);

        const migrationPromises = snapshot.docs.map(async (userDoc) => {
            const userId = userDoc.id;
            const userData = userDoc.data();
            const oldFriendIDs = userData.friendIDs; // Get the old array

            if (!Array.isArray(oldFriendIDs) || oldFriendIDs.length === 0) {
                // console.log(`User ${userId}: No old friendIDs array found or empty. Skipping.`);
                return; // Skip users with no old friend IDs
            }

            console.log(`User ${userId}: Found ${oldFriendIDs.length} friend IDs in old array. Migrating...`);
            const friendsSubcollectionRef = usersRef.doc(userId).collection('friends');
            let friendsMigratedForUser = 0;

            // Use batch writes for efficiency and atomicity per user
            const batch = db.batch();
            const friendSince = admin.firestore.Timestamp.now(); // Use a consistent timestamp

            for (const friendId of oldFriendIDs) {
                if (userId === friendId) {
                    console.warn(`User ${userId}: Skipping self-reference in friendIDs array.`);
                    continue;
                }
                // Create a document in the 'friends' subcollection with the friend's ID
                const friendDocRef = friendsSubcollectionRef.doc(friendId);
                // Add some basic data, like when the friendship was migrated/established
                batch.set(friendDocRef, { friendSince: friendSince });
                friendsMigratedForUser++;
            }

            try {
                await batch.commit();
                console.log(`User ${userId}: Successfully migrated ${friendsMigratedForUser} friends to subcollection.`);
                migratedUsersCount++;
                totalFriendsMigrated += friendsMigratedForUser;
            } catch (batchError) {
                console.error(`User ${userId}: Error committing batch write for friends:`, batchError);
                usersWithErrors++;
            }

            // Optional: Consider removing the old 'friendIDs' field after successful migration
            // try {
            //     await usersRef.doc(userId).update({
            //         friendIDs: admin.firestore.FieldValue.delete()
            //     });
            //     console.log(`User ${userId}: Successfully removed old friendIDs field.`);
            // } catch (updateError) {
            //     console.error(`User ${userId}: Failed to remove old friendIDs field:`, updateError);
            // }
        });

        await Promise.all(migrationPromises);

        console.log("\n--- Migration Summary ---");
        console.log(`Processed ${snapshot.size} total users.`);
        console.log(`Successfully migrated data for ${migratedUsersCount} users.`);
        console.log(`Total friend relationships migrated: ${totalFriendsMigrated}.`);
        if (usersWithErrors > 0) {
            console.warn(`Encountered errors for ${usersWithErrors} users. Check logs above.`);
        }
        console.log("------------------------");
        console.log("Friend data migration completed.");

    } catch (error) {
        console.error("Error fetching users collection:", error);
        console.log("Migration failed.");
    }
}

migrateFriends().then(() => {
    console.log("Script finished.");
}).catch((error) => {
    console.error("Unhandled error during migration:", error);
});
