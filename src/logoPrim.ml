(* The MIT License (MIT)

   Copyright (c) 2014 Nicolas Ojeda Bar <n.oje.bar@gmail.com>

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
   FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
   COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
   IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. *)

open LogoAtom
open LogoEnv
open LogoEval
  
let _ = Random.self_init ()

module Constructors = struct
  let word things =
    try
      Word (String.concat "" (List.map sexpr things))
    with
    | _ -> raise (Error "word: expected string")

  let list things =
    List things

  let sentence args =
    List (List.concat (List.map (function List l -> l | _ as a -> [a]) args))

  let fput thing list =
    match thing, list with
    | _, List l -> List (thing :: l)
    | Array _, _
    | _, Array _ ->
      raise (Error "fput: bad types")
    | _ ->
      let s1 = sexpr thing in
      let s2 = sexpr list in
      if String.length s1 = 1 then
        Word (s1 ^ s2)
      else
        raise (Error "fput: first arg must be a character")

  let fput_doc =
    "fput THING LIST

Outputs LIST with one extra member, THING, at the beginning.  If LIST is a word,
then THING must be a one-letter word, and 'fput THING LIST' is equivalent to
'word THING LIST'."

  let lput thing list =
    match thing, list with
    | _, List l -> List (l @ [thing])
    | Array _, _
    | _, Array _ ->
      raise (Error "lput: bad types")
    | _ ->
      let s1 = sexpr thing in
      let s2 = sexpr list in
      if String.length s1 = 1 then
        Word (s2 ^ s1)
      else
        raise (Error "lput: first arg must be a character")

  let lput_doc =
    "lput THING LIST

Outputs LIST with one extra member, THING, at the end.  If LIST is a word, then
THING must be a one-letter word, and 'lput THING LIST' is equivalent to 'word
LIST THING'."

  let array size ?(opt = Int 1) () =
    let size = try iexpr size with _ -> raise (Error "array: SIZE must be a number") in
    let origin = try iexpr opt with _ -> raise (Error "array: ORIGIN must be a number") in
    if size < 0 then raise (Error "array: SIZE must be a positive integer");
    Array (Array.create size (List []), origin)

  let array_doc =
    "array SIZE
(array SIZE ORIGIN)

Outputs an array of SIZE members (must be a positive integer), each of which
initially is an empty list.  Array members can be selected with 'item' and
changed with 'setitem'.  The first member of the array is member number 1 unless
an ORIGIN input (must be an integer) is given, in which case the first member of
the array has ORIGIN as its index.  (Typically 0 is used as ORIGIN if anything.)
Arrays are printed by 'print' and friends, and can be typed in, inside curly
braces; indicate an origin with {a b c}@0."

  let combine thing1 thing2 =
    match thing1, thing2 with
    | _, List l -> List (thing1 :: l)
    | _, Array _
    | Array _, _ ->
      raise (Error "combine: bad types")
    | _ ->
      let s1 = sexpr thing1 in
      let s2 = sexpr thing2 in
      Word (s1 ^ s2)

  let listtoarray list ?(opt = Int 1) () =
    let origin = try iexpr opt with _ -> raise (Error "listtoarray: ORIGIN must be a number") in
    match list with
    | List l -> Array (Array.of_list l, origin)
    | _ -> raise (Error "listtoarray: LIST must be a list")

  let listtoarray_doc =
    "listtoarray LIST
(listtoarray LIST ORIGIN)

Outputs an array of the same size as the LIST, whose members are the members of
LIST.  The first member of the array is member number 1 unless an ORIGIN input
(must be an integer) is given, in which case the first member of the array has
ORIGIN as its index."

  let arraytolist = function
    | Array (a, _) ->
      List (Array.to_list a)
    | _ ->
      raise (Error "arraytolist: ARRAY must be an array")
  
  let arraytolist_doc =
    "arraytolist ARRAY

Outputs a list whose members are the members of ARRAY.  The first member of the
output is the first member of the array, regardless of the array's origin."

  let reverse = function
    | List l -> List (List.rev l)
    | _ ->
      raise (Error "reverse: expected a list")

  let reverse_doc =
    "reverse LIST

Outputs a list whose members are the members of LIST, in reverse order."

  let gensym =
    let count = ref 0 in
    fun () ->
      incr count;
      Word ("G" ^ string_of_int !count)

  let gensym_doc =
    "gensym

Outputs a unique word each time it's invoked.  The words are of the form G1, G2,
etc."

  let init env =
    add_routine env "word" { nargs = 2; kind = Procn word };
    add_routine env "list" { nargs = 2; kind = Procn list };
    add_routine env "sentence" { nargs = 2; kind = Procn sentence };
    add_routine env "se" { nargs = 2; kind = Procn sentence };
    add_routine env "fput" { nargs = 2; kind = Proc2 fput };
    add_routine env "lput" { nargs = 2; kind = Proc2 lput };
    add_routine env "array" { nargs = 1; kind = Proc12 array };
    add_routine env "combine" { nargs = 2; kind = Proc2 combine };
    add_routine env "listtoarray" { nargs = 1; kind = Proc12 listtoarray };
    add_routine env "arraytolist" { nargs = 1; kind = Proc1 arraytolist };
    add_routine env "reverse" { nargs = 1; kind = Proc1 reverse };
    add_routine env "gensym" { nargs = 0; kind = Proc0 gensym }
end

module DataSelectors = struct
  let first = function
    | Int n ->
      Word (String.make 1 (string_of_int n).[0])
    | Word "" ->
      raise (Error "first: empty word")
    | Word w ->
      Word (String.make 1 w.[0])
    | List [] ->
      raise (Error "first: empty list")
    | List (x :: _) ->
      x
    | Array (_, orig) ->
      Int orig

  let firsts = function
    | List l ->
      List (List.map first l)
    | _ ->
      raise (Error "firsts: list expected")

  let last = function
    | Int n ->
      let s = string_of_int n in
      let l = String.length s in
      Word (String.make 1 (s.[l-1]))
    | Word w ->
      let l = String.length w in
      Word (String.make 1 (w.[l-1]))
    | List [] ->
      raise (Error "last: empty list")
    | List lst ->
      let l = List.length lst in
      List.nth lst (l-1)
    | _ ->
      raise (Error "last: LIST or WORD expected")

  let butfirst = function
    | Int n ->
      let s = string_of_int n in
      let l = String.length s in
      Word (String.sub s 1 (l-1))
    | Word w ->
      let l = String.length w in
      Word (String.sub w 1 (l-1))
    | List [] ->
      raise (Error "butfirst: empty list")
    | List (_ :: rest) ->
      List rest
    | _ ->
      raise (Error "butfirst: expected WORD or LIST")

  let item index thing =
    let index = try iexpr index with _ -> raise (Error "INDEX must be number") in
    match thing with
    | Int n ->
      let s = string_of_int n in
      Word (String.make 1 s.[index-1])
    | Word w ->
      Word (String.make 1 w.[index-1])
    | List l ->
      List.nth l (index-1)
    | Array (a, orig) ->
      a.(index-orig)

  let pick = function
    | List [] ->
      raise (Error "pick: empty list")
    | List l ->
      List.nth l (Random.int (List.length l))
    | _ ->
      raise (Error "pick: LIST expected")

  let quoted = function
    | List _ as a -> a
    | Int n ->
      let s = string_of_int n in
      Word ("\"" ^ s)
    | Word w ->
      Word ("\"" ^ w)
    | _ ->
      raise (Error "quoted: LIST or WORD expected")
        
  let init env =
    add_routine env "first" { nargs = 1; kind = Proc1 first };
    add_routine env "firsts" { nargs = 1; kind = Proc1 firsts };
    add_routine env "last" { nargs = 1; kind = Proc1 last };
    add_routine env "butfirst" { nargs = 1; kind = Proc1 butfirst };
    add_routine env "item" { nargs = 2; kind = Proc2 item };
    add_routine env "pick" { nargs = 1; kind = Proc1 pick };
    add_routine env "quoted" { nargs = 1; kind = Proc1 quoted }
end

module Transmitters = struct
  let print things =
    let rec pr top = function
      | Int n -> print_int n
      | Word w -> print_string w
      | List [] -> if top then () else print_string "[]"
      | List (x :: rest) ->
        if top then begin
          pr false x;
          List.iter (fun x -> print_char ' '; pr false x) rest
        end else begin
          print_char '[';
          pr false x;
          List.iter (fun x -> print_char ' '; pr false x) rest;
          print_char ']'
        end
      | Array ([| |], 1) ->
        print_string "{}"
      | Array ([| |], orig) ->
        print_string "{}@";
        print_int orig
      | Array (a, 1) ->
        print_char '{';
        pr false a.(0);
        for i = 1 to Array.length a - 1 do
          print_char ' ';
          pr false a.(i)
        done;
        print_char '}'
      | Array (a, orig) ->
        print_char '{';
        pr false a.(0);
        for i = 1 to Array.length a - 1 do
          print_char ' ';
          pr false a.(i)
        done;
        print_string "}@";
        print_int orig
    in
    match things with
    | [] ->
      print_newline ()
    | x :: rest ->
      pr true x;
      List.iter (fun x -> print_char ' '; pr true x) rest;
      print_newline ()
    
  let init env =
    add_routine env "print" { nargs = 1; kind = Cmdn print }
end

module Control = struct
  let stop env things _ =
    match things with
    | [] -> output env None
    | _ -> raise (Error "stop: bad arity")
             
  let output env things _ =
    match things with
    | a :: [] -> output env (Some a)
    | _ -> raise (Error "output: bad arity")

  let bye () =
    raise Bye
      
  let init env =
    add_routine env "stop" { nargs = 0; kind = Pcontn stop };
    add_routine env "output" { nargs = 1; kind = Pcontn output };
    add_routine env "bye" { nargs = 0; kind = Cmd0 bye }
end