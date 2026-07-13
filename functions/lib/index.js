"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateQuestWithAI = exports.resetDailyCounters = exports.checkAchievements = exports.completeQuest = exports.addUserExp = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
// ========== EXP LEVELING SYSTEM ==========
// EXP needed for each level (exponential growth)
function getExpForLevel(level) {
    if (level <= 1)
        return 0;
    // Formula: 100 * level^1.5 (adjust as needed)
    return Math.floor(100 * Math.pow(level, 1.5));
}
// Get total EXP needed from level 1 to target level
function getTotalExpForLevel(targetLevel) {
    let total = 0;
    for (let i = 2; i <= targetLevel; i++) {
        total += getExpForLevel(i);
    }
    return total;
}
// Calculate level from total EXP
function calculateLevel(totalExp) {
    let level = 1;
    while (true) {
        const expNeeded = getExpForLevel(level + 1);
        if (totalExp < expNeeded)
            break;
        totalExp -= expNeeded;
        level++;
    }
    return {
        level,
        currentExp: totalExp,
        expToNextLevel: getExpForLevel(level + 1)
    };
}
// Get rank based on level
function getRank(level) {
    const ranks = [
        { minLevel: 1, id: 'Pemula', en: 'Beginner' },
        { minLevel: 5, id: 'Pelajar', en: 'Student' },
        { minLevel: 10, id: 'Atlet', en: 'Athlete' },
        { minLevel: 20, id: 'Petarung', en: 'Fighter' },
        { minLevel: 35, id: 'Juara', en: 'Champion' },
        { minLevel: 50, id: 'Legenda', en: 'Legend' },
        { minLevel: 75, id: 'Dewa', en: 'God' },
        { minLevel: 100, id: 'Titan', en: 'Titan' },
    ];
    let rank = ranks[0];
    for (const r of ranks) {
        if (level >= r.minLevel)
            rank = r;
        else
            break;
    }
    return rank.id; // Default to Indonesian names
}
// ========== CLOUD FUNCTIONS ==========
/**
 * Add EXP to user - Centralized EXP transaction
 *
 * This function handles:
 * - Adding EXP to user's total
 * - Level up calculations
 * - Rank updates
 * - EXP history logging
 * - Quest completion tracking
 */
exports.addUserExp = functions.https.onCall(async (data, context) => {
    // Validate authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const uid = context.auth.uid;
    const { amount, source, questId, questName, exerciseType } = data;
    // Validate input
    if (!amount || typeof amount !== 'number' || amount <= 0) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid EXP amount');
    }
    // Max single transaction: 500 EXP
    const cappedAmount = Math.min(amount, 500);
    try {
        const userRef = db.collection('users').doc(uid);
        const expHistoryRef = db.collection('users').doc(uid).collection('exp_history').doc();
        const questHistoryRef = db.collection('users').doc(uid).collection('quest_history').doc();
        // Use transaction for atomicity
        return db.runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'User document not found');
            }
            const userData = userDoc.data();
            const currentTotalExp = userData.totalExp || 0;
            const newTotalExp = currentTotalExp + cappedAmount;
            // Calculate new level and stats
            const levelInfo = calculateLevel(newTotalExp);
            const newRank = getRank(levelInfo.level);
            // Prepare batch updates
            const batch = db.batch();
            // 1. Update user document with new EXP/level/rank
            batch.update(userRef, {
                totalExp: newTotalExp,
                level: levelInfo.level,
                currentExp: levelInfo.currentExp,
                expToNextLevel: levelInfo.expToNextLevel,
                rank: newRank,
                lastExpGain: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            // 2. Add to EXP history
            batch.set(expHistoryRef, {
                amount: cappedAmount,
                source: source || 'unknown',
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                levelAtGain: levelInfo.level,
            });
            // 3. If this is a quest completion, add to quest history
            if (questId && questName) {
                batch.set(questHistoryRef, {
                    questId,
                    questName,
                    expReward: cappedAmount,
                    exerciseType: exerciseType || 'general',
                    completedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                // 4. Update quest progress (per-date scoped)
                const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
                const questProgressRef = db
                    .collection('users').doc(uid)
                    .collection('quest_progress').doc(today)
                    .collection('quests').doc(questId);
                batch.set(questProgressRef, {
                    questId,
                    isCompleted: true,
                    completedAt: admin.firestore.FieldValue.serverTimestamp(),
                    expEarned: cappedAmount,
                }, { merge: true });
            }
            await batch.commit();
            // Return updated stats for client
            return {
                success: true,
                expAdded: cappedAmount,
                totalExp: newTotalExp,
                level: levelInfo.level,
                currentExp: levelInfo.currentExp,
                expToNextLevel: levelInfo.expToNextLevel,
                rank: newRank,
                leveledUp: levelInfo.level > (userData.level || 1),
                newLevel: levelInfo.level,
            };
        });
    }
    catch (error) {
        console.error('Error adding EXP:', error);
        throw new functions.https.HttpsError('internal', 'Failed to add EXP');
    }
});
/**
 * Batch Complete Quest - Handles all quest completion in one transaction
 */
exports.completeQuest = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const uid = context.auth.uid;
    const { questId, questName, expReward, exerciseType, currentProgress } = data;
    if (!questId || !questName || !expReward) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }
    try {
        const userRef = db.collection('users').doc(uid);
        return db.runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'User not found');
            }
            const userData = userDoc.data();
            const currentTotalExp = userData.totalExp || 0;
            const newTotalExp = currentTotalExp + expReward;
            // Calculate level progression
            const levelInfo = calculateLevel(newTotalExp);
            const newRank = getRank(levelInfo.level);
            // Prepare batch
            const batch = db.batch();
            // 1. Update user stats
            batch.update(userRef, {
                totalExp: newTotalExp,
                level: levelInfo.level,
                currentExp: levelInfo.currentExp,
                expToNextLevel: levelInfo.expToNextLevel,
                rank: newRank,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            // 2. EXP history
            const expHistoryRef = db.collection('users').doc(uid).collection('exp_history').doc();
            batch.set(expHistoryRef, {
                amount: expReward,
                source: questName,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
            // 3. Quest history
            const questHistoryRef = db.collection('users').doc(uid).collection('quest_history').doc();
            batch.set(questHistoryRef, {
                questId,
                questName,
                expReward,
                exerciseType: exerciseType || 'general',
                completedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            // 4. Quest progress (per-date scoped)
            const today = new Date().toISOString().split('T')[0];
            const questProgressRef = db
                .collection('users').doc(uid)
                .collection('quest_progress').doc(today)
                .collection('quests').doc(questId);
            batch.set(questProgressRef, {
                questId,
                isCompleted: true,
                completedAt: admin.firestore.FieldValue.serverTimestamp(),
                expEarned: expReward,
            }, { merge: true });
            await batch.commit();
            return {
                success: true,
                expAdded: expReward,
                totalExp: newTotalExp,
                level: levelInfo.level,
                leveledUp: levelInfo.level > (userData.level || 1),
            };
        });
    }
    catch (error) {
        console.error('Error completing quest:', error);
        throw new functions.https.HttpsError('internal', 'Failed to complete quest');
    }
});
/**
 * Check and unlock achievements
 */
exports.checkAchievements = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const uid = context.auth.uid;
    const { questsCompleted, streakDays, totalExp, level, friendsCount, walkingQuestsCompleted, hydrationQuestsCompleted, exerciseQuestsCompleted, questCompletedAt } = data;
    try {
        const userAchievementsRef = db.collection('users').doc(uid).collection('achievements').doc('progress');
        return db.runTransaction(async (transaction) => {
            var _a, _b;
            const doc = await transaction.get(userAchievementsRef);
            const unlockedIds = doc.exists ? (((_a = doc.data()) === null || _a === void 0 ? void 0 : _a.unlockedIds) || []) : [];
            // Define achievements to check
            const achievements = [
                // Quest achievements
                { id: 'first_quest', condition: questsCompleted >= 1, expReward: 50 },
                { id: 'quest_5', condition: questsCompleted >= 5, expReward: 100 },
                { id: 'quest_25', condition: questsCompleted >= 25, expReward: 250 },
                { id: 'quest_50', condition: questsCompleted >= 50, expReward: 500 },
                { id: 'quest_100', condition: questsCompleted >= 100, expReward: 1000 },
                // Streak achievements
                { id: 'streak_3', condition: streakDays >= 3, expReward: 100 },
                { id: 'streak_7', condition: streakDays >= 7, expReward: 250 },
                { id: 'streak_14', condition: streakDays >= 14, expReward: 500 },
                { id: 'streak_30', condition: streakDays >= 30, expReward: 1000 },
                // Level achievements
                { id: 'level_5', condition: level >= 5, expReward: 200 },
                { id: 'level_10', condition: level >= 10, expReward: 500 },
                { id: 'level_25', condition: level >= 25, expReward: 1500 },
                { id: 'level_50', condition: level >= 50, expReward: 5000 },
                // Time-based achievements
                { id: 'early_bird', condition: questCompletedAt && new Date(questCompletedAt).getHours() < 9, expReward: 100 },
                { id: 'night_owl', condition: questCompletedAt && new Date(questCompletedAt).getHours() >= 22, expReward: 100 },
            ];
            const newlyUnlocked = [];
            let totalExpReward = 0;
            for (const achievement of achievements) {
                if (!unlockedIds.includes(achievement.id) && achievement.condition) {
                    newlyUnlocked.push(achievement.id);
                    totalExpReward += achievement.expReward;
                }
            }
            if (newlyUnlocked.length > 0) {
                // Update unlocked achievements
                transaction.update(userAchievementsRef, {
                    unlockedIds: admin.firestore.FieldValue.arrayUnion(...newlyUnlocked),
                    lastChecked: admin.firestore.FieldValue.serverTimestamp(),
                });
                // Award EXP for achievements
                if (totalExpReward > 0) {
                    const userRef = db.collection('users').doc(uid);
                    const userDoc = await transaction.get(userRef);
                    const currentExp = ((_b = userDoc.data()) === null || _b === void 0 ? void 0 : _b.totalExp) || 0;
                    const newLevelInfo = calculateLevel(currentExp + totalExpReward);
                    transaction.update(userRef, {
                        totalExp: admin.firestore.FieldValue.increment(totalExpReward),
                        level: newLevelInfo.level,
                        currentExp: newLevelInfo.currentExp,
                    });
                }
            }
            return {
                success: true,
                newlyUnlocked,
                expFromAchievements: totalExpReward,
            };
        });
    }
    catch (error) {
        console.error('Error checking achievements:', error);
        throw new functions.https.HttpsError('internal', 'Failed to check achievements');
    }
});
/**
 * Scheduled function to calculate daily EXP
 * Runs every day at midnight to reset daily counters
 */
exports.resetDailyCounters = functions.pubsub
    .schedule('0 0 * * *') // Every day at midnight
    .timeZone('Asia/Jakarta')
    .onRun(async () => {
    // This can be used to reset daily EXP if you have a daily limit system
    // For now, just log
    console.log('Daily counter reset triggered');
    return null;
});
/**
 * On-demand Gemini AI call via Cloud Function (API key protected)
 */
exports.generateQuestWithAI = functions.https.onCall(async (data, context) => {
    var _a, _b, _c, _d, _e, _f;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const uid = context.auth.uid;
    const { userLevel, userExp, bmi, age, fitnessGoal } = data;
    // API key should be stored in environment config, not in code
    const apiKey = (_a = functions.config().gemini) === null || _a === void 0 ? void 0 : _a.api_key;
    if (!apiKey) {
        throw new functions.https.HttpsError('internal', 'AI service not configured');
    }
    try {
        // Build prompt based on user data
        const prompt = `Generate a personalized fitness quest for:
- User Level: ${userLevel}
- Total EXP: ${userExp}
- BMI: ${bmi || 'Not set'}
- Age: ${age || 'Not set'}
- Goal: ${fitnessGoal || 'General fitness'}

Return a JSON with quest recommendations.`;
        const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${apiKey}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                contents: [{ parts: [{ text: prompt }] }],
                generationConfig: {
                    temperature: 0.7,
                    maxOutputTokens: 500,
                }
            })
        });
        const result = await response.json();
        const generatedText = (_f = (_e = (_d = (_c = (_b = result.candidates) === null || _b === void 0 ? void 0 : _b[0]) === null || _c === void 0 ? void 0 : _c.content) === null || _d === void 0 ? void 0 : _d.parts) === null || _e === void 0 ? void 0 : _e[0]) === null || _f === void 0 ? void 0 : _f.text;
        return {
            success: true,
            quest: generatedText || 'Could not generate quest',
        };
    }
    catch (error) {
        console.error('Gemini API error:', error);
        throw new functions.https.HttpsError('internal', 'Failed to generate quest');
    }
});
// ========== DEPLOY INSTRUCTIONS ==========
/*
To deploy these functions:

1. Set Gemini API key (rotate your key first):
   firebase functions:config:set gemini.api_key="YOUR_NEW_API_KEY"

2. Deploy functions:
   cd functions
   npm install
   npm run build
   firebase deploy --only functions

3. Deploy Firestore rules:
   firebase deploy --only firestore:rules
*/
//# sourceMappingURL=index.js.map