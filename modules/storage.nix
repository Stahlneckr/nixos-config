{ pkgs, ... }:

{
  # Data volumes on the 4 TB SN8100, not either 1 TB OS disk.
  # UUIDs stay stable even when Linux changes the NVMe device numbering.
  # A missing data drive must not prevent the OS disk from booting.
  fileSystems."/data/linux" = {
    device = "/dev/disk/by-uuid/f9b438f1-9f28-41f1-bfd3-8b96e98acaaa";
    fsType = "ext4";
    options = [ "noatime" "nofail" "x-systemd.device-timeout=10s" ];
  };

  fileSystems."/data/shared" = {
    device = "/dev/disk/by-uuid/0974920D0861A438";
    fsType = "ntfs3";
    # There is no fsck.ntfs3 helper; use Windows chkdsk if repair is needed.
    noCheck = true;
    options = [
      "noatime"
      "nofail"
      "x-systemd.device-timeout=10s"
      # The existing nick account has UID 1000; the users group has GID 100.
      "uid=1000"
      "gid=100"
      "fmask=0133"
      "dmask=0022"
      "windows_names"
      "nosuid"
      "nodev"
    ];
  };

  # Set ownership of the mounted ext4 root only, never recursively.
  # Ordering and the mount-point condition prevent changing the OS disk's
  # bare /data/linux directory if the data volume could not be mounted.
  systemd.services.data-linux-owner = {
    description = "Give nick ownership of the Linux data volume root";
    wantedBy = [ "multi-user.target" "data-linux.mount" ];
    after = [ "data-linux.mount" ];
    bindsTo = [ "data-linux.mount" ];
    unitConfig.ConditionPathIsMountPoint = "/data/linux";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/chown nick:users /data/linux";
    };
  };
}
