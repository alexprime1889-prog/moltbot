/**
 * Kernel Browser Integration Tests
 */

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import {
  createKernelBrowser,
  getKernelSession,
  listKernelSessions,
  closeAllKernelSessions,
  isKernelConfigured,
  type KernelBrowserSession,
} from "./kernel.js";

// Skip tests if KERNEL_API_KEY is not set
const SKIP_REASON = !process.env.KERNEL_API_KEY
  ? "KERNEL_API_KEY not set - skipping live tests"
  : undefined;

describe("Kernel Browser Integration", () => {
  describe("isKernelConfigured", () => {
    it("returns true when KERNEL_API_KEY is set", () => {
      const hasKey = Boolean(process.env.KERNEL_API_KEY);
      expect(isKernelConfigured()).toBe(hasKey);
    });
  });

  describe.skipIf(SKIP_REASON)("Live browser tests", () => {
    let session: KernelBrowserSession | null = null;

    afterAll(async () => {
      // Cleanup any sessions
      await closeAllKernelSessions();
    });

    it("creates a Kernel browser session", async () => {
      session = await createKernelBrowser({
        timeoutSeconds: 60, // Short timeout for test
        viewportWidth: 1920,
        viewportHeight: 1080,
      });

      expect(session).toBeDefined();
      expect(session.sessionId).toBeTruthy();
      expect(session.cdpWsUrl).toMatch(/^wss?:\/\//);
      expect(session.liveViewUrl).toBeTruthy();

      console.log("Session ID:", session.sessionId);
      console.log("CDP URL:", session.cdpWsUrl);
      console.log("Live View URL:", session.liveViewUrl);
    }, 30000);

    it("can retrieve session by ID", () => {
      if (!session) return;

      const retrieved = getKernelSession(session.sessionId);
      expect(retrieved).toBeDefined();
      expect(retrieved?.sessionId).toBe(session.sessionId);
    });

    it("lists active sessions", () => {
      const sessions = listKernelSessions();
      expect(sessions.length).toBeGreaterThan(0);

      if (session) {
        const found = sessions.find((s) => s.sessionId === session!.sessionId);
        expect(found).toBeDefined();
      }
    });

    it("connects to browser via CDP and navigates", async () => {
      if (!session) return;

      const { chromium } = await import("playwright-core");
      const browser = await chromium.connectOverCDP(session.cdpWsUrl, {
        timeout: 15000,
      });

      const context = browser.contexts()[0] ?? (await browser.newContext());
      const page = context.pages()[0] ?? (await context.newPage());

      await page.goto("https://example.com", {
        timeout: 15000,
        waitUntil: "domcontentloaded",
      });

      const title = await page.title();
      expect(title).toContain("Example");

      console.log("Page title:", title);
      console.log("Page URL:", page.url());
    }, 30000);

    it("closes session", async () => {
      if (!session) return;

      await session.close();

      // Session should be removed from cache
      const retrieved = getKernelSession(session.sessionId);
      expect(retrieved).toBeUndefined();
    }, 15000);
  });
});
