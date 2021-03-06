(* TODO : optimization + more detailed comments *)

type 'a t = int64

let to_int64 = Obj.magic (* more efficient than id function ; but be careful *)
let of_int64_unsafe = Obj.magic

(* to be inlined later (unless the compiler do so) *)

(* TODO : translate or delete this comment *)
(* dommage, pourrait profiter a merveille des phatom types ... 
   notamment shift_pop et autres, qui marchent sur les element et les colones
   (pas les lignes ...) ; en mettant le tout dans un sous-module unsafe ... *)

let first g = Int64.logand g 15L
let first_row g = Int64.logand g 65535L
let first_col g = Int64.logand g 4222189076152335L

let shitf_pop g = Int64.shift_right_logical g 4
let shift_push x g = Int64.logor x (Int64.shift_left g 4)
let shift_row_pop g = Int64.shift_right_logical g 16
let shift_row_push r g = Int64.logor r (Int64.shift_left g 16)

let shift_npop g n = Int64.shift_right_logical g (n lsl 2)
let shift_row_npop g n = Int64.shift_right_logical g (n lsl 4)

(* / to be inlined later *)


let row_nth g n = first (shift_npop g n)
let col_nth g n = first (shift_row_npop g n)

let grid_nth_row g n = first_row (shift_row_npop g n)
let grid_nth_col g n = first_col (shift_npop g n)



(* we might do some optimization by bypassing some function calls *)
let rows g =
  (grid_nth_row g 0, grid_nth_row g 1, grid_nth_row g 2, grid_nth_row g 3)

let cols g =
  (grid_nth_col g 0, grid_nth_col g 1, grid_nth_col g 2, grid_nth_col g 3)


let rows_to_grid (r1, r2, r3, r4) =
  (shift_row_push r1 (shift_row_push r2 (shift_row_push r3 r4)))

let cols_to_grid (c1, c2, c3, c4) =
  (shift_push c1 (shift_push c2 (shift_push c3 c4)))


(* clearly no the most efficient *)
let row_to_col r =
  (shift_row_push (row_nth r 0)
  (shift_row_push (row_nth r 1)
                  (shift_row_push (row_nth r 2) (row_nth r 3))))
let col_to_row c =
  (shift_push (col_nth c 0)
  (shift_push (col_nth c 1)
                  (shift_push (col_nth c 2) (col_nth c 3))))

let make x =
  let rec aux g i =
    if i = 16 then g else
      aux (shift_push x g) (i + 1)
  in aux 0L 0


(* numbering starts at 0 *)
let init f =
  let rec aux g i j =
    if i < 0 then g else
      if j < 0 then aux g (i - 1) 3 else
        aux (shift_push (f i j) g) i (j - 1)
  in aux 0L 3 3


let get g i j = row_nth (grid_nth_row g i) j

(* TODO : TO BE OPTIMIZED !!! currently quite dirty *)
let update g i0 j0 e =
  init (fun i j -> if i = i0 && j = j0 then e else get g i j)


let fold_left f e g =
  let rec aux g i j acc  =
    if i > 3 then acc else
      if j > 3 then aux g (i + 1) 0 acc else
        aux (shitf_pop g) i (j + 1) (f acc (first g))
  in aux g 0 0 e



let iter f g = fold_left (fun _ x -> f x) () g
