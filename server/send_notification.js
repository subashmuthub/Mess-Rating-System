const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
require('dotenv').config();

function readFlag(flagName) {
  const index = process.argv.indexOf(flagName);
  if (index === -1) return undefined;
  return process.argv[index + 1];
}

function resolveCredentialPath() {
  const configured =
    process.env.SERVICE_ACCOUNT_PATH ||
    process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    './serviceAccountKey.json';

  return path.resolve(process.cwd(), configured);
}

function getDeviceToken() {
  return readFlag('--token') || process.env.FCM_DEVICE_TOKEN;
}

function getTitle() {
  return readFlag('--title') || process.env.DEFAULT_TITLE || 'Hello';
}

function getBody() {
  return (
    readFlag('--body') ||
    process.env.DEFAULT_BODY ||
    'FCM working successfully'
  );
}

async function sendNotification() {
  const credentialPath = resolveCredentialPath();
  const token = getDeviceToken();

  if (!fs.existsSync(credentialPath)) {
    throw new Error(
      `Service account JSON not found at: ${credentialPath}. Place your key file there or set SERVICE_ACCOUNT_PATH.`
    );
  }

  if (!token) {
    throw new Error(
      'Device token is missing. Pass --token <FCM_TOKEN> or set FCM_DEVICE_TOKEN in .env.'
    );
  }

  const serviceAccount = require(credentialPath);

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  const message = {
    notification: {
      title: getTitle(),
      body: getBody(),
    },
    token,
  };

  const response = await admin.messaging().send(message);
  console.log('Notification sent successfully:', response);
}

sendNotification().catch((error) => {
  console.error('Failed to send notification:', error.message);
  process.exit(1);
});
