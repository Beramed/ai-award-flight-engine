import { createHash, randomBytes, scryptSync, timingSafeEqual } from "node:crypto";

import { passwordIssue } from "./password-rules";

export { PASSWORD_RULE } from "./password-rules";

export function validatePassword(password: string, { allowMaster = false } = {}) {
  if (allowMaster && password === (process.env.MASTER_PASSWORD ?? "0602")) return null;
  return passwordIssue(password);
}

export function hashSecret(value: string) {
  return createHash("sha256").update(value).digest("hex");
}

export function hashPassword(password: string) {
  const salt = randomBytes(16).toString("hex");
  const hash = scryptSync(password, salt, 32).toString("hex");
  return `${salt}:${hash}`;
}

export function verifyPassword(password: string, stored: string) {
  const [salt, hash] = stored.split(":");
  if (!salt || !hash) return false;
  const next = scryptSync(password, salt, 32);
  return timingSafeEqual(Buffer.from(hash, "hex"), next);
}
