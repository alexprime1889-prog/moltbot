/**
 * Kernel Browser Integration
 *
 * Creates cloud browsers via Kernel SDK (https://onkernel.com)
 * Returns CDP URL for Playwright and Live View URL for users.
 */
import Kernel from "@onkernel/sdk";
import { createSubsystemLogger } from "../logging/subsystem.js";
const log = createSubsystemLogger("browser").child("kernel");
// Active sessions cache for cleanup
const activeSessions = new Map();
// Kernel client singleton
let kernelClient = null;
function getKernelClient() {
    if (!kernelClient) {
        const apiKey = process.env.KERNEL_API_KEY;
        if (!apiKey) {
            throw new Error("KERNEL_API_KEY environment variable is required for Kernel browser integration");
        }
        kernelClient = new Kernel();
    }
    return kernelClient;
}
/**
 * Create a cloud browser via Kernel SDK.
 *
 * @returns Browser session with CDP URL and Live View URL
 */
export async function createKernelBrowser(options = {}) {
    const kernel = getKernelClient();
    const { profileName, saveProfileChanges = false, initialUrl, timeoutSeconds = 900, // 15 minutes default
    viewportWidth = 1920, viewportHeight = 1080, recording = false, } = options;
    log.info(`Creating Kernel browser${profileName ? ` with profile "${profileName}"` : ""} (recording: ${recording})`);
    // Build browser create params
    const browserParams = {
        timeout_seconds: timeoutSeconds,
        headless: false, // Live View requires headed mode
        stealth: true,
        viewport: {
            width: viewportWidth,
            height: viewportHeight,
        },
    };
    // Add profile if specified
    if (profileName) {
        browserParams.profile = {
            name: profileName,
            save_changes: saveProfileChanges,
        };
    }
    const browser = await kernel.browsers.create(browserParams);
    const sessionId = browser.session_id;
    const cdpWsUrl = browser.cdp_ws_url;
    const liveViewUrl = browser.browser_live_view_url ?? "";
    if (!cdpWsUrl) {
        throw new Error("Kernel browser creation failed: no CDP URL returned");
    }
    log.info(`Kernel browser created: ${sessionId}`);
    log.debug(`CDP URL: ${cdpWsUrl}`);
    log.info(`Live View URL: ${liveViewUrl}`);
    // Start recording if enabled
    let replayId;
    if (recording) {
        try {
            const recordingResult = await kernel.browsers.replays.start(sessionId);
            replayId = recordingResult.replay_id;
            log.info(`Recording started: ${replayId}`);
        }
        catch (err) {
            log.warn(`Failed to start recording: ${err}`);
        }
    }
    // Navigate to initial URL if provided
    if (initialUrl) {
        try {
            // Use Playwright to navigate (via CDP)
            const { chromium } = await import("playwright-core");
            const browserConn = await chromium.connectOverCDP(cdpWsUrl, { timeout: 30000 });
            const context = browserConn.contexts()[0] ?? (await browserConn.newContext());
            const page = context.pages()[0] ?? (await context.newPage());
            await page.goto(initialUrl, { timeout: 30000, waitUntil: "domcontentloaded" });
            log.info(`Navigated to: ${initialUrl}`);
        }
        catch (err) {
            log.warn(`Failed to navigate to initial URL: ${err}`);
        }
    }
    const session = {
        sessionId,
        cdpWsUrl,
        liveViewUrl,
        replayId,
        stopRecording: recording && replayId
            ? async () => {
                try {
                    await kernel.browsers.replays.stop(replayId, { id: sessionId });
                    // Get replay list to find the URL
                    const replays = await kernel.browsers.replays.list(sessionId);
                    const replay = replays.find((r) => r.replay_id === replayId);
                    const replayUrl = replay?.replay_view_url ?? null;
                    log.info(`Recording stopped. Replay URL: ${replayUrl}`);
                    return replayUrl;
                }
                catch (err) {
                    log.warn(`Failed to stop recording: ${err}`);
                    return null;
                }
            }
            : undefined,
        close: async () => {
            try {
                // Stop recording if active
                if (recording && replayId) {
                    await kernel.browsers.replays.stop(replayId, { id: sessionId }).catch(() => { });
                }
                // Delete browser session
                await kernel.browsers.deleteByID(sessionId);
                activeSessions.delete(sessionId);
                log.info(`Kernel browser closed: ${sessionId}`);
            }
            catch (err) {
                log.warn(`Failed to close Kernel browser: ${err}`);
            }
        },
    };
    activeSessions.set(sessionId, session);
    return session;
}
/**
 * Get active Kernel browser session by ID.
 */
export function getKernelSession(sessionId) {
    return activeSessions.get(sessionId);
}
/**
 * List all active Kernel browser sessions.
 */
export function listKernelSessions() {
    return Array.from(activeSessions.values());
}
/**
 * Close all active Kernel browser sessions.
 */
export async function closeAllKernelSessions() {
    const sessions = Array.from(activeSessions.values());
    await Promise.allSettled(sessions.map((s) => s.close()));
    activeSessions.clear();
    log.info(`Closed ${sessions.length} Kernel browser sessions`);
}
/**
 * Check if Kernel API key is configured.
 */
export function isKernelConfigured() {
    return Boolean(process.env.KERNEL_API_KEY);
}
