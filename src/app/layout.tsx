import type { Metadata, Viewport } from "next";
import "./globals.css";
import { ServiceWorkerRegistration } from "@/components/pwa/service-worker-registration";

export const metadata: Metadata = {
  title: "DoUrStuff",
  description: "A calm, local-first task manager that stays useful offline.",
  applicationName: "DoUrStuff",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "DoUrStuff"
  },
  formatDetection: {
    telephone: false
  }
};

export const viewport: Viewport = {
  themeColor: "#fcfaf7"
};

export default function RootLayout({
  children
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>
        <ServiceWorkerRegistration />
        {children}
      </body>
    </html>
  );
}
