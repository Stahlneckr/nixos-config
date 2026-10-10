{ pkgs, ... }:

{
  services.restic.backups.nsnix = {
    repository = "s3:https://s3.us-west-002.backblazeb2.com/nsnix-restic-backups";

    # Runtime files only: never embed credentials or passwords in the Nix store.
    environmentFile = "/var/lib/restic/b2.env";
    passwordFile = "/var/lib/restic/password";
    user = "root";

    # Shared multimedia is backed up elsewhere; do not include /data/shared.
    paths = [
      "/home/nick"
      "/data/linux"
    ];

    exclude = [
      "/home/nick/.cache"
      "/home/nick/.local/share/Trash"
      "/home/nick/.npm/_cacache"

      # Downloaded tools and caches, not sessions, skills, or settings.
      "/home/nick/.codex/packages"
      "/home/nick/.codex/cache"
      "/home/nick/.codex/.tmp"
      "/home/nick/.codex/tmp"
      "/home/nick/.codex/plugins/cache"

      # Keep Steam userdata and Proton prefixes, which can contain saves.
      "/home/nick/.local/share/Steam/steamapps/common"
      "/home/nick/.local/share/Steam/steamapps/downloading"
      "/home/nick/.local/share/Steam/steamapps/shadercache"
      "/data/linux/SteamLibrary/steamapps/common"
      "/data/linux/SteamLibrary/steamapps/downloading"
      "/data/linux/SteamLibrary/steamapps/shadercache"
    ];

    extraBackupArgs = [ "--one-file-system" "--exclude-caches" ];

    # This volume uses nofail at boot: never silently back up a bare mountpoint.
    backupPrepareCommand = ''
      #!${pkgs.runtimeShell}
      if ! ${pkgs.util-linux}/bin/mountpoint -q /data/linux; then
        echo "Refusing backup: /data/linux is not mounted." >&2
        exit 1
      fi
    '';

    # Local time (America/New_York); catch up missed runs without waking the PC.
    timerConfig = {
      OnCalendar = "Sun *-*-* 18:00:00";
      Persistent = true;
      WakeSystem = false;
    };
    initialize = false;

    # Applies to this host's snapshots in the dedicated Restic bucket only.
    # Manual backups use the same retention policy as scheduled backups.
    pruneOpts = [
      "--host nsnix"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];

    # Check repository structure after each successful backup.
    runCheck = true;
    createWrapper = true;
  };

  systemd.services.restic-backups-nsnix.unitConfig.RequiresMountsFor = [
    "/home/nick"
    "/data/linux"
  ];
}
