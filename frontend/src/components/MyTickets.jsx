// src/components/MyTickets.jsx
// Customer-facing support ticket list + thread view with reply.
"use client";
import React, { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { supportAPI } from "@/services/api";
import { useToast } from "@/contexts/ToastContext";

const statusStyle = {
  open: "bg-yellow-100 text-yellow-800",
  in_progress: "bg-blue-100 text-blue-800",
  resolved: "bg-green-100 text-green-800",
  closed: "bg-gray-200 text-gray-700",
};

export default function MyTickets() {
  const { showToast } = useToast();
  const [tickets, setTickets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [active, setActive] = useState(null); // { ticket, messages }
  const [reply, setReply] = useState("");
  const [sending, setSending] = useState(false);

  const loadTickets = useCallback(async () => {
    try {
      setLoading(true);
      const res = await supportAPI.getMyTickets();
      setTickets(res.tickets || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadTickets();
  }, [loadTickets]);

  const openTicket = async (id) => {
    try {
      const res = await supportAPI.getTicket(id);
      setActive(res);
    } catch (e) {
      showToast("Failed to open ticket.", "error");
    }
  };

  const sendReply = async () => {
    if (!reply.trim() || !active) return;
    setSending(true);
    try {
      await supportAPI.addMessage(active.ticket.ticket_id, reply.trim());
      setReply("");
      await openTicket(active.ticket.ticket_id); // refresh thread
      showToast("Reply sent.", "success");
      loadTickets();
    } catch (e) {
      showToast("Failed to send reply.", "error");
    } finally {
      setSending(false);
    }
  };

  if (loading) {
    return (
      <div className="bg-card border border-card-border rounded-lg p-6 mb-6 text-center text-text-secondary">
        <i className="fas fa-spinner fa-spin mr-2"></i> Loading your tickets...
      </div>
    );
  }

  return (
    <div className="bg-card border border-card-border rounded-lg shadow-sm p-6 mb-6">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-bold text-text-primary flex items-center gap-2">
          <i className="fas fa-ticket text-primary"></i> My Support Tickets
        </h2>
        <Link
          href="/contact"
          className="text-sm text-primary hover:underline font-medium"
        >
          <i className="fas fa-plus mr-1"></i> New Request
        </Link>
      </div>

      {tickets.length === 0 ? (
        <div className="text-center py-8 text-text-secondary">
          <i className="fas fa-inbox text-3xl mb-2 opacity-50"></i>
          <p>You haven't raised any support tickets yet.</p>
          <Link
            href="/contact"
            className="inline-block mt-3 text-primary hover:underline font-medium"
          >
            Contact Support →
          </Link>
        </div>
      ) : (
        <div className="space-y-2">
          {tickets.map((t) => (
            <button
              key={t.ticket_id}
              onClick={() => openTicket(t.ticket_id)}
              className="w-full text-left p-4 rounded-lg border border-card-border hover:bg-gray-50 dark:hover:bg-gray-800 transition flex items-center justify-between gap-3"
            >
              <div className="min-w-0">
                <p className="font-semibold text-text-primary truncate">
                  #{t.ticket_id} · {t.subject}
                </p>
                <p className="text-xs text-text-secondary">
                  {new Date(t.created_at).toLocaleString()} ·{" "}
                  {t.message_count} message{t.message_count === 1 ? "" : "s"}
                </p>
              </div>
              <span
                className={`shrink-0 px-3 py-1 text-xs font-semibold rounded-full ${
                  statusStyle[t.status] || statusStyle.closed
                }`}
              >
                {t.status.replace("_", " ")}
              </span>
            </button>
          ))}
        </div>
      )}

      {/* Thread modal */}
      {active && (
        <div
          className="fixed inset-0 bg-black/50 z-[9998] flex items-center justify-center p-4"
          onClick={() => setActive(null)}
        >
          <div
            className="bg-white dark:bg-gray-900 rounded-xl shadow-2xl max-w-lg w-full max-h-[85vh] flex flex-col"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="p-5 border-b border-gray-200 dark:border-gray-700 flex items-start justify-between">
              <div>
                <h3 className="font-bold text-text-primary">
                  #{active.ticket.ticket_id} · {active.ticket.subject}
                </h3>
                <span
                  className={`inline-block mt-1 px-2 py-0.5 text-xs font-semibold rounded-full ${
                    statusStyle[active.ticket.status]
                  }`}
                >
                  {active.ticket.status.replace("_", " ")}
                </span>
              </div>
              <button
                onClick={() => setActive(null)}
                className="text-gray-400 hover:text-gray-600 text-xl"
              >
                <i className="fas fa-xmark"></i>
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-5 space-y-3">
              {active.messages.map((m) => (
                <div
                  key={m.message_id}
                  className={`flex ${
                    m.sender_role === "customer"
                      ? "justify-end"
                      : "justify-start"
                  }`}
                >
                  <div
                    className={`max-w-[80%] rounded-2xl px-4 py-2 ${
                      m.sender_role === "customer"
                        ? "bg-primary text-white"
                        : "bg-gray-100 dark:bg-gray-800 text-text-primary"
                    }`}
                  >
                    <p className="text-xs opacity-70 mb-1">
                      {m.sender_role === "staff"
                        ? "🎧 " + m.sender_name
                        : m.sender_name}
                    </p>
                    <p className="text-sm whitespace-pre-line">{m.body}</p>
                    <p className="text-[10px] opacity-60 mt-1">
                      {new Date(m.created_at).toLocaleString()}
                    </p>
                  </div>
                </div>
              ))}
            </div>

            {active.ticket.status !== "closed" && (
              <div className="p-4 border-t border-gray-200 dark:border-gray-700 flex gap-2">
                <input
                  value={reply}
                  onChange={(e) => setReply(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && sendReply()}
                  placeholder="Type a reply..."
                  className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-700 rounded-lg bg-background text-text-primary"
                />
                <button
                  onClick={sendReply}
                  disabled={sending || !reply.trim()}
                  className="bg-primary text-white px-4 py-2 rounded-lg font-medium disabled:opacity-50"
                >
                  {sending ? (
                    <i className="fas fa-spinner fa-spin"></i>
                  ) : (
                    <i className="fas fa-paper-plane"></i>
                  )}
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
