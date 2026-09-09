import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Award Engine",
    short_name: "Award Engine",
    description: "Compare tabela fixa e dinâmica e prepare a emissão de passagens com milhas.",
    start_url: "/",
    display: "standalone",
    background_color: "#081018",
    theme_color: "#081018",
    lang: "pt-BR",
    icons: [
      {
        src: "/icon.svg",
        sizes: "any",
        type: "image/svg+xml",
        purpose: "any",
      },
    ],
  };
}
