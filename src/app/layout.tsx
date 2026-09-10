import { AppShell } from "@/components/AppShell";
import { PwaRegister } from "@/components/PwaRegister";
import type { Metadata, Viewport } from "next";
import { Fraunces, IBM_Plex_Sans, IBM_Plex_Mono } from "next/font/google";
import "./globals.css";

const display = Fraunces({
  variable: "--font-display",
  subsets: ["latin"],
});

const sans = IBM_Plex_Sans({
  variable: "--font-sans",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
});

const mono = IBM_Plex_Mono({
  variable: "--font-mono",
  subsets: ["latin"],
  weight: ["400", "500"],
});

export const metadata: Metadata = {
  title: "Voando com Tati — passagens com milhas",
  description:
    "Busque o destino pelo nome do lugar, veja aeroportos próximos e compare milhas para emitir com aprovação humana.",
  applicationName: "Voando com Tati",
  appleWebApp: {
    capable: true,
    title: "Voando com Tati",
    statusBarStyle: "black-translucent",
  },
};

export const viewport: Viewport = {
  themeColor: "#081018",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="pt-BR"
      className={`${display.variable} ${sans.variable} ${mono.variable} h-full`}
    >
      <body className="min-h-full">
        <PwaRegister />
        <AppShell>{children}</AppShell>
      </body>
    </html>
  );
}
