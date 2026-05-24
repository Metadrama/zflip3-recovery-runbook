# Notes

This repo is for the Samsung Galaxy Z Flip 3 SM-F711B damaged-screen headless-server path.

Keep the main README guide linear. Do not insert explanatory headers into the step-by-step flow. If a step needs explanation, mark it with a counted star like [*2] and explain it in the appendix.

Use definitive instructions. Avoid soft phrasing like "if you want" or "that works for me" in the operational path. When a step is conditional, state the condition and the required action.

The recovery mission is authorized ADB plus bootable Android. The infrastructure mission is a 24/7 headless server with root SSH, Tailscale, Termux or Debian chroot, Hermes/OpenClaw runtime support, boot persistence, power management, and health checks.

It is acceptable to SSH into the PC and use ADB against the phone for study or verification when the phone is connected.
