%% This is file `novelette-subdoc.cls', part of `novelette' document class.
%% Copied and modified from file `subfiles.cls', part of `subfiles' package, 
%% Copyright 2002, 2012 Federico Garcia; 2018-2020 Gernot Salzer.
%% Modifications Copyright 2024 Robert Allgeyer.
%% This file may be distributed and/or modified under the
%% conditions of the LaTeX Project Public License, version 1.3.
%%
\NeedsTeXFormat{LaTeX2e}[2020/10/01]
\ProvidesClass{novelette-subdoc}
[2024/03/11 v0.46 Multi-file projects (class)]

%%% Sub-Documents
%   Novelette does not allow users to load packages, or to load files using
% \input or \import. Instead, \subdoc can load a file with extension *tex.
% A subdoc may load another subdoc.
%   If the subdoc has \documentclass[../path/to/maindoc.tex]{novelette-subdoc},
% then it must also have the usual \begin{document} and \end{document}.
% This kind of subdoc may be compiled by itself. It will read the Preamble of
% the main document. The subdoc cannot over-ride any of the main settings,
% except for \mode XXXX, and only when compiled by itself.
%% 

\DeclareOption*{\let\preamble@file\CurrentOption}
\ProcessOptions
\let\@classoptionslist\relax
\ifdefined\nvt@input\else\let\nvt@input\input\fi
\def\fatal@suberr#1{%
  \immediate\write\@unused{}%
  \set@display@protect%
  \typeout{! Class novelette-subdoc Fatal Error:^^J#1^^J%
    \space\space See the novelette class documentation for explanation.^^J%
    \space\space This is a fatal error. No PDF produced. Compiler exits.}%
  \batchmode \read-1 \ciaobaby
}
\IfFileExists\preamble@file{
  \typeout{Preamble taken from file `\CurrentOption'}%
}{
  \fatal@suberr{Subdoc \jobname\space did not find^^J%
  the main document at \preamble@file.^^J%
  Is the filename correct (with extension)?^^J%
  Is the path correct, from this subdoc to main document?^^J%
  Previously good path may become bad, if you move files.}
}
\let\novelettesubdoc@documentclass\documentclass
\def\documentclass{%
  \let\documentclass\novelettesubdoc@documentclass
  \LoadClass
}
\filename@parse{\preamble@file}
\edef\import@path{\filename@area}
\edef\input@path{{\filename@area}}
\edef\graphics@path{\filename@area}
\nvt@input{\preamble@file}
{\makeatletter\gdef\import@path{}}
% Prevent subdoc from changing settings, but allow mode, guides, sheetfeed:
\def\title#1{\@lert{Ignored setting \string\title, in subdoc.}}
\def\subtitle#1{\@lert{Ignored setting \string\subtitle, in subdoc.}}
\def\author#1{\@lert{Ignored setting \string\author, in subdoc.}}
\def\intent#1{\@lert{Ignored setting \string\intent, in subdoc.}}
\def\trimsize#1{\@lert{Ignored setting \string\trimsize, in subdoc.}}
\def\margin#1{\@lert{Ignored setting \string\margin, in subdoc.}}
\def\margins#1{\@lert{Ignored setting \string\margins, in subdoc.}}
\def\layout#1{\@lert{Ignored setting \string\layout, in subdoc.}}
\def\namestyle#1{\@lert{Ignored setting \string\namestyle, in subdoc.}}
\def\subnamestyle#1{\@lert{Ignored setting \string\subnamestyle, in subdoc.}}
\def\scenestyle#1{\@lert{Ignored setting \string\scenestyle, in subdoc.}}
\DeclareDocumentCommand\pageicon{O{}mO{}}{%
  \@lert{Ignored setting \string\pageicon, in subdoc.}%
}
\DeclareDocumentCommand\pageicons{O{}mO{}}{%
  \@lert{Ignored setting \string\pageicons, in subdoc.}%
}
\DeclareDocumentCommand\onechartypo{sm}{%
  \@lert{Ignored setting \string\onechartypo, in subdoc.}%
}
\DeclareDocumentCommand\twochartypo{sm}{%
  \@lert{Ignored setting \string\twochartypo, in subdoc.}%
}
\DeclareDocumentCommand\twocharstypo{sm}{%
  \@lert{Ignored setting \string\twocharstypo, in subdoc.}%
}
\ifthenelse{\equal{\@mode}{final}}{\gdef\@mode{draft}}{}
\def\starteven{%
  \AtBeginDocument{%
    \thispagestyle{empty}%
    \null\vfil%
    {\centering You requested subdoc \string\starteven.\\This page empty.\par}%
    \vfil\null\clearpage%
  }%
}
\@onlypreamble\starteven
\endinput
%%
%% End of file `novelette-subdoc.cls'.
