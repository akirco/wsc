Write-Host @"
╔════════════════════╗
║░        wsc       ░║
╚════════════════════╝
Usage: wsc -sqrmfy [<args>] -hv

   -s, -style             select [(l|light)|(m|mono)(p|paper)]
   -q, -query             input starting search query
   -r, -repository        browse a specific repo [core|extra|community|aur]
   -m, -margin            set the margin 10|2,5|5,3,8|1,5,2,3
   -h, -help              show this help
   -v, -version           get lsparu version

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
