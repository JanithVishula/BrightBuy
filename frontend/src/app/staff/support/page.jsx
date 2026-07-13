"use client";
import React, { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { supportAPI } from "@/services/api";
import { useToast } from "@/contexts/ToastContext";

const statusStyle = {
  open: "bg-yellow-100 text-yellow-800",
  in_progress: "bg-blue-100 text-blue-800",
  resolved: "bg-green-100 text-green-800",
  closed: "bg-gray-200 text-gray-700",
};
const priorityStyle = {
  high: "bg-red-100 text-red-800",
  medium: "bg-orange-100 text-orange-800",
  low: "bg-green-100 text-green-800",
};

export default function CustomerSupport() {
  const router = useRouter();
  const { showToast } = useToast();
  const [user, setUser] = useState(null);
  const [tickets, setTickets] = useState([]);
  const [stats, setStats] = useState({
    open: 0,
    in_progress: 0,
    resolved: 0,
    closed: 0,
  });
  const [filterStatus, setFilterStatus] = useState("all");
  const [loading, setLoading] = useState(true);

  const [active, setActive] = useState(null); // { ticket, messages }
  const [reply, setReply] = useState("");
  const [sending, setSending] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem("authToken");
    const userData = localStorage.getItem("user");
    if (!token || !userData) return router.push("/login");
    const parsed = JSON.parse(userData);
    if (parsed.role !== "staff") return router.push("/");
    setUser(parsed);
  }, [router]);

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      const [tRes, sRes] = await Promise.all([
        supportAPI.getAllTickets(filterStatus),
        supportAPI.getStats(),
      ]);
      setTickets(tRes.tickets || []);
      if (sRes.stats) setStats(sRes.stats);
    } catch (e) {
      console.error(e);
      showToast("Failed to load tickets.", "error");
    } finally {
      setLoading(false);
    }
  }, [filterStatus, showToast]);

  useEffect(() => {
    if (user) loadData();
  }, [user, loadData]);

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
      await openTicket(active.ticket.ticket_id);
      showToast("Reply sent to customer.", "success");
      loadData();
    } catch (e) {
      showToast("Failed to send reply.", "error");
    } finally {
      setSending(false);
    }
  };

  const changeStatus = async (status) => {
    if (!active) return;
    try {
      await supportAPI.updateTicket(active.ticket.ticket_id, { status });
      setActive({ ...active, ticket: { ...active.ticket, status } });
      showToast(`Ticket marked ${status.replace("_", " ")}.`, "success");
      loadData();
    } catch (e) {
      showToast("Failed to update status.", "error");
    }
  };

  if (!user) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <div className="container mx-auto px-6 py-8">
        <div className="mb-8">
          <Link
            href="/staff/dashboard"
            className="text-primary hover:underline mb-2 inline-block"
          >
            ← Back to Dashboard
          </Link>
          <h1 className="text-3xl font-bold text-text-primary flex items-center gap-3">
            <i className="fas fa-headset text-primary"></i> Customer Support
          </h1>
          <p className="text-text-secondary mt-2">
            Manage customer inquiries and support tickets
          </p>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          {[
            {
              key: "open",
              label: "Open",
              cls: "bg-yellow-50 dark:bg-yellow-900/20 border-yellow-200 dark:border-yellow-800",
            },
            {
              key: "in_progress",
              label: "In Progress",
              cls: "bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800",
            },
            {
              key: "resolved",
              label: "Resolved",
              cls: "bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800",
            },
            {
              key: "closed",
              label: "Closed",
              cls: "bg-gray-50 dark:bg-gray-800/40 border-gray-200 dark:border-gray-700",
            },
          ].map((s) => (
            <div key={s.key} className={`border rounded-lg p-4 ${s.cls}`}>
              <div className="text-sm font-medium text-text-secondary">
                {s.label}
              </div>
              <div className="text-2xl font-bold text-text-primary">
                {stats[s.key] || 0}
              </div>
            </div>
          ))}
        </div>

        {/* Filter */}
        <div className="mb-6 flex gap-2 flex-wrap">
          {["all", "open", "in_progress", "resolved", "closed"].map((f) => (
            <button
              key={f}
              onClick={() => setFilterStatus(f)}
              className={`px-4 py-2 rounded capitalize ${
                filterStatus === f
                  ? "bg-primary text-white"
                  : "bg-gray-200 dark:bg-gray-700 text-text-secondary"
              }`}
            >
              {f.replace("_", " ")}
            </button>
          ))}
        </div>

        {/* Tickets list */}
        <div className="bg-card border border-card-border rounded-lg overflow-hidden">
          <div className="px-6 py-4 bg-gray-50 dark:bg-gray-800 border-b border-card-border flex justify-between items-center">
            <h2 className="text-xl font-bold text-text-primary">
              Support Tickets
            </h2>
            <span className="text-sm text-text-secondary">
              {tickets.length} ticket{tickets.length === 1 ? "" : "s"}
            </span>
          </div>

          {loading ? (
            <div className="p-8 text-center text-text-secondary">
              <i className="fas fa-spinner fa-spin mr-2"></i> Loading...
            </div>
          ) : tickets.length === 0 ? (
            <div className="p-8 text-center text-text-secondary">
              <i className="fas fa-inbox text-3xl mb-2 opacity-50"></i>
              <p>No tickets found.</p>
            </div>
          ) : (
            <div className="divide-y divide-gray-200 dark:divide-gray-700">
              {tickets.map((t) => (
                <div
                  key={t.ticket_id}
                  className="px-6 py-4 hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer"
                  onClick={() => openTicket(t.ticket_id)}
                >
                  <div className="flex justify-between items-start mb-1 gap-3">
                    <h3 className="text-lg font-semibold text-text-primary">
                      #{t.ticket_id} · {t.subject}
                    </h3>
                    <div className="flex gap-2 shrink-0">
                      <span
                        className={`px-3 py-1 text-xs font-semibold rounded-full ${
                          statusStyle[t.status]
                        }`}
                      >
                        {t.status.replace("_", " ")}
                      </span>
                      <span
                        className={`px-3 py-1 text-xs font-semibold rounded-full ${
                          priorityStyle[t.priority]
                        }`}
                      >
                        {t.priority}
                      </span>
                    </div>
                  </div>
                  <p className="text-sm text-text-secondary">
                    {t.name} • {t.email}
                  </p>
                  <p className="text-sm text-text-secondary truncate mt-1">
                    {t.message}
                  </p>
                  <p className="text-xs text-text-secondary mt-1">
                    {new Date(t.created_at).toLocaleString()} ·{" "}
                    {t.message_count} message{t.message_count === 1 ? "" : "s"}
                  </p>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Thread modal */}
      {active && (
        <div
          className="fixed inset-0 bg-black/50 z-[9998] flex items-center justify-center p-4"
          onClick={() => setActive(null)}
        >
          <div
            className="bg-white dark:bg-gray-900 rounded-xl shadow-2xl max-w-lg w-full max-h-[88vh] flex flex-col"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="p-5 border-b border-gray-200 dark:border-gray-700">
              <div className="flex items-start justify-between">
                <div>
                  <h3 className="font-bold text-text-primary">
                    #{active.ticket.ticket_id} · {active.ticket.subject}
                  </h3>
                  <p className="text-sm text-text-secondary">
                    {active.ticket.name} ({active.ticket.email})
                  </p>
                </div>
                <button
                  onClick={() => setActive(null)}
                  className="text-gray-400 hover:text-gray-600 text-xl"
                >
                  <i className="fas fa-xmark"></i>
                </button>
              </div>
              <div className="flex gap-2 mt-3">
                {["open", "in_progress", "resolved", "closed"].map((s) => (
                  <button
                    key={s}
                    onClick={() => changeStatus(s)}
                    className={`px-3 py-1 text-xs rounded-full capitalize border ${
                      active.ticket.status === s
                        ? statusStyle[s] + " border-transparent font-bold"
                        : "border-gray-300 text-text-secondary hover:bg-gray-100 dark:hover:bg-gray-800"
                    }`}
                  >
                    {s.replace("_", " ")}
                  </button>
                ))}
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-5 space-y-3">
              {active.messages.map((m) => (
                <div
                  key={m.message_id}
                  className={`flex ${
                    m.sender_role === "staff" ? "justify-end" : "justify-start"
                  }`}
                >
                  <div
                    className={`max-w-[80%] rounded-2xl px-4 py-2 ${
                      m.sender_role === "staff"
                        ? "bg-primary text-white"
                        : "bg-gray-100 dark:bg-gray-800 text-text-primary"
                    }`}
                  >
                    <p className="text-xs opacity-70 mb-1">
                      {m.sender_role === "staff"
                        ? "🎧 " + m.sender_name
                        : "👤 " + m.sender_name}
                    </p>
                    <p className="text-sm whitespace-pre-line">{m.body}</p>
                    <p className="text-[10px] opacity-60 mt-1">
                      {new Date(m.created_at).toLocaleString()}
                    </p>
                  </div>
                </div>
              ))}
            </div>

            <div className="p-4 border-t border-gray-200 dark:border-gray-700 flex gap-2">
              <input
                value={reply}
                onChange={(e) => setReply(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && sendReply()}
                placeholder="Reply to customer..."
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
                  <>
                    <i className="fas fa-paper-plane mr-1"></i> Send
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
