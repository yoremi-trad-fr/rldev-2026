(* $Id: iMap.ml,v 1.3 2003/06/18 15:11:07 yori Exp $ *)
(* Copyright 2003 Yamagata Yoriyuki. distributed with LGPL *)
(* Reconstructed based on iMap.mli interface *)

include AvlTree

let (>!) = (>)

let compare_uint n1 n2 =
  let sgn1 = (n1 lsr 24) - (n2 lsr 24) in
  if sgn1 = 0 then (n1 land 0xffffff) - (n2 land 0xffffff) else sgn1

let (>) n1 n2 = compare_uint n1 n2 > 0
let (>=) n1 n2 = compare_uint n1 n2 >= 0
let (<) n1 n2 = compare_uint n1 n2 < 0
let (<=) n1 n2 = compare_uint n1 n2 <= 0
let compare = compare_uint

let max n1 n2 = if n1 >= n2 then n1 else n2
let min n1 n2 = if n1 <= n2 then n1 else n2

let max_int = ~-1
let min_int = 0

type key = int
type 'a t = (int * int * 'a) tree

let rec mem n m =
  if is_empty m then false else
  let v1, v2, _ = root m in
  if n < v1 then mem n (left_branch m)
  else if n > v2 then mem n (right_branch m)
  else true

let rec find n m =
  if is_empty m then raise Not_found else
  let v1, v2, x = root m in
  if n < v1 then find n (left_branch m)
  else if n > v2 then find n (right_branch m)
  else x

let rec add ?(eq=(=)) n x m =
  if is_empty m then make_tree empty (n, n, x) empty else
  let (v1, v2, v) as r = root m in
  let m0 = left_branch m in
  let m1 = right_branch m in
  if n < v1 - 1 then make_tree (add ~eq n x m0) r m1
  else if n > v2 + 1 then make_tree m0 r (add ~eq n x m1)
  else if n = v1 - 1 then
    if eq x v then
      if not (is_empty m0) then
        let (u1, u2, u), m0' = split_rightmost m0 in
        if u2 + 1 = n && eq x u then
          make_tree m0' (u1, v2, x) m1
        else
          make_tree m0 (n, v2, x) m1
      else
        make_tree m0 (n, v2, x) m1
    else
      make_tree (add ~eq n x m0) r m1
  else if n = v2 + 1 then
    if eq x v then
      if not (is_empty m1) then
        let (u1, u2, u), m1' = split_leftmost m1 in
        if n + 1 = u1 && eq x u then
          make_tree m0 (v1, u2, x) m1'
        else
          make_tree m0 (v1, n, x) m1
      else
        make_tree m0 (v1, n, x) m1
    else
      make_tree m0 r (add ~eq n x m1)
  else if eq x v then m
  else if n = v1 && n = v2 then make_tree m0 (n, n, x) m1
  else if n = v1 then make_tree m0 (n, n, x) (make_tree empty (n+1, v2, v) m1)
  else if n = v2 then make_tree (make_tree m0 (v1, n-1, v) empty) (n, n, x) m1
  else
    let m0' = make_tree m0 (v1, n-1, v) empty in
    let m1' = make_tree empty (n+1, v2, v) m1 in
    make_tree m0' (n, n, x) m1'

let rec add_range ?(eq=(=)) n1 n2 x m =
  if n1 > n2 then invalid_arg "IMap.add_range" else
  let m = remove_range n1 n2 m in
  let n1, m0 =
    if n1 = min_int then n1, empty else
    let m0 = until (n1 - 1) m in
    if is_empty m0 then n1, empty else
    let (u1, u2, u), m0' = split_rightmost m0 in
    if u2 + 1 = n1 && eq x u then u1, m0' else n1, m0 in
  let n2, m1 =
    if n2 = max_int then n2, empty else
    let m1 = from (n2 + 1) m in
    if is_empty m1 then n2, empty else
    let (u1, u2, u), m1' = split_leftmost m1 in
    if n2 + 1 = u1 && eq x u then u2, m1' else n2, m1 in
  make_tree m0 (n1, n2, x) m1

and remove n m =
  if is_empty m then empty else
  let (v1, v2, v) as r = root m in
  let m0 = left_branch m in
  let m1 = right_branch m in
  if n < v1 then make_tree (remove n m0) r m1
  else if n > v2 then make_tree m0 r (remove n m1)
  else if n = v1 && n = v2 then concat m0 m1
  else if n = v1 then make_tree m0 (v1 + 1, v2, v) m1
  else if n = v2 then make_tree m0 (v1, v2 - 1, v) m1
  else
    let m0' = make_tree m0 (v1, n - 1, v) empty in
    make_tree m0' (n + 1, v2, v) m1

and remove_range n1 n2 m =
  if n1 > n2 then invalid_arg "IMap.remove_range" else
  concat (before n1 m) (after n2 m)

and from n m =
  if is_empty m then empty else
  let (v1, v2, v) as r = root m in
  let m0 = left_branch m in
  let m1 = right_branch m in
  if n < v1 then make_tree (from n m0) r m1
  else if n > v2 then from n m1
  else make_tree empty (n, v2, v) m1

and after n m = if n = max_int then empty else from (n + 1) m

and until n m =
  if is_empty m then empty else
  let (v1, v2, v) as r = root m in
  let m0 = left_branch m in
  let m1 = right_branch m in
  if n > v2 then make_tree m0 r (until n m1)
  else if n < v1 then until n m0
  else make_tree m0 (v1, n, v) empty

and before n m = if n = min_int then empty else until (n - 1) m

let iter_range f = AvlTree.iter (fun (n1, n2, v) -> f n1 n2 v)

let iter f m = iter_range (fun n1 n2 v ->
  for i = n1 to n2 do f i v done) m

let fold_range f = AvlTree.fold (fun (n1, n2, v) a -> f n1 n2 v a)

let fold f m a =
  fold_range (fun n1 n2 v a ->
    let rec loop n a =
      if n > n2 then a else loop (n + 1) (f n v a) in
    loop n1 a) m a

let rec map ?(eq=(=)) f m =
  if is_empty m then empty else
  let v1, v2, v = root m in
  let m0 = map ~eq f (left_branch m) in
  let m1 = map ~eq f (right_branch m) in
  add_range ~eq v1 v2 (f v) (concat m0 m1)

let rec mapi ?(eq=(=)) f m =
  if is_empty m then empty else
  let v1, v2, v = root m in
  let m0 = mapi ~eq f (left_branch m) in
  let m1 = mapi ~eq f (right_branch m) in
  let rec loop n acc =
    if n > v2 then acc
    else loop (n + 1) (add ~eq n (f n v) acc) in
  loop v1 (concat m0 m1)

let set_to_map s v =
  ISet.fold_range (fun n1 n2 m -> make_tree m (n1, n2, v) empty) s empty

let domain m =
  fold_range (fun n1 n2 _ s -> ISet.add_range n1 n2 s) m ISet.empty

let map_to_set f m =
  fold_range (fun n1 n2 v s ->
    let rec loop n s =
      if n > n2 then s
      else if f v then loop (n + 1) (ISet.add n s)
      else loop (n + 1) s in
    loop n1 s) m ISet.empty
