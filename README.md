# elfeed-autotag

[![MELPA](http://melpa.org/packages/elfeed-autotag-badge.svg)](http://melpa.org/#/elfeed-autotag)
[![MELPA Stable](https://stable.melpa.org/packages/elfeed-autotag-badge.svg)](https://stable.melpa.org/#/elfeed-autotag)
![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/paulelms/elfeed-autotag)

Easy auto-tagging for elfeed-protocol (and elfeed in general).  
Thanks to [elfeed-org](https://github.com/remyhonig/elfeed-org "elfeed-org") by Remy Honig for starting point.

Elfeed-autotag overlays configuration in elfeed-org style on elfeed-protocol feeds. The difference from elfeed-org is that autotag does not set up its own feed tree, it only applies the rules. In addition, since all feeds are not fully described in the org file, url matching was added.

## Supported rules

- those that are in elfeed-org
  - feed renaming
  - headline tags (converted to tags, but do not generate subscriptions for elfeed)
  - `entry-title: \(emacs\|org-mode\)`
- tag rules for feed url like `feed-url: reddit.com :reddit:`

## Documentation

### init

``` emacs-lisp
(require 'elfeed-autotag)
(setq pvv-elfeed-autotag-files '("~/org/elfeed.org")
      pvv-elfeed-autotag-protocol-used t)
(elfeed-autotag)
```

### Example feed rules

``` org
* feeds :elfeed:
** Reddit :reddit:
*** feed-url: reddit.com
*** [[https://www.reddit.com/r/listentothis/.rss][Listen To This]] :music:
feed renaming
** Emacs :emacs:
*** entry-title: \(emacs\|org-mode\)
*** https://planet.emacslife.com/atom.xml :mustread:
```

### How to update old entries when configuration changed

By default autotag only runs on new entries. You can add new tags to old posts with `M-x elfeed-apply-hooks-now`, but this will not remove the redundant tags (you can do it by hands). I will think about more complete synchronization of the configuration with the actual elfeed database.

``` emacs-lisp
(elfeed-apply-hooks-now)
```

### TODO

- learn how to test emacs-lisp code (ert, xtest)
- (maybe) better deal with elfeed-protocol dependency
- automate elfeed-protocol detection
- feed url escaping for `elfeed-make-tagger`
- explore possibility to sync tags via elfeed-protocol
- ~~it might be better set autotags property for elfeed-protocol instead of modifying entries~~
- (maybe) support for more than one elfeed-protocol source and more complex configurations
- considering (according to `elfeed-make-tagger` function):
  - tag rules for entry link like `entry-link: <url> :tag:`
  - tag rules for feed title
  - after/before tag rules
  - tag remove
