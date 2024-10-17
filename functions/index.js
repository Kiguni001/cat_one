const functions = require("firebase-functions");
const {RtcTokenBuilder, RtcRole} = require("agora-access-token");

// กำหนดค่า Agora App ID และ App Certificate ของคุณ
const appID = "5801841d64fa4c8aa9f912cd9f6197de";
const appCertificate = "0db8fca050014b50bee8e1f388591622";

exports.generateAgoraToken = functions.https.onRequest((req, res) => {
  const channelName = req.query.channelName;
  const uid = req.query.uid;

  if (!channelName || !uid) {
    return res.status(400).send("Channel name and UID are required");
  }

  const role = RtcRole.PUBLISHER;
  const expireTime = 3600; // 1 hour
  const currentTime = Math.floor(Date.now() / 1000);
  const privilegeExpireTime = currentTime + expireTime;

  // สร้าง Token
  const token = RtcTokenBuilder.buildTokenWithUid(
    appID,
    appCertificate,
    channelName,
    uid,
    role,
    privilegeExpireTime
  );

  res.json({token: token});
});
