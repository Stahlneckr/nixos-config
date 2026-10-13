{ ... }:

{
  services.tailscale = {
    enable = true;
    # Allow direct WireGuard connections to other tailnet devices.
    openFirewall = true;
    # Serve SSH on the tailnet using Tailscale identity and access policies.
    extraSetFlags = [ "--ssh" ];
  };
}
