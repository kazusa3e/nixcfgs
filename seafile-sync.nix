{
  lib,
  pkgs,
  ...
}:

let
  containerName = "seafile-sync";
  imageName = "localhost/seafile-sync";
  imageTag = "nix";
  imageRef = "${imageName}:${imageTag}";
  stateVolume = "seafile-sync-state";
  syncDirectory = "/home/kazusa/Seafile";
  initClient = pkgs.writeShellScriptBin "seafile-sync-init" (
    builtins.readFile ./seafile-sync-init.sh
  );

  # Cloudflare's Browser Integrity Check rejects urllib's default User-Agent.
  seafileShared = pkgs.seafile-shared.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace app/seaf-cli \
        --replace-fail \
          '    headers = headers or {}' \
          $'    headers = headers or {}\n    headers.setdefault("User-Agent", "Seafile-CLI/${old.version}")'
    '';
  });

  startClient = pkgs.writeShellScript "start-seafile-sync" ''
    set -eu
    umask 077

    if [ ! -f /state/.ccnet/seafile.ini ]; then
      ${seafileShared}/bin/seaf-cli init -c /state/.ccnet -d /state
    fi

    exec ${seafileShared}/bin/seaf-daemon \
      -c /state/.ccnet \
      -d /state/seafile-data \
      -w /state/seafile
  '';

  image = pkgs.dockerTools.buildLayeredImage {
    name = imageName;
    tag = imageTag;
    contents = [
      seafileShared
      pkgs.dockerTools.fakeNss
      pkgs.dockerTools.binSh
      pkgs.dockerTools.usrBinEnv
      pkgs.dockerTools.caCertificates
    ];
    config = {
      Cmd = [ "${startClient}" ];
      Env = [
        "HOME=/state"
        "PATH=${
          lib.makeBinPath [
            seafileShared
            pkgs.coreutils
            pkgs.bash
          ]
        }"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "PYTHONDONTWRITEBYTECODE=1"
      ];
    };
  };
in
{
  users.users.kazusa.linger = true;
  users.users.kazusa.packages = [ initClient ];

  systemd.tmpfiles.rules = [
    "d ${syncDirectory} 0700 kazusa users - -"
  ];

  systemd.user.services.seafile-sync = {
    description = "Seafile file sync in rootless Podman";
    wantedBy = [ "default.target" ];
    unitConfig.ConditionUser = "kazusa";
    serviceConfig = {
      Type = "exec";
      Restart = "always";
      RestartSec = 10;
      TimeoutStartSec = "10min";
      ExecStartPre = [
        "${pkgs.podman}/bin/podman load -i ${image}"
        "${pkgs.podman}/bin/podman volume create --ignore ${stateVolume}"
      ];
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.podman}/bin/podman run"
        "--rm"
        "--replace"
        "--name ${containerName}"
        "--hostname arashi-seafile"
        "--cap-drop=ALL"
        "--security-opt=no-new-privileges"
        "--read-only"
        "--tmpfs /tmp:rw,nosuid,nodev"
        "--volume ${stateVolume}:/state:rw"
        "--volume ${syncDirectory}:/sync:rw"
        imageRef
      ];
      ExecStop = "${pkgs.podman}/bin/podman stop --ignore --time 10 ${containerName}";
    };
  };
}
