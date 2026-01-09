{ config, pkgs, ... }:

{
  # Claude Code MCP server configuration
  home.file.".mcp.json".source = ../config/mcp.json;
}
