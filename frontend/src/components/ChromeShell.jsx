"use client";
import { usePathname } from "next/navigation";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

// Portals with their own fixed sidebar must not render the global Footer
// underneath it (the sidebar would overlap the footer).
//   - /staff   : full custom shell, no public Navbar/Footer
//   - /profile : keep the Navbar (customer still needs to shop) but drop
//                the Footer to avoid the sidebar overlap
//   - else     : full public chrome (Navbar + Footer)
export default function ChromeShell({ children }) {
  const pathname = usePathname() || "";
  const isStaffPortal = pathname.startsWith("/staff");
  const isProfilePortal = pathname.startsWith("/profile");

  if (isStaffPortal) {
    return <main className="min-h-screen">{children}</main>;
  }

  if (isProfilePortal) {
    return (
      <div className="flex flex-col min-h-screen">
        <Navbar />
        <main className="flex-grow">{children}</main>
      </div>
    );
  }

  return (
    <div className="flex flex-col min-h-screen">
      <Navbar />
      <main className="flex-grow">{children}</main>
      <Footer />
    </div>
  );
}
