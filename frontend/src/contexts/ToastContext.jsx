// src/contexts/ToastContext.jsx
// Lightweight, app-wide toast notifications. Replaces raw window.alert()
// with animated, styled, auto-dismissing messages.
"use client";

import React, {
  createContext,
  useContext,
  useState,
  useCallback,
} from "react";

const ToastContext = createContext(null);

export const useToast = () => {
  const ctx = useContext(ToastContext);
  if (!ctx) {
    // Fail soft so a component outside the provider doesn't crash.
    return { showToast: () => {} };
  }
  return ctx;
};

let idCounter = 0;

const ICONS = {
  success: "fa-circle-check",
  error: "fa-circle-xmark",
  info: "fa-circle-info",
  warning: "fa-triangle-exclamation",
};

export const ToastProvider = ({ children }) => {
  const [toasts, setToasts] = useState([]);

  const removeToast = useCallback((id) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const showToast = useCallback(
    (message, type = "info", duration = 4000) => {
      const id = ++idCounter;
      setToasts((prev) => [...prev, { id, message, type }]);
      if (duration > 0) {
        setTimeout(() => removeToast(id), duration);
      }
      return id;
    },
    [removeToast]
  );

  return (
    <ToastContext.Provider value={{ showToast, removeToast }}>
      {children}

      {/* Toast viewport — fixed top-right, above everything */}
      <div className="fixed top-5 right-5 z-[9999] flex flex-col gap-3 w-[min(92vw,380px)] pointer-events-none">
        {toasts.map((t) => (
          <div
            key={t.id}
            role="status"
            className={`toast-item pointer-events-auto flex items-start gap-3 rounded-xl border px-4 py-3 shadow-lg backdrop-blur bg-white/95 dark:bg-gray-900/95 ${
              t.type === "success"
                ? "border-green-300 dark:border-green-700"
                : t.type === "error"
                ? "border-red-300 dark:border-red-700"
                : t.type === "warning"
                ? "border-amber-300 dark:border-amber-700"
                : "border-blue-300 dark:border-blue-700"
            }`}
          >
            <i
              className={`fas ${ICONS[t.type] || ICONS.info} text-xl mt-0.5 ${
                t.type === "success"
                  ? "text-green-500"
                  : t.type === "error"
                  ? "text-red-500"
                  : t.type === "warning"
                  ? "text-amber-500"
                  : "text-blue-500"
              }`}
            ></i>
            <p className="flex-1 text-sm font-medium text-gray-800 dark:text-gray-100 whitespace-pre-line">
              {t.message}
            </p>
            <button
              onClick={() => removeToast(t.id)}
              className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 shrink-0"
              aria-label="Dismiss"
            >
              <i className="fas fa-xmark"></i>
            </button>
          </div>
        ))}
      </div>

      <style jsx global>{`
        .toast-item {
          animation: toast-in 0.28s cubic-bezier(0.21, 1.02, 0.73, 1);
        }
        @keyframes toast-in {
          from {
            opacity: 0;
            transform: translateX(24px) scale(0.96);
          }
          to {
            opacity: 1;
            transform: translateX(0) scale(1);
          }
        }
      `}</style>
    </ToastContext.Provider>
  );
};
