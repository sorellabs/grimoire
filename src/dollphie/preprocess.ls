/** ^
 * Copyright (c) 2013 Quildreen Motta
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

Maybe = require 'monads.maybe'
but-last = require 'data.array/common/but-last'
{ parse } = require './parser'

plain = (a) -> [\text a]

sanitise-re = (a) -> a.replace /(\W)/g, '\\$1'

matches-re = (s, re) --> (new RegExp re).test s

starts-with = (s, a) --> s `matches-re` "^\\s*#{sanitise-re a}"

nuke-comments = (c, s) --> s.replace (new RegExp "^\\s*#{sanitise-re c}\\s?"), ''

split-comments = (lexer, c) --> (a) ->
  a.split /\r?\n/
   .map (l, n) ->
     | /^\s*$/.test l    => [\blank line: n]
     | l `starts-with` c => [\text text: nuke-comments c, l; line: n]
     | otherwise         => [\code lexer: lexer, text: l, line: n]

fold-lines = (lines) ->
  (`lines~reduce` []) (as, a) ->
    | as.length is 0         => [a]
    | match-type a, as[*-1]  => (but-last as) ++ [(join as[*-1], a)]
    | match-type a, [\blank] => (but-last as) ++ [add-blank as[*-1], a]
    | otherwise              => as ++ [a]

match-type = (a, b) -> a.0 is b.0

join = (a, b) -> [...a, b.1]

add-blank = (a, b) -> [...a, text: '', line: b.line]

export process-file = (lexer, c) --> (a) -> fold-lines (split-comments lexer, c)(a)

export serialise-to-dollphie = (ast) ->
  (`ast~reduce` []) (as, a) ->
    switch a.0
    | \blank => as.push [\blank-line]
    | \text  => as.push ...(parse (a.slice 1 .map (.text) .join '\n')).get!.1
    | \code  => as.push [\meta
                          [\id \code]
                          [\soft-line ["#{a.1.lexer} #{a.1.line}"]]
                          [[\literal (a.slice 1 .map (.text) .join '\n')]]]
    return as

export find-language-definitions-for = (name) ->
  for lang, x of languages when match-language x, name => return Maybe.Just [lang, x]
  return Maybe.Nothing!

match-language = (spec, name) -->
  spec.extensions.some (a) ->(new RegExp "#{sanitise-re a}$").test name

export convert-to-dollphie = (filename, data) -->
  [lang, spec] <- find-language-definitions-for filename .chain
  Maybe.Just serialise-to-dollphie (spec.processor data)

export languages = do
                   Dollphie:
                     extensions: <[ .doll ]>
                     processor: plain
                   
                   C:
                     extensions: <[ .c .h ]>
                     processor: process-file \c '//'
                   
                   'C#':
                     extensions: <[ .cs ]>
                     processor: process-file \csharp '//'
                   
                   'C++':
                     extensions: <[ .cpp .hpp .c++ .h++ .cc .hh .cxx .hxx ]>
                     processor: process-file \cpp '//'
                   
                   Clojure:
                     extensions: <[ .clj .cljs ]>
                     processor: process-file \clojure ';;'
                     
                   CoffeeScript:
                     extensions: <[ .coffee Cakefile ]>
                     processor: process-file \coffee-script '#'
                   
                   Go:
                     extensions: <[ .go ]>
                     processor: process-file \go '//'
                   
                   Haskell:
                     extensions: <[ .hs ]>
                     processor: process-file \haskell '--'
                   
                   Java:
                     extensions: <[ .java ]>
                     processor: process-file \java '//'
                   
                   JavaScript:
                     extensions: <[ .js ]>
                     processor: process-file \javascript '//'
                   
                   LiveScript:
                     extensions: <[ .ls Slakefile ]>
                     processor: process-file \livescript '#'
                   
                   Lua:
                     extensions: <[ .lua ]>
                     processor: process-file \lua '--'
                   
                   Make:
                     extensions: <[ Makefile ]>
                     processor: process-file \make '#'
                   
                   'Objective-C':
                     extensions: <[ .m .nm ]>
                     processor: process-file \objc '//'
                   
                   Perl:
                     extensions: <[ .pl .pm ]>
                     processor: process-file \perl '#'
                   
                   PHP:
                     extensions: <[ .php .phpd .fbp ]>
                     processor: process-file \php '//'
                   
                   Puppet:
                     extensions: <[ .pp ]>
                     processor: process-file \puppet '#'
                   
                   Python:
                     extensions: <[ .py ]>
                     processor: process-file \python '#'
                   
                   Ruby:
                     extensions: <[ .rb .ru .gemspec ]>
                     processor: process-file \ruby '#'
                   
                   Shell:
                     extensions: <[ .sh ]>
                     processor: process-file \sh '#'

