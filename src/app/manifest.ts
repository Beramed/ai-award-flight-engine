import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Voando com Tati",
    short_name: "Voando Tati",
    description: "Busque destinos pelo nome do lugar e compare passagens com milhas.",
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
