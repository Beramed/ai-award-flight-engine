import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import type { AccessPlan } from "./auth-types";
import { isValidCpf, normalizeName, onlyDigits } from "./cpf";
import { hashPassword, hashSecret, validatePassword, verifyPassword } from "./crypto-pass";

export type { AccessPlan } from "./auth-types";

export type StoredUser = {
  id: string;
  fullName: string;
  preferredName: string;
  email: string;
  country: string;
  phone: string;
  address: string;
  cpfHash: string;
  cpfLast4: string;
  passwordHash: string;
  role: "user" | "master";
  createdAt: string;
  deletedAt: string | null;
  accessPlan: AccessPlan;
  accessExpiresAt: string | null;
};

export type PublicUser = {
  id: string;
  fullName: string;
  preferredName: string;
  email: string;
  country: string;
  phone: string;
  address: string;
  cpfLast4: string;
  role: "user" | "master";
  createdAt: string;
  deletedAt: string | null;
  accessPlan: AccessPlan;
  accessExpiresAt: string | null;
  expired: boolean;
};

type StoreFile = { users: StoredUser[] };

const MASTER_NAME = process.env.MASTER_NAME ?? "Tati";
const MASTER_PASSWORD = process.env.MASTER_PASSWORD ?? "0602";

function filePath() {
  if (process.env.VERCEL) return join("/tmp", "voando-users.json");
  return join(process.cwd(), "data", "users.json");
}

function emptyStore(): StoreFile {
  return { users: [] };
}

function readStore(): StoreFile {
  try {
    return JSON.parse(readFileSync(filePath(), "utf8")) as StoreFile;
  } catch {
    return emptyStore();
  }
}

function writeStore(store: StoreFile) {
  const path = filePath();
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, JSON.stringify(store, null, 2), "utf8");
}

function publicUser(user: StoredUser): PublicUser {
  const expired = Boolean(user.accessExpiresAt && Date.parse(user.accessExpiresAt) < Date.now());
  return {
    id: user.id,
    fullName: user.fullName,
    preferredName: user.preferredName,
    email: user.email,
    country: user.country,
    phone: user.phone,
    address: user.address,
    cpfLast4: user.cpfLast4,
    role: user.role,
    createdAt: user.createdAt,
    deletedAt: user.deletedAt,
    accessPlan: user.accessPlan,
    accessExpiresAt: user.accessExpiresAt,
    expired,
  };
}

function ensureMaster(store: StoreFile) {
  const exists = store.users.find((user) => user.role === "master");
  if (exists) return store;
  store.users.push({
    id: "master-tati",
    fullName: MASTER_NAME,
    preferredName: MASTER_NAME,
    email: "tati@voandocomtati.local",
    country: "Brasil",
    phone: "",
    address: "",
    cpfHash: "",
    cpfLast4: "",
    passwordHash: hashPassword(MASTER_PASSWORD),
    role: "master",
    createdAt: new Date().toISOString(),
    deletedAt: null,
    accessPlan: "indefinite",
    accessExpiresAt: null,
  });
  writeStore(store);
  return store;
}

function load() {
  return ensureMaster(readStore());
}

export function planToExpiry(plan: AccessPlan) {
  if (plan === "indefinite") return null;
  const date = new Date();
  if (plan === "7d") date.setDate(date.getDate() + 7);
  if (plan === "1m") date.setMonth(date.getMonth() + 1);
  if (plan === "6m") date.setMonth(date.getMonth() + 6);
  if (plan === "1y") date.setFullYear(date.getFullYear() + 1);
  return date.toISOString();
}

export function findUserByLogin(login: string) {
  const store = load();
  const key = login.trim().toLowerCase();
  return store.users.find(
    (user) =>
      !user.deletedAt &&
      (user.preferredName.toLowerCase() === key ||
        user.email.toLowerCase() === key ||
        user.fullName.toLowerCase() === key),
  );
}

export function authenticate(login: string, password: string) {
  const user = findUserByLogin(login);
  if (!user || !verifyPassword(password, user.passwordHash)) {
    return { error: "Nome ou senha inválidos." as const };
  }
  if (user.accessExpiresAt && Date.parse(user.accessExpiresAt) < Date.now()) {
    return { error: "Acesso expirado. Peça à Tati para renovar o prazo." as const };
  }
  return { user: publicUser(user) };
}

export function getUserById(id: string) {
  const user = load().users.find((item) => item.id === id);
  return user ? publicUser(user) : null;
}

export function listUsers() {
  return load().users.map(publicUser);
}

type RegisterInput = {
  fullName: string;
  preferredName: string;
  email: string;
  country: string;
  phone: string;
  address: string;
  cpf: string;
  password: string;
  recover?: boolean;
};

export function registerUser(input: RegisterInput) {
  const fullName = input.fullName.trim();
  const preferredName = input.preferredName.trim();
  const email = input.email.trim().toLowerCase();
  const passwordError = validatePassword(input.password);
  if (!fullName || !preferredName || !email) return { error: "Preencha nome, como quer ser chamado e e-mail." };
  if (passwordError) return { error: passwordError };
  if (!isValidCpf(input.cpf)) return { error: "CPF inválido." };
  if (normalizeName(preferredName) === normalizeName(MASTER_NAME)) {
    return { error: "Este nome de acesso é reservado." };
  }

  const store = load();
  const cpfHash = hashSecret(onlyDigits(input.cpf));
  const existing = store.users.find((user) => user.cpfHash === cpfHash && user.role !== "master");

  if (existing && !existing.deletedAt) {
    return { error: "Este CPF já está cadastrado." };
  }

  if (existing && existing.deletedAt) {
    if (normalizeName(existing.fullName) !== normalizeName(fullName)) {
      return { error: "Este CPF já foi usado e não pode ser cadastrado em outro nome." };
    }
    if (!input.recover) {
      return {
        recoverable: true as const,
        message: "Encontramos uma conta antiga neste CPF. Deseja recuperar a conta anterior?",
      };
    }
    existing.deletedAt = null;
    existing.preferredName = preferredName;
    existing.email = email;
    existing.country = input.country.trim();
    existing.phone = input.phone.trim();
    existing.address = input.address.trim();
    existing.passwordHash = hashPassword(input.password);
    writeStore(store);
    return { user: publicUser(existing), recovered: true as const };
  }

  if (store.users.some((user) => !user.deletedAt && user.email.toLowerCase() === email)) {
    return { error: "Este e-mail já está em uso." };
  }

  const user: StoredUser = {
    id: crypto.randomUUID(),
    fullName,
    preferredName,
    email,
    country: input.country.trim(),
    phone: input.phone.trim(),
    address: input.address.trim(),
    cpfHash,
    cpfLast4: onlyDigits(input.cpf).slice(-4),
    passwordHash: hashPassword(input.password),
    role: "user",
    createdAt: new Date().toISOString(),
    deletedAt: null,
    accessPlan: "indefinite",
    accessExpiresAt: null,
  };
  store.users.push(user);
  writeStore(store);
  return { user: publicUser(user) };
}

export function deleteUser(id: string, by: { id: string; role: "user" | "master" }) {
  const store = load();
  const user = store.users.find((item) => item.id === id);
  if (!user) return { error: "Usuário não encontrado." };
  if (user.role === "master") return { error: "A conta master não pode ser apagada." };
  if (by.role !== "master" && by.id !== id) return { error: "Sem permissão." };
  user.deletedAt = new Date().toISOString();
  writeStore(store);
  return { ok: true as const };
}

export function setUserAccess(id: string, plan: AccessPlan) {
  const store = load();
  const user = store.users.find((item) => item.id === id);
  if (!user) return { error: "Usuário não encontrado." };
  if (user.role === "master") {
    user.accessPlan = "indefinite";
    user.accessExpiresAt = null;
  } else {
    user.accessPlan = plan;
    user.accessExpiresAt = planToExpiry(plan);
  }
  writeStore(store);
  return { user: publicUser(user) };
}
