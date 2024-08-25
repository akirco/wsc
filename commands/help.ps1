Write-Host @"
╔════════════════════╗
║░        wsc       ░║
╚════════════════════╝
Usage: wsc si/su [<args>]

   si  [-s/--skip]        install app with scoop
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
"@
