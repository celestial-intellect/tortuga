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

type atom =
  | Int of int
  | Word of string
  | List of atom list
  | Array of atom array * int

exception Error of string
    
type turtle = {
  point : Gg.V2.t;
  angle : float;
  image : Vg.image;
  (* outline : P.outline; *)
  penup : bool;
  color : Gg.Color.t;
  alpha : float
}

module NoCaseString = struct
  type t = string
  let equal s1 s2 =
    String.uppercase s1 = String.uppercase s2
  let hash =
    Hashtbl.hash
end

module H = Hashtbl.Make (NoCaseString)

type env = {
  routines : routine H.t;
  globals : atom H.t;
  locals : atom H.t list;
  output : atom option -> unit;
  mutable turtle : turtle
}

and routine =
  | Pf0 of (unit -> atom option)
  | Pf1 of (atom -> atom option)
  | Pf2 of (atom -> atom -> atom option)
  | Pfn of int * (atom list -> atom option)
  | Pf12 of (atom -> ?opt:atom -> unit -> atom option)
  | Pfcn of int * (env -> atom list -> (atom option -> unit) -> unit)