vim9script

import autoload 'qline/config.vim'
import autoload './colorscheme.vim'

var previewWinId: number = 0

export def Start()
  const currentScheme = config.Get('colorscheme')

  const menuheight = min([20, &lines - 9])
  const winid = popup_menu(colorscheme.GetList(null_string, null_string, 0)->split("\n"), {
    maxheight: menuheight,
    pos: 'topleft',
    line: (&lines - 9 - menuheight) / 2 + 1,
    filter: Filter,
    callback: (id: number, result: number) => {
      if result < 0
        execute 'QlineColorscheme' currentScheme
      else
        echo 'QlineColorscheme' config.Get('colorscheme')
      endif
      popup_close(getwinvar(id, 'previewWinId'))
    },
  })
  setwinvar(winid, 'previewWinId', OpenPreview(winid))
  win_execute(winid, $'search("\V\C\^{currentScheme}\$", "c")')
  win_execute(winid, 'normal! z.')
enddef


def Filter(id: number, key: string): bool
  popup_filter_menu(id, key)
  if winbufnr(id) > 0
    execute 'QlineColorscheme' getbufoneline(winbufnr(id), line('.', id))
    UpdateHighlight()
  endif
  return true
enddef


def OpenPreview(parentId: number): number
  const modeText = {
    normal:      'NORMAL',
    insert:      'INSERT',
    visual:      'VISUAL',
    replace:     'REPLAC',
    terminal:    'TERMNL',
    commandline: 'CMDLIN',
    inactive:    'INACTV',
  }

  final showcaseText: list<string> = []
  for modename in ['normal', 'insert', 'visual', 'replace', 'terminal', 'commandline', 'inactive']
    showcaseText->add($' {modeText[modename]}  left1  left2    middle    right2  right1  right0 ')
  endfor

  const parentPos = popup_getpos(parentId)
  const winid = popup_create(showcaseText, {
    line: parentPos.line + parentPos.height,
    maxheight: 7,
    highlight: 'Normal',
  })

  for modename in ['normal', 'insert', 'visual', 'replace', 'terminal', 'commandline', 'inactive']
    var hl: string = colorscheme.GetHighlight(modename, 'left0')[2 : -2]
    matchadd(hl, $'^ {modeText[modename]} ', 10, -1, {window: winid})
    for tiername in ['left1', 'left2', 'right2', 'right1', 'right0']
      hl = colorscheme.GetHighlight(modename, tiername)[2 : -2]
      matchadd(hl, $'^ {modeText[modename]} .*\zs {tiername} \ze', 10, -1, {window: winid})
    endfor
    hl = colorscheme.GetHighlight(modename, 'middle')[2 : -2]
    matchadd(hl, $'^ {modeText[modename]} .*\zs   middle   \ze', 10, -1, {window: winid})
  endfor

  return winid
enddef


def UpdateHighlight()
  for modename in ['normal', 'insert', 'visual', 'replace', 'terminal', 'commandline', 'inactive']
    colorscheme.GetHighlight(modename, 'left0')[2 : -2]
    for tiername in ['left1', 'left2', 'middle', 'right2', 'right1', 'right0']
      colorscheme.GetHighlight(modename, tiername)[2 : -2]
    endfor
  endfor
enddef


# vim: et sw=2 sts=-1
