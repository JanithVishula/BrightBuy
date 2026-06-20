"use client";
import { usePathname } from "next/navigation";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

// The staff portal has its own full-screen shell (sidebar + header), so the
// public marketing Navbar/Footer must NOT render there — otherwise the fixed
// sidebar overlaps the footer and the page gets double chrome.
export default function ChromeShell({ children }) {
  const pathname = usePathname() || "";
  const isStaffPortal = pathname.startsWith("/staff");

  if (isStaffPortal) {
    return <main className="min-h-screen">{children}</main>;
  }

  return (
    <div className="flex flex-col min-h-screen">
      <Navbar />
      <main className="flex-grow">{children}</main>
      <Footer />
    </div>
  );
}
