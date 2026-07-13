// src/app/contact/page.jsx
"use client";
import React, { useState, useEffect } from "react";
import Link from "next/link";
import { supportAPI } from "@/services/api";
import { useToast } from "@/contexts/ToastContext";
import { useAuth } from "@/contexts/AuthContext";

export default function ContactPage() {
  const { showToast } = useToast();
  const { user } = useAuth();

  const [form, setForm] = useState({
    name: "",
    email: "",
    subject: "",
    message: "",
    priority: "medium",
  });
  const [submitting, setSubmitting] = useState(false);
  const [lastTicketId, setLastTicketId] = useState(null);

  // Prefill from the logged-in user.
  useEffect(() => {
    if (user) {
      setForm((f) => ({
        ...f,
        name: user.name || f.name,
        email: user.email || f.email,
      }));
    }
  }, [user]);

  const handleChange = (e) =>
    setForm({ ...form, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.name || !form.email || !form.subject || !form.message) {
      showToast("Please fill in all fields.", "warning");
      return;
    }
    setSubmitting(true);
    try {
      const res = await supportAPI.createTicket(form);
      setLastTicketId(res.ticket_id);
      showToast(
        `Message sent! Your ticket #${res.ticket_id} has been created.`,
        "success"
      );
      setForm((f) => ({ ...f, subject: "", message: "", priority: "medium" }));
    } catch (err) {
      showToast(err.message || "Failed to send message.", "error");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="bg-background">
      <div className="container mx-auto px-6 py-16">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-text-primary">Get In Touch</h1>
          <p className="text-lg text-text-secondary mt-2">
            We'd love to hear from you.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-start">
          <div className="space-y-8">
            <div>
              <h3 className="text-xl font-semibold text-primary flex items-center gap-3">
                <i className="fas fa-map-marker-alt"></i> Address
              </h3>
              <p className="text-text-secondary mt-2">
                123 Electronics Ave, Dallas, Texas, 75201, USA
              </p>
            </div>
            <div>
              <h3 className="text-xl font-semibold text-primary flex items-center gap-3">
                <i className="fas fa-phone"></i> Phone
              </h3>
              <p className="text-text-secondary mt-2">+1 (123) 456-7890</p>
            </div>
            <div>
              <h3 className="text-xl font-semibold text-primary flex items-center gap-3">
                <i className="fas fa-envelope"></i> Email
              </h3>
              <p className="text-text-secondary mt-2">support@brightbuy.com</p>
            </div>

            {user && (
              <div className="bg-card border border-card-border rounded-lg p-4">
                <p className="text-sm text-text-secondary">
                  <i className="fas fa-circle-info text-primary mr-2"></i>
                  You're signed in — track replies to your requests under{" "}
                  <Link
                    href="/profile/help"
                    className="text-primary font-medium hover:underline"
                  >
                    My Support Tickets
                  </Link>
                  .
                </p>
              </div>
            )}
          </div>

          <div className="bg-card p-8 rounded-lg shadow-md border border-card-border">
            <form className="space-y-4" onSubmit={handleSubmit}>
              <div>
                <label
                  htmlFor="name"
                  className="block text-sm font-medium text-text-secondary mb-1"
                >
                  Your Name
                </label>
                <input
                  type="text"
                  id="name"
                  name="name"
                  value={form.name}
                  onChange={handleChange}
                  className="w-full p-3 bg-background border border-card-border rounded-md text-text-primary"
                />
              </div>
              <div>
                <label
                  htmlFor="email"
                  className="block text-sm font-medium text-text-secondary mb-1"
                >
                  Your Email
                </label>
                <input
                  type="email"
                  id="email"
                  name="email"
                  value={form.email}
                  onChange={handleChange}
                  className="w-full p-3 bg-background border border-card-border rounded-md text-text-primary"
                />
              </div>
              <div>
                <label
                  htmlFor="subject"
                  className="block text-sm font-medium text-text-secondary mb-1"
                >
                  Subject
                </label>
                <input
                  type="text"
                  id="subject"
                  name="subject"
                  value={form.subject}
                  onChange={handleChange}
                  placeholder="e.g. Question about my order"
                  className="w-full p-3 bg-background border border-card-border rounded-md text-text-primary"
                />
              </div>
              <div>
                <label
                  htmlFor="priority"
                  className="block text-sm font-medium text-text-secondary mb-1"
                >
                  Priority
                </label>
                <select
                  id="priority"
                  name="priority"
                  value={form.priority}
                  onChange={handleChange}
                  className="w-full p-3 bg-background border border-card-border rounded-md text-text-primary"
                >
                  <option value="low">Low</option>
                  <option value="medium">Medium</option>
                  <option value="high">High</option>
                </select>
              </div>
              <div>
                <label
                  htmlFor="message"
                  className="block text-sm font-medium text-text-secondary mb-1"
                >
                  Message
                </label>
                <textarea
                  id="message"
                  name="message"
                  rows="5"
                  value={form.message}
                  onChange={handleChange}
                  className="w-full p-3 bg-background border border-card-border rounded-md text-text-primary"
                ></textarea>
              </div>
              <button
                type="submit"
                disabled={submitting}
                className="w-full bg-secondary text-white py-3 rounded-md font-semibold hover:bg-opacity-90 disabled:opacity-60 flex items-center justify-center gap-2"
              >
                {submitting ? (
                  <>
                    <i className="fas fa-spinner fa-spin"></i> Sending...
                  </>
                ) : (
                  "Send Message"
                )}
              </button>

              {lastTicketId && (
                <p className="text-sm text-green-600 dark:text-green-400 text-center">
                  <i className="fas fa-check-circle mr-1"></i>
                  Ticket #{lastTicketId} created. We'll get back to you soon.
                </p>
              )}
            </form>
          </div>
        </div>
      </div>
    </div>
  );
}
