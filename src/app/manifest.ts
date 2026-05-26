import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "DoUrStuff",
    short_name: "DoUrStuff",
    description: "A calm, local-first task manager for mobile and desktop.",
    start_url: "/",
    display: "standalone",
    background_color: "#fcfaf7",
    theme_color: "#fcfaf7",
    lang: "en",
    icons: [
      {
        src: "/icons/icon-192.svg",
        sizes: "192x192",
        type: "image/svg+xml"
      },
      {
        src: "/icons/icon-512.svg",
        sizes: "512x512",
        type: "image/svg+xml"
      }
    ]
  };
}
