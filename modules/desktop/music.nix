# I create "music" (with no experience whatsoever) so here's my "music" workflow.
{ config, options, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.desktop.music;
in {
  options.modules.desktop.music = 
    let mkBoolDefault = bool: mkOption {
      type = types.bool;
      default = bool;
    }; in {
      composition.enable = mkBoolDefault false;
      production.enable = mkBoolDefault false;
    };

  config = {
    my.packages = with pkgs;
      (if cfg.composition.enable then [
        lilypond            # Prevent your compositions to be forever lost when you're in grave by engraving them now (or whenever you feel like it).
        musescore           # A music composer for creating musical cheatsheets.
        soundfont-fluid     # A soundfont for it or something.
        sonic-pi            # A pie made up of them supersonic sounds created from electricity.
        supercollider       # Programming platform for synthesizing them 'zics.
      ] else []) ++

      (if cfg.production.enable then [
        ardour      # A DAW focuses on hardware recording but it can be used for something else.
        audacity    # Belongs in the great city of "Simple tools for short audio samples".
        carla       # A plugin host useful for a consistent hub for them soundfonts and SFZs.
        fluidsynth  # Synth for fluid sounds.
        geonkick    # Create them percussions.
        helm        # A great synthesizer plugin.
        hydrogen    # Them drum beats composition will get good.
        polyphone   # Edit your fonts for sound.
        #zrythm      # An up-and-coming DAW in Linux town.
        zynaddsubfx # Ze most advanced synthesizer I've seen so far (aside from the upcoming Vital syntehsizer).

        # As of 2020-07-03, lmms has some trouble regarding Qt or something so at least use the "unstable" channel just to be safe.
        # lmms
      ] else []);
  };
}
