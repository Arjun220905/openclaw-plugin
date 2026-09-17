/**
 * Native OpenClaw runtime entry point.
 *
 * The durable capabilities for this plugin are declared in
 * openclaw.plugin.json: native skill roots and the hosted MeetStream MCP
 * server. Keeping this runtime deliberately side-effect free means loading it
 * cannot create, remove, or alter a meeting bot; state-changing operations
 * remain explicit agent tool/script actions with the existing guardrails.
 */
export default {
  id: "openclaw-x-meetstream-skill",
  name: "MeetStream",
  description: "Native OpenClaw runtime for the MeetStream skills and MCP server.",
  register() {}
};
