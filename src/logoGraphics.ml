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

open Gg
open LogoTypes
open LogoAtom
open LogoEnv
  
let blank = Color.black
let blue = Color.blue
let lime = Color.v_srgbi 191 255 0
let cyan = Color.v_srgbi 0 255 255
let red = Color.red
let magenta = Color.v_srgbi 255 0 255
let yellow = Color.v_srgbi 255 255 0
let white = Color.white
let brown = Color.v_srgbi 150 75 0
let tan = Color.v_srgbi 210 180 140
let green = Color.green
let aquamarine = Color.v_srgbi 127 255 212
let salmon = Color.v_srgbi 250 128 114
let purple = Color.v_srgbi 128 0 128
let orange = Color.v_srgbi 255 127 0
let gray = Color.v_srgbi 128 128 128

let forward (module T : TURTLE) dist =
  let dist = iexpr dist in
  T.move dist

let back (module T : TURTLE) dist =
  let dist = iexpr dist in
  T.move (-dist)

let left (module T : TURTLE) deg =
  let deg = iexpr deg in
  T.turn (-deg)

let right (module T : TURTLE) deg =
  let deg = iexpr deg in
  T.turn deg

let setpos (module T : TURTLE) pos =
  match pos with
  | List [x; y] ->
    let x = iexpr x in
    let y = iexpr y in
    T.set_pos x y
  | _ ->
    raise (Error "setpos: bad args")

(* let render (module T : TURTLE) name = *)
(*   let name = try sexpr name with _ -> raise (Error "render: bad args") in *)
(*   let out = open_out_bin (name ^ ".pdf") in *)
(*   render turtle out; *)
(*   close_out out; *)
(*   turtle *)
    
let init env =
  set_pft1 env "forward" forward;
  set_pft1 env "fd" forward;
  set_pft1 env "back" back;
  set_pft1 env "bk" back;
  set_pft1 env "left" left;
  set_pft1 env "lt" left;
  set_pft1 env "right" right;
  set_pft1 env "rt" right;
  set_pft1 env "setpos" setpos

  (* set_pft1 env "render" render *)
