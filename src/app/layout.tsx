import type { Metadata } from "next";
import "./globals.css";
import Navbar from "@/components/Navbar";

export const metadata: Metadata = {
  title: "DoUrStuff",
  description: "Minimalist offline-first task manager",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="min-h-screen antialiased">
        <Navbar />
        <main className="container mx-auto px-4 pb-8">{children}</main>
      </body>
    </html>
  );
}
