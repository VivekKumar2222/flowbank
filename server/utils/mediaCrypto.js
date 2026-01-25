const crypto = require("crypto");

const ALGORITHM = "aes-256-gcm";
const SECRET = process.env.MEDIA_ENCRYPTION_KEY;

if (!SECRET) {
  throw new Error("MEDIA_ENCRYPTION_KEY is not defined");
}

// Derive 32-byte key from SECRET
const KEY = crypto.createHash("sha256").update(SECRET).digest();

function encrypt(text) {
  const iv = crypto.randomBytes(12); // 12 bytes for GCM
  const cipher = crypto.createCipheriv(ALGORITHM, KEY, iv);

  const encrypted = Buffer.concat([cipher.update(text, "utf8"), cipher.final()]);
  const tag = cipher.getAuthTag();

  // Store as iv:tag:encrypted in base64
  return `${iv.toString("base64")}:${tag.toString("base64")}:${encrypted.toString("base64")}`;
}

function decrypt(payload) {
  try {
    const [ivB64, tagB64, encryptedB64] = payload.split(":");
    if (!ivB64 || !tagB64 || !encryptedB64) {
      throw new Error("Invalid encrypted payload format");
    }

    const decipher = crypto.createDecipheriv(
      ALGORITHM,
      KEY,
      Buffer.from(ivB64, "base64")
    );

    decipher.setAuthTag(Buffer.from(tagB64, "base64"));

    const decrypted = Buffer.concat([
      decipher.update(Buffer.from(encryptedB64, "base64")),
      decipher.final()
    ]);

    return decrypted.toString("utf8");
  } catch (err) {
    console.error("Decryption failed:", err.message);
    return null; // fail-safe: return null if decryption fails
  }
}

module.exports = { encrypt, decrypt };
