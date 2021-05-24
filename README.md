# elfeed-autotag

[![MELPA](http://melpa.org/packages/elfeed-autotag-badge.svg)](http://melpa.org/#/elfeed-autotag) [![MELPA Stable](https://stable.melpa.org/packages/elfeed-autotag-badge.svg)](https://stable.melpa.org/#/elfeed-autotag)

Easy auto-tagging for elfeed-protocol (and elfeed in general).  
Thanks to [elfeed-org](https://github.com/remyhonig/elfeed-org "elfeed-org") by Remy Honig for starting point.

Elfeed-autotag overlays configuration in elfeed-org style on elfeed-protocol feeds.

## Supported rules

- those that are in elfeed-org
  - feed renaming
  - headline tags (converted to tags, but do not generate subscriptions for elfeed)
  - `entry-title: \(emacs\|org-mode\)`
- tag rules for feed url like `feed-url: reddit.com :reddit:`

## Documentation WIP

### TODO

- learn how to test emacs-lisp code (ert, xtest)
- automate elfeed-protocol detection
- feed url escaping for `elfeed-make-tagger`
- explore possibility to sync tags via elfeed-protocol
- it might be better set autotags property for elfeed-protocol instead of modifying entries
- (maybe) support for more than one elfeed-protocol source and more complex configurations
- considering (according to `elfeed-make-tagger` function):
  - tag rules for entry link like `entry-link: <url> :tag:`
  - tag rules for feed title
  - after/before tag rules
  - tag remove

### init

``` emacs-lisp
(require 'elfeed-autotag)
(elfeed-autotag)
```
