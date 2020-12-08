const functions = require('firebase-functions');
const admin=require('firebase-admin');
const { Change } = require('firebase-functions');
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
exports.onCreateFollower=
 functions.firestore.document("/followers/{userId}/userFollowers/{followerId}").onCreate((snapshot,context)=>{
    console.log('follower Created',snapshot.data()); 
    const userId=context.params.userId;
     const followerId=context.params.followerId;


     //get followed user post
     const followedUserPostsRef=admin
     .firestore()
     .collection('posts')
     .doc(userId)
     .collection('userPosts');
     //following users timeline
     const timelinePostsRef=admin.
     firestore().
     collection('timeline')
     .doc(followerId)
     .collection('timelinePosts');
     //get follwed user
     const querySnapshot=await followedUserPostsRef.get();
     //add each user post to  follwoing      users timeline
     querySnapshot.forEach(doc=>{
         if(doc.exists){
             const postId=doc.id; 
             const postData=doc.data();
             timelinePostsRef.doc(postId).set(postData)
         }
     });


 });
 exports.onDeleteFollower=functions.firestore.document("/followers/{userId}/userFollowers/{followerId}")
 .onDelete((snapshot,context)=>{
     console.log('Follower Deleted',snapshot.id);
     const userId=context.params.userId;
     const followerId=context.params.followerId;
     const timelinePostsRef=admin.
     firestore().
     collection('timeline')
     .doc(followerId)
     .collection('timelinePosts').where("ownerId","==",userId);
     const querSnapshot=await timelinePostsRef.get();
     querSnapshot.forEach(doc=>{
         if(doc.exists){
             doc.ref.delete(); 
         }
     });
 });
exports.onCreatePost=functions.firestore.document('/posts/{userId}/usersPosts/{postId}').onCreate(async(snapshot,context)=>{
    const postCreated=snapshot.data();
    const userId=context.params.userId;
    const postId=context.params.postId;


    const userFollowersRef=admin.firestore().
    collection('followers')
    .doc(userId)
    .collection('userFollowers');
    const querSnapshot=await userFollowersRef.get();
    querSnapshot.forEach(doc=>{
        const followerId=doc.id;
        admin.firestore()
        .collection('timeline')
        .doc(followerId)
        .collection('timelinePosts')
        .doc(postId)
        .set(postCreated);

    });
});
exports.onUpdatePost=functions.firestore.document('/posts/{userId}/usersPosts/{postId}')
.onUpdate(async (change,context)=>{
   const postUpdated= change.after.data();
   const userId=context.params.userId;
    const postId=context.params.postId;
    const userFollowersRef=admin.firestore().
    collection('followers')
    .doc(userId)
    .collection('userFollowers');

    const querSnapshot=await userFollowersRef.get();

    querSnapshot.forEach(doc=>{
        const followerId=doc.id;
        admin.firestore()
        .collection('timeline')
        .doc(followerId)
        .collection('timelinePosts')
        .doc(postId)
        .get().then(doc=>{
            doc.ref.update(postUpdated);
        });

    });

});
exports.onDeletePost=functions.firestore.document('/posts/{userId}/usersPosts/{postId}')
.onDelete(async(snapshot,context)=>{
    const userId=context.params.userId;
    const postId=context.params.postId;
    const userFollowersRef=admin.firestore().
    collection('followers')
    .doc(userId)
    .collection('userFollowers');

    const querSnapshot=await userFollowersRef.get();

    querSnapshot.forEach(doc=>{
        const followerId=doc.id;
        admin.firestore()
        .collection('timeline')
        .doc(followerId)
        .collection('timelinePosts')
        .doc(postId)
        .get().then(doc=>{
            doc.ref.delete();
        });

    });

});