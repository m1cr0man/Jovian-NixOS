{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption types mdDoc escapeShellArg;
  inherit (types) nullOr;
  inherit (builtins) concatStringsSep attrValues removeAttrs;

  pairOf = typ: types.addCheck (types.listOf typ) (l: lib.lists.length == 2);
  ifSet = output: v: if v == null || v == false then "" else output;
  ts = builtins.toString;

  cfg = config.jovian.steam.gamescopeOptions;
in
{
  options.jovian.steam.gamescopeOptions = {
    finalArguments = mkOption {
      type = types.str;
      readOnly = true;
      default = let
        opts =
          (removeAttrs cfg ["finalArguments" "vr" "hdr"])
          // (removeAttrs cfg.vr ["overlay"])
          // cfg.vr.overlay
          // cfg.hdr;
        setOpts = builtins.filter (v: v != "") (attrValues opts);
      in concatStringsSep " " setOpts;
      description = mdDoc ''
        The resultant set of flags to gamescope
      '';
    };
    outputWidth = mkOption {
      type = types.ints.positive;
      default = 1280;
      description = mdDoc ''
        Output width
      '';
      apply = v: "--output-width ${ts v}";
    };
    outputHeight = mkOption {
      type = types.ints.positive;
      default = 800;
      description = mdDoc ''
        Output height
      '';
      apply = v: "--output-height ${ts v}";
    };
    nestedRefresh = mkOption {
      type = nullOr types.ints.positive;
      default = null;
      description = mdDoc ''
        Game refresh rate (frames per second)
      '';
      apply = v: ifSet "--nested-refresh ${ts v}" v;
    };
    nestedWidth = mkOption {
      type = nullOr types.ints.positive;
      default = null;
      description = mdDoc ''
        Game width
      '';
      apply = v: ifSet "--nested-width ${ts v}" v;
    };
    nestedHeight = mkOption {
      type = nullOr types.ints.positive;
      default = null;
      description = mdDoc ''
        Game height
      '';
      apply = v: ifSet "--nested-height ${ts v}" v;
    };
    maxScale = mkOption {
      type = types.ints.unsigned;
      default = 2;
      description = mdDoc ''
        Maximum scale factor
      '';
      apply = v: "--max-scale ${ts v}";
    };
    scaler = mkOption {
      type = nullOr (types.enum [
        "auto"
        "integer"
        "fit"
        "fill"
        "stretch"
      ]);
      default = null;
      description = mdDoc ''
        Upscaler type
      '';
      apply = v: ifSet "--scaler ${v}" v;
    };
    filter = mkOption {
      type = nullOr (types.enum [
        "linear"
        "nearest"
        "fsr"
        "nis"
      ]);
      default = null;
      description = mdDoc ''
        Upscaler filter.

        - fsr => AMD FidelityFX™ Super Resolution 1.0
        - nis => NVIDIA Image Scaling v1.0.3
      '';
      apply = v: ifSet "--filter ${v}" v;
    };
    sharpness = mkOption {
      type = nullOr (types.ints.between 0 20);
      default = null;
      description = mdDoc ''
        Upscaler sharpness, specifically FSR sharpness.
        The MAX value is 0, and the MIN value is 20.
      '';
      apply = v: ifSet "--sharpness ${ts v}" v;
    };
    exposeWayland = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        support wayland clients using xdg-shell
      '';
      apply = ifSet "--expose-wayland";
    };
    headless = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        use headless backend (no window, no DRM output)
      '';
      apply = ifSet "--headless";
    };
    cursor = mkOption {
      type = types.pathInStore;
      default = "${pkgs.steamdeck-hw-theme}/share/steamos/steamos-cursor.png";
      description = mdDoc ''
        path to default cursor image
      '';
      apply = v: "--cursor ${escapeShellArg v}";
    };
    readyFd = mkOption {
      type = nullOr types.path;
      default = null;
      description = mdDoc ''
        notify FD when ready
      '';
      apply = v: ifSet "--ready-fd ${escapeShellArg v}" v;
    };
    realtimeScheduling = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Use realtime scheduling
      '';
      apply = ifSet "--rt";
    };
    statsPath = mkOption {
      type = nullOr types.path;
      default = null;
      description = mdDoc ''
        Write statistics to path
      '';
      apply = v: ifSet "--stats-path ${escapeShellArg v}" v;
    };
    hideCursorDelay = mkOption {
      type = types.int;
      default = 3000;
      description = mdDoc ''
        hide cursor image after delay
      '';
      apply = v: ifSet "--hide-cursor-delay ${ts v}" v;
    };
    enableSteam = mkOption {
      type = types.bool;
      default = true;
      description = mdDoc ''
        enable Steam integration
      '';
      apply = ifSet "--steam";
    };
    xwaylandCount = mkOption {
      type = types.int;
      default = 2;
      description = mdDoc ''
        create N xwayland servers
      '';
      apply = v: ifSet "--xwayland-count ${ts v}" v;
    };
    preferVulkanDevice = mkOption {
      type = nullOr (pairOf types.ints.unsigned);
      default = null;
      description = mdDoc ''
        prefer Vulkan device for compositing (ex: 1002:7300)
      '';
      apply = v: ifSet "--prefer-vk-device ${concatStringsSep ":" v}" v;
    };
    forceOrientation = mkOption {
      type = nullOr (types.enum [
        "left"
        "right"
        "normal"
        "upsidedown"
      ]);
      default = null;
      description = mdDoc ''
        rotate the internal display
      '';
      apply = v: ifSet "--force-orientation ${v}" v;
    };
    forceWindowsFullscreen = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Force windows inside of gamescope to be the size of the nested display (fullscreen)
      '';
      apply = ifSet "--force-windows-fullscreen";
    };
    cursorScaleHeight = mkOption {
      type = nullOr types.ints.positive;
      default = null;
      description = mdDoc ''
        If specified, sets a base output height to linearly scale the cursor against.
      '';
      apply = v: ifSet "--cursor-scale-height ${ts v}" v;
    };
    hdr = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Enable HDR output (needs Gamescope WSI layer enabled for support from clients)
        '';
        apply = ifSet "--hdr-enabled";
      };
      sdrGamutWideness = mkOption {
        type = nullOr (types.numbers.between 0 1);
        default = null;
        description = mdDoc ''
          Set the 'wideness' of the gamut for SDR comment. 0 - 1.
        '';
        apply = v: ifSet "--sdr-gamut-wideness ${ts v}" v;
      };
      sdrContentNits = mkOption {
        type = nullOr types.ints.positive;
        default = null;
        description = mdDoc ''
          Set the luminance of SDR content in nits. Vendor default: 400 nits.
        '';
        apply = v: ifSet "--hdr-sdr-content-nits ${ts v}" v;
      };
      enableItm = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Enable SDR->HDR inverse tone mapping. Only works for SDR input.
        '';
        apply = ifSet "--hdr-itm-enable";
      };
      itmSdrNits = mkOption {
        type = nullOr (types.ints.between 0 1000);
        default = null;
        description = mdDoc ''
          Set the luminance of SDR content in nits used as the input for the inverse tone mapping process.
          Vendor Default: 100 nits, Max: 1000 nits
        '';
        apply = v: ifSet "--hdr-itm-sdr-nits ${ts v}" v;
      };
      itmTargetNits = mkOption {
        type = nullOr (types.ints.between 0 10000);
        default = null;
        description = mdDoc ''
          Set the target luminace of the inverse tone mapping process.
          Default: 1000 nits, Max: 10000 nits
        '';
        apply = v: ifSet "--hdr-itm-target-nits ${ts v}" v;
      };
      debugForceSupport = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          forces support for HDR, etc even if the display doesn't support it.
          HDR clients will be outputted as SDR still in that case.
        '';
        apply = ifSet "--hdr-debug-force-support";
      };
      debugForceOutput = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          forces support and output to HDR10 PQ even if the output does not support it (will look very wrong if it doesn't)
        '';
        apply = ifSet "--hdr-debug-force-output";
      };
      debugHeatmap = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          displays a heatmap-style debug view of HDR luminence across the scene in nits.
        '';
        apply = ifSet "--hdr-debug-heatmap";
      };
    };
    framerateLimit = mkOption {
      type = types.ints.unsigned;
      default = 0;
      description = mdDoc ''
        Set a simple framerate limit. Used as a divisor of the refresh rate, rounds down eg 60 / 59 -> 60fps, 60 / 25 -> 30fps.
        Default: 0, disabled.
      '';
      apply = ifSet "--hdr-debug-heatmap";
    };
    nestedUnfocusedRefreshRate = mkOption {
      type = nullOr types.ints.positive;
      default = null;
      description = mdDoc ''
        game refresh rate when unfocused
      '';
      apply = v: ifSet "--nested-unfocused-refresh ${ts v}" v;
    };
    borderless = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        make the window borderless
      '';
      apply = ifSet "--borderless";
    };
    fullscreen = mkOption {
      type = types.bool;
      default = true;
      description = mdDoc ''
        make the window fullscreen
      '';
      apply = ifSet "--fullscreen";
    };
    grab = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        grab the keyboard
      '';
      apply = ifSet "--grab";
    };
    forceGrabCursor = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        always use relative mouse mode instead of flipping dependent on cursor visibility.
      '';
      apply = ifSet "--force-grab-cursor";
    };
    preferOutput = mkOption {
      type = types.listOf types.str;
      default = [ "*" "eDP-1" ];
      description = mdDoc ''
        List of connectors in order of preference, highest to lowest.
        Defaults to any external display, then the on board display.
      '';
      apply = v: "--prefer-output ${escapeShellArg (builtins.concatStringsSep "," v)}";
    };
    defaultTouchMode = mkOption {
      type = types.ints.between 0 4;
      default = 4;
      description = mdDoc ''
        - 0: hover
        - 1: left
        - 2: right
        - 3: middle
        - 4: passthrough
      '';
      apply = v: "--default-touch-mode ${ts v}";
    };
    generateDrmMode = mkOption {
      type = types.enum [
        "cvt"
        "fixed"
      ];
      default = "fixed";
      description = mdDoc ''
        DRM mode generation algorithm
      '';
      apply = v: "--generate-drm-mode ${v}";
    };
    immediateFlips = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Enable immediate flips, may result in tearing
      '';
      apply = ifSet "--immediate-flips";
    };
    adaptiveSync = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Enable adaptive sync if available (variable rate refresh)
      '';
      apply = ifSet "--adaptive-sync";
    };
    vr = {
      openvr = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Uses the openvr backend and outputs as a VR overlay
        '';
        apply = ifSet "--openvr";
      };
      scrollSpeed = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = mdDoc ''
          Mouse scrolling speed of trackpad scroll in VR. Vendor default: 8.0
        '';
        apply = v: ifSet "--vr-scrolls-speed ${ts v}" v;
      };
      overlay = {
        key = mkOption {
          type = nullOr types.str;
          default = null;
          description = mdDoc ''
            Sets the SteamVR overlay key to this string
          '';
          apply = v: ifSet "--vr-overlay-key ${escapeShellArg v}" v;
        };
        explicitName = mkOption {
          type = nullOr types.str;
          default = null;
          description = mdDoc ''
            Force the SteamVR overlay name to always be this string
          '';
          apply = v: ifSet "--vr-overlay-explicit-name ${escapeShellArg v}" v;
        };
        defaultName = mkOption {
          type = nullOr types.str;
          default = null;
          description = mdDoc ''
            Sets the fallback SteamVR overlay name when there is no window title
          '';
          apply = v: ifSet "--vr-overlay-default-name ${escapeShellArg v}" v;
        };
        icon = mkOption {
          type = nullOr types.path;
          default = null;
          description = mdDoc ''
            Sets the SteamVR overlay icon to this file
          '';
          apply = v: ifSet "--vr-overlay-icon ${escapeShellArg v}" v;
        };
        showImmediately = mkOption {
          type = types.bool;
          default = false;
          description = mdDoc ''
            Makes our VR overlay take focus immediately
          '';
          apply = ifSet "--vr-overlay-show-immediately";
        };
        enableControlBar = mkOption {
          type = types.bool;
          default = false;
          description = mdDoc ''
            Enables the SteamVR control bar
          '';
          apply = ifSet "--vr-overlay-enable-control-bar";
        };
        enableControlBarKeyboard = mkOption {
          type = types.bool;
          default = false;
          description = mdDoc ''
            Enables the SteamVR keyboard button on the control bar
          '';
          apply = ifSet "--vr-overlay-enable-control-bar-keyboard";
        };
        enableControlBarClose = mkOption {
          type = types.bool;
          default = false;
          description = mdDoc ''
            Enables the SteamVR close button on the control bar
          '';
          apply = ifSet "--vr-overlay-enable-control-bar-keyboard-close";
        };
        modal = mkOption {
          type = types.bool;
          default = false;
          description = mdDoc ''
            Makes our VR overlay appear as a modal
          '';
          apply = ifSet "--vr-overlay-modal";
        };
        physicalWidth = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
          description = mdDoc ''
            Sets the physical width of our VR overlay in metres
          '';
          apply = v: ifSet "--vr-overlay-physical-width ${ts v}" v;
        };
        physicalCurvature = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
          description = mdDoc ''
            Sets the curvature of our VR overlay
          '';
          apply = v: ifSet "--vr-overlay-physical-curvature ${ts v}" v;
        };
        physicalPreCurvePitch = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
          description = mdDoc ''
            Sets the pre-curve pitch of our VR overlay
          '';
          apply = v: ifSet "--vr-overlay-physical-pre-curve-pitch ${ts v}" v;
        };
      };
    };
    disableLayers = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        disable libliftoff (hardware planes)
      '';
      apply = ifSet "--disable-layers";
    };
    debugLayers = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        debug libliftoff
      '';
      apply = ifSet "--debug-layers";
    };
    debugFocus = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        debug XWM focus
      '';
      apply = ifSet "--debug-focus";
    };
    synchronousX11 = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        force X11 connection synchronization
      '';
      apply = ifSet "--synchronous-x11";
    };
    debugHUD = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        paint HUD with debug info
      '';
      apply = ifSet "--debug-hud";
    };
    debugEvents = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        debug X11 events
      '';
      apply = ifSet "--debug-events";
    };
    forceComposition = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        disable direct scan-out
      '';
      apply = ifSet "--force-composition";
    };
    compositeDebug = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        draw frame markers on alternating corners of the screen when compositing
      '';
      apply = ifSet "--composite-debug";
    };
    disableColorManagement = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        disable color management
      '';
      apply = ifSet "--disable-color-management";
    };
    disableXRes = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        disable XRes for PID lookup
      '';
      apply = ifSet "--disable-xres";
    };
    reshadeEffect = mkOption {
      type = nullOr types.str;
      default = null;
      description = mdDoc ''
        sets the name of a reshade shader to use in either
        ''${pkgs.gamescope}/share/gamescope/reshade/Shaders
        or ~/.local/share/gamescope/reshade/Shaders
      '';
      apply = v: ifSet "--reshade-effect ${escapeShellArg v}" v;
    };
    reshadeTechniqueIndex = mkOption {
      type = nullOr types.ints.positive;
      default = null;
      description = mdDoc ''
        sets technique idx to use from the reshade effect
      '';
      apply = v: ifSet "--reshade-technique-idx ${ts v}" v;
    };
  };
}
