% zstatus(1) zstatus version alpha1 | zstatus user's manual
% cmanv
% January 2026

# NAME

zstatus — a status bar for the zwm window manager

# SYNOPSIS

**zstatus** \[-c configfile\] \[-t theme\] \[-h\]

# DESCRIPTION

**zstatus** is a statusbar for ZWM written in Tcl/Tk and C.

# COMMAND LINE OPTIONS

**-c _configfile_**

> Use _configfile_ as the configuration file.

**-t _theme_**

> Specify the startup theme as either "dark" or "light". This can also be specified
trough the configuration file.

**-h**

> Print brief usage information.

# CONFIGURATION FILE

The configuration file (_$HOME/.config/zstatus/config_ by default)
has the general format:

> [section1]

> option1=value

> option2=value

> ..

>

> [section2]

> option1=value

> option2=value

## MAIN SECTION

These are the options can be specified in the __[main]__ section.

* __lang__

> Locale of the application. (Default: _env(LANG)_)

* __timezone__

> Select a timezone. (Default: _date +%Z_)

* __delay__

> Refresh frequency. (Default _2000_ milliseconds)

* __fontname__

> Font used for text. (Default: _Dejavu Sans_)

* __fontsize__

> Default font size. (Default: _12_)

* __emojifont__

> Font used for emojis.

* __geometry__

> Geometry of the status bar in the format _width_x_height_+_xpos_+_ypos_.

* __position__

> Whether the bar is position at the _top_ or the _bottom_ of the screen.
> (Default: _top_)

* __theme__

> Default theme. ('dark' or 'light')

* __leftside__

> List of widgets in the statusbar starting from the left. (Default: _desklayout separator desklist separator deskname separator wintitle_)
> Note: _separator_ can be abbreviated as _sep_.

* __rightside__

> List of widgets in the statusbar starting from the right. (Default: _datetime_)
> Note: _separator_ can be abbreviated as _sep_.

## COLOR SECTION

* __fg.light__

> Default foreground color in light mode.

* __fg.dark__

> Default foreground color in dark mode.

* __bg.light__

> Default background color in light mode.

* __bg.dark__

> Default background color in dark mode.

* __hi.light__

> Highlight color in light mode.

* __hi.dark__

> Highlight color in dark mode.

* __line.light__

> Line color in light mode.

* __line.dark__

> Line color in dark mode.

## WIDGETS SECTIONS

The list of valid widgets are:

> __datetime__, __desklayout__, __desklist__, __deskname__, __devices__,
>  __loadavg__, __mail__, __memused__, > __metar__, __mixer__, __music__,
> __netstat__, __separator__, __wintitle__

Each of these widgets can be customized with options:

- __[datetime]__: Shows current date and time in the defined _timezone_

> Options:
> - _format_: Format of the date and time (as defined in strftime(3))
> - _font_: font to use for text (normal, italic or bold).
> - _bg.light_: background color in light mode.
> - _bg.dark_: background color in dark mode.
> - _fg.light_: foreground color in light mode.
> - _fg.dark_: foreground color in dark mode.

- __[desklayout]__: Mode of the active workspace.

> Options:
> - _font_: font to use for text (normal, italic or bold).
> - _bg.light_: background color in light mode.
> - _bg.dark_: background color in dark mode.
> - _fg.light_: foreground color in light mode.
> - _fg.dark_: foreground color in dark mode.

- __[desklist]__: List of workspaces currently in use.

> Options:
> - _font_: font to use for text (normal, italic or bold).
> - _bg.light_: background color in light mode.
> - _bg.dark_: background color in dark mode.
> - _fg.light_: foreground color in light mode.
> - _fg.dark_: foreground color in dark mode.

- __[deskname]__: Name of the active workspace.

> Options:
> - _font_: font to use for text (normal, italic or bold).
> - _bg.light_: background color in light mode.
> - _bg.dark_: background color in dark mode.
> - _fg.light_: foreground color in light mode.
> - _fg.dark_: foreground color in dark mode.

- __[devices]__: Show some devices present under /dev.

> Options:
> - _searchlist_: List of devices to watch. (Default: _da[0-9] ulpt[0-9]_)
> - _font_: font to use for text (normal, italic or bold).
> - _bg.light_: background color in light mode.
> - _bg.dark_: background color in dark mode.
> - _fg.light_: foreground color in light mode.
> - _fg.dark_: foreground color in dark mode.

- __[loadavg]__: Shows current CPU load average.

> Options:
> - _exec_: Command to execute on mouse click.
> - _font_: font to use for text (normal, italic or bold).
> - _bg.light_: background color in light mode.
> - _bg.dark_: background color in dark mode.
> - _fg.light_: foreground color in light mode.
> - _fg.dark_: foreground color in dark mode.

- __[mail]__: Shows icons of new mail. There must be at least one maildir section defined.

> Options:
> - _exec_: Command to execute on mouse click.
> - _font_: font to use for text (normal, italic or bold).
> - _bg.light_: background color in light mode.
> - _bg.dark_: background color in dark mode.
> - _fg.light_: foreground color in light mode.
> - _fg.dark_: foreground color in dark mode.

- __[memused]__: Shows percentage of used memory.

> Options:
> - _exec_: Command to execute on mouse click.
> - _font_: font to use for text (normal, italic or bold).
> - _bg.light_: background color in light mode.
> - _bg.dark_: background color in dark mode.
> - _fg.light_: foreground color in light mode.
> - _fg.dark_: foreground color in dark mode.

- __[metar]__: Shows an icon and current temperature from a METAR station.
Clicking on it opens a window showing current weather conditions.

> Options:
> - _code_: The 4 characters code of the METAR station. (required)
> - _delay_: Time between updates in minutes. (Default 10)
> - _font_: font to use for text (normal, italic or bold).
> - _bg.light_: background color in light mode.
> - _bg.dark_: background color in dark mode.
> - _fg.light_: foreground color in light mode.
> - _fg.dark_: foreground color in dark mode.

- __[mixer]__: Shows an icon and the volume level of _/dev/mixer_.

> Options:
> - _exec_: Command to execute on mouse click.
> - _font_: font to use for text (normal, italic or bold).
> - _bg.light_: background color in light mode.
> - _bg.dark_: background color in dark mode.
> - _fg.light_: foreground color in light mode.
> - _fg.dark_: foreground color in dark mode.

- __[music]__: Shows an icon when the music player daemon is in use. Hovering on
it shows the currently playing track.

> Options:
> - _socket_: Unix or tcp socket for connecting to mpd. If not defined, the value
> of _MPD\_HOST_ is used instead.
> - _font_: font to use for text (normal, italic or bold).
> - _bg_:_light_: background color in light mode.
> - _bg_:_dark_: background color in dark mode.
> - _fg_:_light_: foreground color in light mode.
> - _fg_:_dark_: foreground color in dark mode.

- __[netstat]__: Shows net statistics the given network interface.

> Options:
> - _interface_: Network interface to monitor. (required)
> - _exec_: Command to execute on mouse click.
> - _font_: font to use for text (normal, italic or bold).
> - _bg.light_: background color in light mode.
> - _bg.dark_: background color in dark mode.
> - _fg.light_: foreground color in light mode.
> - _fg.dark_: foreground color in dark mode.

- __[separator]__: Widget acting as vertical separators between two widgets.

> Options:
> - _bg_:_light_: color in light mode.
> - _bg_:_dark_: color in dark mode.

- __[wintitle]__: Displays the title of the currently active window.

> Options:
> - _expand_: The widget expands to occupy all available space.
> - _maxlength_: Maximum length of text to display. (Default 100 characters)
> - _font_: font to use for text (normal, italic or bold).
> - _bg.light_: background color in light mode.
> - _bg.dark_: background color in dark mode.
> - _fg.light_: foreground color in light mode.
> - _fg.dark_: foreground color in dark mode.

## OTHER SECTIONS

- __[maildir]__: Defines a mailbox for the __mail__ widget.
The mailbox __must__ be in the _maildir_ format. Multiple _maildir_ sections
are allowed for multiple mailboxes.

> Options:
> - _name_: Name of the maildir (required)
> - _path_: Path of the maildir (required)
> - _bg.light_: background color in light mode.
> - _bg.dark_: background color in dark mode.
> - _fg.light_: foreground color in light mode.
> - _fg.dark_: foreground color in dark mode.

# FILES

If not specified at the command line, the configuration file _~/.config/zstatus/config_ is read at startup.

# BUGS

See GitHub Issues: <https://github.com/cmanv/zstatus/issues>
