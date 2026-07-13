// src/app/order-confirmation/[id]/page.jsx
"use client";

import React, { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { ordersAPI } from "@/services/api";
import { formatCurrency } from "@/utils/currency";
import { getImageUrl } from "@/utils/imageUrl";

export default function OrderConfirmationPage() {
  const { id } = useParams();
  const router = useRouter();
  const [order, setOrder] = useState(null);
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      try {
        const token =
          localStorage.getItem("token") ||
          localStorage.getItem("bb_token") ||
          localStorage.getItem("authToken");
        if (!token) return router.push("/login");
        const res = await ordersAPI.getOrderById(id, token);
        setOrder(res.order);
        setItems(res.items || []);
      } catch (e) {
        console.error("Failed to load confirmation:", e);
      } finally {
        setLoading(false);
      }
    };
    if (id) load();
  }, [id, router]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-14 w-14 border-b-2 border-primary" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-green-50 to-gray-50 dark:from-gray-900 dark:to-gray-950 py-12 px-4">
      <div className="max-w-2xl mx-auto">
        {/* Success hero */}
        <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-xl border border-gray-100 dark:border-gray-800 p-8 text-center mb-6">
          <div className="success-check mx-auto mb-5 w-24 h-24 rounded-full bg-green-100 dark:bg-green-900/40 flex items-center justify-center">
            <i className="fas fa-check text-5xl text-green-500" />
          </div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
            Order Confirmed!
          </h1>
          <p className="text-gray-500 dark:text-gray-400">
            Thank you for your purchase. A confirmation has been recorded for
            your order.
          </p>

          {order && (
            <div className="mt-6 grid grid-cols-2 sm:grid-cols-3 gap-3 text-left">
              <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-3">
                <p className="text-xs text-gray-400">Order ID</p>
                <p className="font-bold text-gray-900 dark:text-white">
                  #{order.order_id}
                </p>
              </div>
              <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-3">
                <p className="text-xs text-gray-400">Total</p>
                <p className="font-bold text-primary">
                  {formatCurrency(order.total)}
                </p>
              </div>
              <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-3">
                <p className="text-xs text-gray-400">Payment</p>
                <p className="font-bold text-gray-900 dark:text-white text-sm">
                  {order.payment_method || "N/A"}
                </p>
              </div>
              <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-3 col-span-2 sm:col-span-3">
                <p className="text-xs text-gray-400">Delivery</p>
                <p className="font-bold text-gray-900 dark:text-white text-sm">
                  {order.delivery_mode}
                  {order.delivery_mode === "Store Pickup"
                    ? " — collect from our store"
                    : ""}
                </p>
              </div>
            </div>
          )}

          <div className="flex flex-col sm:flex-row gap-3 justify-center mt-8">
            <Link
              href={`/order-tracking/${order?.order_id}`}
              className="bg-primary text-white px-6 py-3 rounded-lg font-semibold hover:bg-opacity-90 transition flex items-center justify-center gap-2"
            >
              <i className="fas fa-truck" /> Track Order
            </Link>
            <Link
              href="/products"
              className="bg-gray-100 dark:bg-gray-800 text-gray-800 dark:text-gray-100 px-6 py-3 rounded-lg font-semibold hover:bg-gray-200 dark:hover:bg-gray-700 transition flex items-center justify-center gap-2"
            >
              <i className="fas fa-bag-shopping" /> Keep Shopping
            </Link>
          </div>
        </div>

        {/* Items summary */}
        {items.length > 0 && (
          <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 p-6">
            <h2 className="font-semibold text-gray-900 dark:text-white mb-4">
              Items in this order
            </h2>
            <div className="space-y-3">
              {items.map((item) => (
                <div
                  key={item.order_item_id}
                  className="flex items-center gap-4"
                >
                  <div className="w-14 h-14 bg-gray-50 dark:bg-gray-800 rounded-lg overflow-hidden relative flex-shrink-0 border border-gray-100 dark:border-gray-700">
                    {item.image_url ? (
                      <Image
                        src={getImageUrl(item.image_url)}
                        alt={item.product_name}
                        fill
                        className="object-contain p-1"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-gray-300">
                        <i className="fas fa-image" />
                      </div>
                    )}
                  </div>
                  <div className="flex-1">
                    <p className="font-medium text-gray-900 dark:text-white text-sm">
                      {item.product_name}
                    </p>
                    <p className="text-xs text-gray-400">
                      {formatCurrency(item.unit_price)} × {item.quantity}
                    </p>
                  </div>
                  <p className="font-semibold text-gray-900 dark:text-white text-sm">
                    {formatCurrency(item.unit_price * item.quantity)}
                  </p>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      <style jsx global>{`
        .success-check {
          animation: pop-in 0.5s cubic-bezier(0.17, 0.89, 0.32, 1.28);
        }
        .success-check i {
          animation: check-draw 0.4s ease 0.2s both;
        }
        @keyframes pop-in {
          from {
            transform: scale(0);
            opacity: 0;
          }
          to {
            transform: scale(1);
            opacity: 1;
          }
        }
        @keyframes check-draw {
          from {
            transform: scale(0) rotate(-20deg);
            opacity: 0;
          }
          to {
            transform: scale(1) rotate(0);
            opacity: 1;
          }
        }
      `}</style>
    </div>
  );
}
