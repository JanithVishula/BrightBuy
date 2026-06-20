// src/components/Navbar.jsx
"use client";
import Link from "next/link";
import React from "react";
import Image from "next/image";
import { useCart } from "@/contexts/CartContext";
import { ThemeSwitcher } from "@/components/ThemeSwitcher";
import SearchBar from "@/components/SearchBar";
import { useAuth } from "@/contexts/AuthContext";

const Navbar = () => {
  const { cartCount } = useCart();
  const { user } = useAuth();

  return (
    <header className="bg-card shadow-sm sticky top-0 z-50 border-b border-card-border">
      <nav className="container mx-auto px-6 py-4">
        <div className="flex justify-between items-center gap-6">
          {/* Left Section: Logo (pulled hard-left) + User Info */}
          <div className="flex items-center gap-5">
            <Link href="/" className="flex items-center gap-3 group shrink-0">
              <Image
                src="/brightbuy-logo.png"
                alt="BrightBuy"
                width={170}
                height={48}
                className="h-11 w-auto object-contain transition-transform duration-300 group-hover:scale-105"
                priority
              />
              <span className="hidden sm:block text-xs text-text-secondary font-medium border-l border-card-border pl-3">
                Your Tech
                <br />
                Paradise
              </span>
            </Link>

            {user && (
              <div className="hidden lg:flex items-center space-x-3 px-4 py-2 bg-background rounded-full border border-card-border shadow-sm">
                <div className="w-10 h-10 bg-primary rounded-full flex items-center justify-center text-white font-bold">
                  {user.name?.charAt(0).toUpperCase() || "U"}
                </div>
                <div className="text-sm text-text-primary">
                  <div className="font-semibold">{user.name}</div>
                  <div className="text-xs text-text-secondary">
                    {user.email}
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Center Section: Search Bar - Hidden for staff */}
          <div className="flex-1 max-w-2xl">
            {user?.role !== "staff" && <SearchBar />}
          </div>

          {/* Right Section: Actions */}
          <div className="flex items-center space-x-3">
            {/* Theme Switcher with premium styling */}
            <div className="p-2 hover:bg-background rounded-full transition-all">
              <ThemeSwitcher />
            </div>

            {/* Cart Icon - Hidden for staff */}
            {user?.role !== "staff" && (
              <Link
                href="/cart"
                className="relative p-3 hover:bg-background rounded-full transition-all group"
              >
                <i className="fas fa-shopping-cart text-xl text-text-secondary group-hover:text-secondary transition-colors"></i>
                {cartCount > 0 && (
                  <span className="absolute -top-1 -right-1 bg-secondary text-white text-xs font-bold rounded-full h-6 w-6 flex items-center justify-center">
                    {cartCount}
                  </span>
                )}
              </Link>
            )}

            {/* User Actions */}
            {user ? (
              user.role === "staff" ? (
                <Link
                  href="/staff/dashboard"
                  className="bg-primary hover:bg-primary-dark text-white px-6 py-2.5 rounded-lg font-semibold transition-colors flex items-center space-x-2"
                >
                  <i className="fas fa-user-tie"></i>
                  <span>Staff Dashboard</span>
                </Link>
              ) : (
                <Link
                  href="/profile"
                  className="bg-primary hover:bg-primary-dark text-white px-6 py-2.5 rounded-lg font-semibold transition-colors flex items-center space-x-2"
                >
                  <i className="fas fa-user-circle"></i>
                  <span className="hidden md:inline">
                    {user.name || "Profile"}
                  </span>
                </Link>
              )
            ) : (
              <Link
                href="/login"
                className="bg-primary hover:bg-primary-dark text-white px-8 py-2.5 rounded-lg font-bold transition-colors flex items-center space-x-2"
              >
                <i className="fas fa-sign-in-alt"></i>
                <span>Login</span>
              </Link>
            )}
          </div>
        </div>
      </nav>
    </header>
  );
};

export default Navbar;
