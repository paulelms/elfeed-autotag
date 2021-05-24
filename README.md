# elfeed-autotag

Easy auto-tagging for elfeed-protocol (and elfeed in general).  
Thanks to [elfeed-org](https://github.com/remyhonig/elfeed-org "elfeed-org") by Remy Honig for starting point.

I just wanted to overlay elfeed-org config on elfeed-protocol, but with some changes in how the rules work.

## Supported rules

- those thar are in elfeed-org
  - feed renaming
  - headline tags (converted to tags, but do not generate subscriptions for elfeed)
  - `entry-title: \(emacs\|org-mode\)`
- tag rules for feed url like `feed-url: reddit.com :reddit:`

## Documentation WIP

### TODO

- learn how to test emacs-lisp code (ert, xtest)
- explore possibility to sync tags via elfeed-protocol
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
