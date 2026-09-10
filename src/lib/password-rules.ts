export const PASSWORD_RULE =
  "A senha precisa ter 8 a 16 caracteres, com 1 letra minúscula, 1 maiúscula e 1 número.";

export function passwordIssue(password: string) {
  if (password.length < 8 || password.length > 16) return PASSWORD_RULE;
  if (!/[a-z]/.test(password) || !/[A-Z]/.test(password) || !/\d/.test(password)) return PASSWORD_RULE;
  return null;
}
