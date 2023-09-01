%% This is file `novelette.cls', lualatex `novelette' document class.
%% Copyright 2023 Robert Allgeyer.
%%
%% This file may be distributed and/or modified under the
%% conditions of the LaTeX Project Public License, version 1.3c.
%% License URL: https://www.latex-project.org/lppl/lppl-1-3c.txt
%% A copy of this license is distributed with LaTeX 2008+.
%%
\NeedsTeXFormat{LaTeX2e}[2020/10/01]
\ProvidesClass{novelette}%
[2023/08/30 v0.4 LuaLaTeX document class (printed non-color popular fiction).]
\def\class@ver{4} % Above version = v0.\class@ver. Also update other files.
% If \class@ver is less than 10, this is BETA TEST.
%%


%% PURPOSE
% Novelette is limited to printed (paper, not Ebook) popular fiction, written
% in a Western European language. Monochrome black ink interiors, and CMYK
% color covers, are supported. Interior images must be monochrome png.
% No vector artwork. Print-on-demand is expected, but not exclusive.
%   The available commands are very limited, to only what you need for books
% such as detctive novels, romance, and the like. No frills. Although bug
% reports are encouraged, feature requests ar not. If you cannot do what
% you need to do, then try a different document class.
%   Novelette must be compiled using LuaLaTeX, not pdftex or XeTeX.
% Command: lualatex yourdocument   Or: luahbtex --fmt=lualatex yourdocument
%   You may decompose your book into a main document with subfiles, such as
% chapters. Then, you may compile an individual subfile. Great for editing.
% The complete book is created by compiling the main document, which calls
% its subfiles (rather than by merging various PDF subfiles).
%   Novelette supports three modes: draft, shade, final. Default draft.
% Shade mode is draft, with gray zones placed on pages, for alignment purposes.
% In draft|shade mode, you may do some things (such as fake or off-spec images)
% that are disallowed in final mode. Also, a draft|shade mode file, or any
% individual subfile, will contain modified PDF metadata, which distinguishes
% it from the data that will appear in the final document.
%   In final mode, you may compile the document for PDF/X-1a:2001 conformance.
% This is the default. But if an error is detected, the document will
% automatically revert to draft mode, and will not be labeled with conformance.
%   Settings such as font size, lines per page, page size, and anything else,
% are not set by a document class option. Instead, you may modify the default
% values, by using Novelette-specific commands in Preamble.
%   The only class option is "cover". This converts a pre-processed CMYK
% cover image to PDF/X-1a:2001 conformance, without attached icc profile.
% Some print services require this format; others do not. When processing
% a cover, only a single page is produced, with no text. Just the image.
%   The Preamble settings for cover and non-cover will ignore each other.
% So, you may use a single document for both book interior and its cover.
%   Novelette does not use most standard LaTeX commands, and does not allow
% you to load additional packages. This is because the internal calculations
% require very specific macros, and no others. So, be sure to read the
% documentation.
%%


%% Traps some novelette-specific fatal errors:
\def\nvt@fatal@error#1{%
  \immediate\write\@unused{}%
  \set@display@protect%
  \typeout{! Class novelette Fatal Error: #1^^J^^J%
    See the novelette class documentation for explanation.^^J%
    This is a fatal error. No PDF produced. Compiler exits.}%
  \batchmode \read-1 \ciaobaby
}
%%


%% Preliminary requirements:
\RequirePackage{iftex}
\RequirePackage{luatex85} % Compatibility.
\RequirePackage{pdftexcmds} % Compatibility.
\ifluatex
  \pdfvariable suppressoptionalinfo 511 % Writes only ID to PDF Catalog.
\else
  \nvt@fatal@error{Requires lualatex compiler.^^J%
  Command:\space\space lualatex yourdocument^^J%
  Or this:\space\space luahbtex --fmt=lualatex yourdocument}
\fi
\RequirePackage{luatexbase}
\nofiles % Does not use aux.
\pdfimageresolution=600 % Default pixels/inch for monochrome bitmap images.
\pdfcompresslevel=0
\pdfobjcompresslevel=0
\pdfminorversion=3 % Required for optional PDF/X-1a:2001 conformance.
\gdef\thepdfminorversion{\pdfminorversion}
\setlength\overfullrule{6pt} % Except in final mode.
\newif\ifmsdoc % Always false. Compatibility with some packages.
\newif\if@ok % Local scratch boolean. Typically used for and/or series.
\newif\ifnocle@rtoend % True omits blank verso at end. Normally false.
\newlength\temp@l % Local scratch length.
\newcounter{nvt@alert} \setcounter{nvt@alert}{0} % Number of alerts issued.
\RequirePackage{novelette-unglued}
\newif\ifwarn@percent % True warns if percent symbol used for comment.
\newif\ifwarn@alert % True issues warning when alerts > 0.
\newcounter{nvt@count} % Scratch counter.
\newif\ifdev@test \newlength\feeler@wd % Developer only.
%%


%% Error detection. Intended to prevent final mode when error:
\newif\ifb@d % True if error detected.

\def\@XN{You may continue. A PDF may or may not be produced.^^J%
  If PDF produced, it is relegated to draft or shade mode.^^J%
  Better to respond x to exit now, then fix the problem}
\def\@RXN{No more help. If in doubt, respond x to exit now.}
\def\@error#1{\ClassError{novelette}{^^J#1^^J\@XN}{\@RXN}\global\b@dtrue}


% Thanks to Marcel Krüger for this, at tex.stackexchange.com, q. 675718:
\directlua{
  local error_seen = false
  local true_cmd = token.create'use_i:nn'
  local false_cmd = token.create'use_ii:nn'
  local id = luatexbase.new_luafunction'iferrorsissued'
  token.set_lua('iferrorsissued', id)
  lua.get_functions_table()[id] = function()
    token.put_next(error_seen and true_cmd or false_cmd)
  end
  luatexbase.add_to_callback('show_error_hook', function()
    error_seen = true
    texio.write('.')
    tex.show_context()
  end, 'track_errors')
}
%%


%% Utility: Check if string can be used to set a length (number with units).
\newcommand\check@length[1]{
  \@okfalse
  \IfEndWith{#1}{in}{\@oktrue}{}
  \IfEndWith{#1}{mm}{\@oktrue}{}
  \IfEndWith{#1}{cm}{\@oktrue}{}
  \IfEndWith{#1}{pt}{\@oktrue}{}
  \IfEndWith{#1}{bp}{\@oktrue}{}
  \ifdefined\forceindent\IfEndWith{#1}{em}{\@oktrue}{}\fi % AtBeginDocument.
  \StrGobbleRight{#1}{2}[\temp@cl]
  \IfDecimal{\temp@cl}{}{\@okfalse}
}
%%


%% Class Option:
\newif\ifnvt@cover
\DeclareOption{cover}{
  \global\nvt@covertrue
  \global\pdfimageresolution=300 % Default for cover image.
}
\ProcessOptions
\ifdefined\preamble@file % When compiling only a subfile.
  \ifnvt@cover
    \nvt@fatal@error{Cannot request cover from within subfile.
      Cover may only be processed as main document.}
  \fi
\fi
%%


%% Novelette uses these in a slightly different way than in other classes:
\protect\def\title#1{\gdef\nvt@title{#1}}
\title{Untitled Document}
\@onlypreamble\title
\protect\def\author#1{\gdef\nvt@author{#1}}
\author{Anonymous Author}
\@onlypreamble\author
%% \subtitle is for convenience. Not in PDF metadata.
\long\gdef\subtitle#1{\gdef\@subtitle{#1}\gdef\thesubtitle{#1}}
\@onlypreamble\subtitle
%%
% Only set application or producer if necessary. Otherwise, use defaults.
\newcommand\application[1]{\gdef\nvt@application{#1}}
\application{Novelette}
\@onlypreamble\application
\newcommand\producer[1]{\gdef\nvt@producer{#1}}                                                                 \producer{Novelette}
\@onlypreamble\producer
%%


%%
\RequirePackage{xparse}
\RequirePackage{letltxmacro}
\RequirePackage{etoolbox}
\RequirePackage{xifthen}
\RequirePackage{xstring}
\RequirePackage[nomessages]{fp}
\FPmessagesfalse
%%


%% The booksize is finished size of interior pages. Known as "trim size".
\newlength\book@w \newlength\book@h % No defaults. Fatal error if not set.
\newcommand\booksize[1]{ % w=length,h=length. Must be h>=w.
  \StrDel{#1,}{ }[\temp@s]
  \StrBehind{\temp@s}{w=}[\temp@n]
  \StrBefore{\temp@n}{,}[\temp@n]
  \check@length{\temp@n}
  \if@ok
    \global\deflength\book@w{\temp@n}
    \StrBehind{\temp@s}{h=}[\temp@n]
    \StrBefore{\temp@n}{,}[\temp@n]
    \check@length{\temp@n}
    \if@ok\global\deflength\book@h{\temp@n}\fi
  \fi
  \if@ok
    \ifthenelse{\dimtest{\book@h}{<}{\book@w}}{\@okfalse}{}
  \fi
  \if@ok
    \gdef\book@size{#1}
  \else
    \nvt@fatal@@error{Bad \string\booksize{w=W,h=H}.^^J%
      W and H must have units in|mm. Also, H>=W.^^J%
      You must set both of them. No default values.}
  \fi
}
\@onlypreamble\booksize
%%


%% PDF/X Output Intent for interior. Cover may over-ride using \coverintent.
\newcommand\intent[1]{ % For PDF/X conformance.
  \IfSubStr{:none:SWOP:FOGRA39:JC200103:custom:}{#1}{
    \xdef\@intent{#1}
  }{
    \@error{Bad \string\intent{choice}.^^J%
      Choices: none SWOP FOGRA39 JC200103 custom.^^J%
      Do not use custom without expertise. See docs.}
  }
}
\ifnvt@cover\def\@intent{SWOP}\else\def\@intent{none}\fi % Defaults.
\@onlypreamble\intent
%%


%%
\RequirePackage{novelette-layout}
\ifnvt@cover
  \RequirePackage{novelette-cover}
\else
  \RequirePackage{novelette-interior}
  \RequirePackage{silence}
  \WarningFilter{microtype}{I cannot find a protrusion list}
  \WarningFilter{microtype}{protrusion}
  \WarningFilter{microtype}{Redefining}
  \WarningFilter*{latex}{Text page \thepage\space contains only floats}
  \WarningsOff[Fancyhdr,fancyhdr]
  \RequirePackage{atbegshi}
  \RequirePackage{changepage} % Do not use strict!
  \RequirePackage{noindentafter}
  \RequirePackage{novelette-fonts}
  \RequirePackage{novelette-utilities}
  \RequirePackage{luahyphenrules}
\fi
%%


%% No user-added packages:
\LetLtxMacro\nvt@get@package\RequirePackage\relax
\NewDocumentCommand\out@of@luck{O{}m}{%
  \nvt@fatal@error{Novelette does not allow additional packages.^^J%
    You cannot use \string\usepackage, or \string\RequirePackage.^^J%
    If the package is a font, do not load its package. Instead, use^^J%
    the Novelette font settings to directly load the fonts by name.^^J%
    Novelette pre-loads only what is necessary. No frills allowed.^^J%
    Reason: Layout calculations are very tight, and are likely to be^^J%
    disturbed by added packages. Besides, you should not need them.}
}
\LetLtxMacro\RequirePackage\out@of@luck\relax
\LetLtxMacro\usepackage\out@of@luck\relax
%%


%% Process user settings, set defaults, calculate page layout:
\AtEndPreamble{
  \ifdefined\book@size\else
    \nvt@fatal@error{\string\booksize\space was not set.^^J%
      The booksize, known to print services as "trim size",^^J%
      is the finished width and height of interior book pages.^^J%
      Novelette does not use a default setting for booksize.^^J%
      In Preamble: \string\booksize{w=W,h=H}^^J%
      \space\space W = Interior page width (units in|mm).^^J%
      \space\space H = Interior page height (units in|mm).^^J%
      Example: \string\booksize{w=5.5in,h=8.5in}^^J%
      If creating a cover, its booksize must be set to the same as^^J%
      interior page booksize. The coversize is a different setting.}
  \fi
  \LetLtxMacro\RequirePackage\nvt@get@package\relax
  \LetLtxMacro\usepackage\nvt@get@package\relax
  \ifthenelse{\equal{\@mode}{dev}}{\global\dev@testtrue}{}
  \ifdev@test\gdef\@mode{shade}\global\deflength\feeler@wd{4pt}\fi
  \ifnvt@cover\else\HyphenRules{\set@lang}\fi
  \ifthenelse{\equal{\@mode}{final}}{\global\deflength\overfullrule{0pt}}{}
  \process@layout
  \gundef\setmainfont \gundef\setsansfont \gundef\setmonofont
  \gundef\newfontfamily \gundef\newfontface
  \RequirePackage[no-math,quiet]{fontspec}
  \defaultfontfeatures[\rmfamily,\sffamily]%
    {Kerning=On,Numbers=OldStyle,Ligatures=TeX,}
  \RequirePackage{novelette-fonts}
  \process@fonts
  \RequirePackage[\nvt@microset]{microtype}
  \ifdefined\DeclareMicrotypeFilePrefix % From microtype version 3.1.
    \DeclareMicrotypeFilePrefix{nvt} % Load nvt-*.cfg for microtype.
  \else
    \def\MT@find@file#1{} % Prevents loading mt-*.cfg files AtBeginDocument.
  \fi
  \RequirePackage{novelette-footnotes}
  \RequirePackage{novelette-opening}
  \RequirePackage{novelette-color}
  \RequirePackage{novelette-image}
  \RequirePackage{fancyhdr}
  \RequirePackage{novelette-headers}
  \process@headfoot
  \RequirePackage{novelette-metadata}
  \process@metadata
  \process@pdfboxes
  \ifthenelse{\equal{\@mode}{shade}}{\RequirePackage{novelette-shading}}{}
  \RequirePackage{novelette-filler}
}
%%


%% Finish the setup, with some values not available until here:
\AtBeginDocument{
  \global\deflength\textfloatsep{0pt plus \le@ding minus \le@ding}
  \global\deflength\parindent{\normalindent}
  \gdef\forceindent{\ifvmode\else\unskip\fi\stake\hspace{\normalindent}}
  \gdef\backindent{\ifvmode\else\unskip\fi\hspace{-\normalindent}}
  \DeclareDocumentCommand\textls{sO{}+m}{#3} % Do-nothing.
  \let\lsstyle\relax
  \hyphenpenalty=1000
  \exhyphenpenalty=1000
  \gdef\nvt@versohead{}
  \gdef\nvt@\rectohead{}
  \gdef\nocleartoend{\nocle@rtoendtrue} % Cover and docs only. Not book.
  \frenchspacing % Even if English.
}
%%


%% Tacked onto the end of AtBeginDocument, just prior to document body:
\AfterEndPreamble{ % Deactivate many special characters and macros.
  \catcode`\$=12
  \catcode`\_=12
  \catcode`\#=12
  \catcode`\&=12
  \catcode`\^=12
  \gdef\nvt@sdqused{ALERT: Used straightdblquote, page \thepage.}
  \begingroup\lccode`\~="0022
  \lowercase{\endgroup%
    \gdef~{\straightdblquote\typeout{\nvt@sdqused}\stepcounter{nvt@alert}}%
  }
  \catcode`\"=13
  \def\({(}
  \def\){)}
  \def\[{[}
  \def\]{]}
  \ifwarn@percent
    \begingroup
    \lccode`\~="0025
    \lowercase{\endgroup%
      \gdef~{\ClassWarning{novelette}{Percent used as comment, page \thepage}}%
    }
    \catcode`\%=13
  \fi
}
%%


%% Runs at \end{document}. Document is still writeable here:
\AtEndDocument{
  \catcode`\%=14
  \catcode`\"=12
  \catcode`\$=3
  \catcode`\_=8
  \catcode`\#=6
  \catcode`\&=4
  \catcode`\^=7
  \ifnocle@rtoend\else
    \clearpage
    \ifodd\c@page
      \thispagestyle{empty}\null\clearpage
    \fi
    \thispagestyle{empty}\null\clearpage
  \fi
  \pdfinfo{%
    /CreationDate(\pdffeedback creationdate) % Needs space percent.
    /ModDate(\pdffeedback creationdate) % Needs space percent.
  }
  \iferrorsissued{\global\b@dtrue}{}
  \ifthenelse{\equal{\nvt@title}{Untitled Document}}{\global\b@dtrue}{}
  \ifthenelse{\equal{\nvt@author}{Anonymous Author}}{\global\b@dtrue}{}
  \ifb@d
    \ifthenelse{\equal{\@mode}{final}}{\gdef\@mode{draft}}{}
    \gdef\@intent{none}
    \xdef\log@mode{\string\mode[\@intent]{\@mode} (no final mode when error).}
    \gdef\mod@xmplabel{DRAFT }
  \else
    \gdef\mod@xmplabel{}
  \fi
  \attach@metadata
  \attach@xmp
  \ifthenelse{\equal{\@intent}{none}}{}{\attach@intent}
  \ifnum\value{nvt@alert}=0\else
    \ifwarn@alert
      \ClassWarningNoLine{novelette}{One or more ALERT in log file}
    \fi
  \fi
}
%%


%% Log final messages and summary:
\AfterEndDocument{
  \typeout{^^J}
  \typeout{*******************************************************************}
  \ifnvt@cover%
    \typeout{SUMMARY FOR COVER OF JOBNAME \jobname}%
  \else%
    \typeout{SUMMARY FOR JOBNAME \jobname}%
  \fi%
  \typeout{*******************************************************************}
  \typeout{These are the actual values used. If different from your settings,}
  \typeout{it means Novelette used defaults, or needed to over-ride yours:}
  \ifnvt@cover
    \typeout{Document class option [cover].}
    \typeout{\string\coverPDFtitle{\cover@name}}
    \typeout{\string\coverPDFauthor{\cover@author}}
    \typeout{\string\coverPDFintent{\cover@intent}}
    \typeout{\string\coverIMAGEfilename{\cover@image}}
    \typeout{\string\covertrim{\cover@trim} (final, after trimming bleed area)}
    \typeout{Book title: \@title}
    \typeout{Book author: \@author}
    \typeout{Book interior page size: \book@size}
    %%%%% \typeout{Measured image size, with bleed: \cover@measure}
  \else
    \typeout{\string\title{\@title}}
    \ifdefined\@subtitle\typeout{\string\subtitle{\@subtitle}}\fi
    \typeout{\string\author{\@author}}
    \typeout{\string\application{\nvt@application}}
    \typeout{\string\producer{\nvt@producer}}
    \typeout{\string\mode[\@intent]{\@mode}}
    \typeout{\string\booksize{\book@size}}
    \typeout{\string\sheetfeed{\sheet@feed}}
    \typeout{\string\margins{\all@margins}}
    \typeout{\string\layout{style=\l@yout,hgap=\h@gap,fgap=\f@gap,num=\numer@ls}}
    \typeout{\string\guides{\nvt@guides}\ifdefined\no@guides\space\no@guides\fi}
    \typeout{\string\setmicrotype{\nvt@microset}}
    \typeout{\string\mainfont{\main@name}[\main@feat]}
    \ifdefined\alt@font\typeout{\string\altfont{\alt@name}[\alt@feat]}\fi
    \ifdefined\drama@font\typeout{\string\dramafont{\drama@name}[\drama@feat]}\fi
    \ifdefined\deco@font\typeout{\string\decofont{\deco@name}[\deco@feat]}\fi
    \ifdefined\lang@feature
      \typeout{string\setlang{\set@lang}[\lang@feature]}
    \else
      \typeout{\string\setlang{\set@lang}}
      \ifthenelse{\equal{\set@lang}{english}}{
        \typeout{\space\space Better to use {english}[us] or {english}[uk].}
      }{}
    \fi

    \ifdefined\funky@margin{\typeout{\funky@margin}}\fi

    \FPround{\temp@n}{\strip@pt\type@size}{2}
    \FPclip{\temp@n}{\temp@n}
    \FPmul{\temp@d}{\strip@pt\type@size}{.996264}
    \FPround{\temp@d}{\temp@d}{2}
    \FPclip{\temp@d}{\temp@d}
    \typeout{\string\typesize{\temp@n pt} (\temp@d\space PostScript)}

    \ifdefined\typescale@message{\typeout{\typescale@message}}\fi
    \typeout{Estimated average chars/line, English: \chars@line. Typical 55-75.}
    \typeout{\string\lines{\lines@pp}}

    \FPround{\temp@n}{\strip@pt\le@ding}{2}
    \FPclip{\temp@n}{\temp@n}
    \FPmul{\temp@d}{\strip@pt\le@ding}{.996264}
    \FPround{\temp@d}{\temp@d}{2}
    \FPclip{\temp@d}{\temp@d}
    \typeout{Calculated leading (baselineskip): %
      \temp@n pt (\temp@d\space PostScript)}
    \FPdiv{\temp@n}{\strip@pt\le@ding}{\strip@pt\type@size}
    \FPround{\temp@n}{\temp@n}{2}
    \FPclip{\temp@n}{\temp@n}
    \typeout{Calculated ratio leading/typesize: \temp@n. Typically near 1.28.}

    \log@imagespecs

  \fi
  \typeout{Document Class novelette v0.\class@ver. Processed by lualatex.}
  \ifnum\value{nvt@alert}=0\else
    \typeout{!!!!! Warnings or ALERTs issued. See log file. !!!!!}
  \fi
  \ifb@d
    \typeout{!!!!! ERROR OR CRITICAL WARNING. OUTPUT IS INVALID. !!!!!}
  \fi
  \typeout{*******************************************************************}
  \typeout{^^J}
}
%%



%%
%% End of file `novelette.cls'.
%%
