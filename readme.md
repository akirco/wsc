## wsc

Current Release 0.1.0

整合windows包管理器和fzf，借鉴于[lsparu](https://github.com/salkin-mada/lsparu)

目前状态：书写中,需要重新设计(移除s,su命令，完全通过fzf keybing 完成)，先这样写吧，fzf高级用法不是特别熟悉

## Usage

```
╔════════════════════╗
║░        wsc       ░║
╚════════════════════╝
Usage: wsc si/su [<args>]

   s  [-s/--skip]         install app with scoop
   su                     update scoop
   -h, -help              show this help
   -v, -version           get wsc version

   ctrl-space             toggle package
   ctrl-d                 deselect-all
   ctrl-l                 clear-query
   ctrl-p                 toggle-preview
   ctrl-w                 toggle-preview-wrap
   shift-up               preview-up
   shift-down             preview-down
   shift-left             preview-page-up
   shift-right            preview-page-down
   ctrl-s                 see package stats
   ctrl-u                 list updatable packages
   ctrl-n                 read the news
   ctrl-g                 get info about installed packages
   enter                  install package(s)
   esc                    leave, do nothing
   tab                    toggle package and move pointer down
   shift-tab              toggle package and move pointer up
   ctrl-h                 list keybindings (help)
```

## Requirements

- fzf
- scoop
- pwsh
- winget
- chocolatey

## Installation

```
scoop bucket add aki https://github.com/akirco/aki-apps.git
scoop install aki/wsc
```

