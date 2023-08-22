::  lib/iterator.hoon WIP
::
::  What's the sum of the first 20 natural numbers divisible by 3 or 5?
::
::  =<
::     %+  get-ind  19  ::  0-indexed
::     %+  accumulate  add
::     %+  filter-true  |=(n=@ |(=(0 (mod n 3)) =(0 (mod n 5))))
::     (count from=1 step=1)
::
::  =<  (to-list (take 10 primes))
|%
++  iterator
  |$  [item]
  $_  ^?  |.
  ^-  $@(~ [i=item next=^$])
  ~
::
++  list-to-iterator
  |*  =(list)
  ^-  (iterator _?>(?=(^ list) i.list))
  |.
  ?~  list  ~
  [i.list ..$(list t.list)]
::
++  iterator-type
  |*  it=(iterator)
  =+  (it)
  _?>(?=(^ -) i)
::
++  to-list  ::  unsafe: potential inf loop
  |*  it=(iterator)
  %-  flop
  =|  out=(list (iterator-type it))
  |-  ^+  out
  =+  (it)
  ?~  -  out
  %=  $
    out  [i out]
    it  next
  ==
::
++  count
  |=  [start=@ step=@]
  ^-  (iterator @)
  |.
  [start ..$(start (add start step))]
::  ++take first n
::
++  take
  |*  [n=@ it=(iterator)]
  ^+  it
  (slice [0 n 1] it)
::
++  chain
  |*  [a=(iterator) b=(iterator)]
  ^+  a
  |.
  =+  (a)
  ?^  -
    [i ..$(a next)]
  =+  (b)
  ?~  -  ~
  [i ..$(b next)]
::
++  cycle
  |*  it=(iterator)
  ^+  it
  =+  it-init=it
  |.
  =+  (it)
  ?^  -
    [i ..$(it next)]
  $(it it-init)
::
++  repeat
  |*  a=*
  ^-  (iterator _a)
  |.([a ..$])
::
++  accumulate
  |*  [f=_=>(~ |=([* *] +<+)) it=(iterator)]
  ^-  (iterator _(f *(iterator-type it) +<+.f))
  |.
  =+  (it)
  ?~  -  ~
  =/  result  ,:(f i +<+.f)
  :-  result
  ..$(it next, f f(+<+ result))
::
++  compress
  |*  [it=(iterator) select=(iterator ?)]
  ^+  it
  |.
  =+  pop-select=(select)
  ?~  pop-select  ~
  =+  pop-it=(it)
  ?~  pop-it  ~
  ?:  i.pop-select
    [i.pop-it ..$(it next.pop-it, select next.pop-select)]
  $(it next.pop-it, select next.pop-select)
::
++  drop-while
  |*  [it=(iterator) f=$-(* ?)]
  ^+  it
  |.
  =+  (it)
  ?~  -  ~
  ?:  (f i)
    $(it next)
  [i next]
::
++  filter-false
  |*  [f=$-(* ?) it=(iterator)]
  ^+  it
  |.
  =+  (it)
  ?~  -  ~
  ?:  (f i)
    $(it next)
  [i ..$(it next)]
::
++  filter-true
  |*  [f=$-(* ?) it=(iterator)]
  ^+  it
  |.
  =+  (it)
  ?~  -  ~
  ?.  (f i)
    $(it next)
  [i ..$(it next)]
::
++  slice  ::  overcomputes?
  |*  [[from=@ to=@ step=@] it=(iterator)]
  ^+  it
  =/  counter=@  0
  |.
  =+  (it)
  ?~  -  ~
  ?.  =(0 from)
    $(it next, from (dec from), counter +(counter))
  ?:  (gte counter to)
    ~
  [i ..$(it next, from (dec step), counter +(counter))]
::
++  pairwise
  |*  it=(iterator)
  ^-  (iterator (pair (iterator-type it) (iterator-type it)))
  |.
  =+  first-eval=(it)
  ?~  first-eval  ~
  =+  second-eval=(next.first-eval)
  ?~  second-eval  ~
  :-  [i.first-eval i.second-eval]
  ..$(it next.second-eval)
::
++  starmap
  |*  [it=(iterator) f=$-(* *)]
  ^-  (iterator _(f *(iterator-type it)))
  |.
  =+  (it)
  ?~  -  ~
  [(f i) ..$(it next)]
::
++  take-while
  |*  [it=(iterator) f=$-(* ?)]
  ^+  it
  |.
  =+  (it)
  ?~  -  ~
  ?.  (f i)
    ~
  [i ..$(it next)]
::
++  get-last  ::  unsafe: potential inf loop
  |*  it=(iterator)
  ^-  (iterator-type it)
  ::  (pins ~ or [i next])
  ::
  =+  (it)
  ?~  -
    ~|  'empty-iterator'
    !!
  |-  ^-  (iterator-type it)
  =+  (next)
  ?~  -  i
  $(i i, next next)  ::  **WTF**
                     ::  Replaces original [i next] pair from `(it)`
                     ::  with the new values from `(next)`. Then the
                     ::  cycle continues with `next` iterator. This idiom
                     ::  is equivalent to `$(+< -)`, but this is
                     ::  even more cursed.
  ::
  ++  get-ind
    |*  [ind=@ it=(iterator)]
    ^-  (iterator-type it)
    (get-last (take +(ind) it))
  ::
  ++  primes  ::  overcomputes?
    =/  n=@  2
    ^-  (iterator @)
    |.
    =*  this-it  ..$
    ::~+
    ?:
        ::;;  ?  .*  .  !=  ::  idk wtf im doing why you fuse-loop why dont you compuuuute
                            ::  maybe add something like ?:  =(n 2)
                                                           [2 ..$(n 3)]
                                                         ...
                            ::  so that take-while finishes properly?
        %-  is-empty
        %+  filter-true  |=(i=@ =(0 (mod n i)))
        ::(take-while this-it(n 2) (cork (curr pow 2) (curr lte n)))
        (take-while (count 2 1) (cork (curr pow 2) (curr lte n)))
      [n this-it(n +(n))]
    $(n +(n))
  ::
  ++  is-empty
    |=  it=(iterator)
    ^-  ?
    ?=(@ (it))
--
