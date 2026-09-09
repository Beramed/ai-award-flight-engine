import { AIRPORTS } from "@/lib/airports";
import { DEFAULT_SEARCH } from "@/lib/engine";
import { DEFAULT_WALLETS, FIXED_TABLES } from "@/lib/tables";

export async function GET() {
  return Response.json({
    airports: AIRPORTS,
    wallets: DEFAULT_WALLETS,
    tables: FIXED_TABLES,
    defaultSearch: DEFAULT_SEARCH,
  });
}
