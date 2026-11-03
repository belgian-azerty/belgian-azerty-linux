import gi; gi.require_version('CinnamonDesktop','3.0'); from gi.repository import CinnamonDesktop
for loc in ['nl_BE','fr_BE','de_BE','wa_BE','li_BE','en_US','nl_NL','de_DE','fr_FR']:
    print(loc, CinnamonDesktop.get_input_source_from_locale(loc))
