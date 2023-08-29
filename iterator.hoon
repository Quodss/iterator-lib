::  lib/iterator.hoon WIP
::
::  What's the sum of the first 20 natural numbers divisible by 3 or 5?
::
::  =<
::    %+  get-ind  19  ::  0-indexed
::    %+  accumulate  add
::    %+  filter-true  |=(n=@ |(=(0 (mod n 3)) =(0 (mod n 5))))
::    (count from=1 step=1)
::
::  How many times to roll a D20 to get a 20?
::  =<
::    =;  it=(iterator [@ @])
::      ?:  (is-empty it)  1
::      -:(get-last it)
::    %+  take-while  |=([p=@ q=@] (lth q 20))
::    %+  zip
::      (count 2 1)
::    (random 1 20 eny)
|%
++  iterator
  |$  [item]
  $_  |?
  ^-  $@(~ [i=item next=(iterator item)])
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
  $(out [i out], it next)
::
++  count
  |=  [start=@ step=@]
  ^-  (iterator @)
  |.
  :-  start
  ..$(start (add start step))
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
  ?~  -  (b)
  [i ..$(a next)]
::
++  cycle
  |*  it=(iterator)
  ^+  it
  =+  it-init=it
  ?:  (is-empty it-init)
    ~|  'empty-iterator'
    !!
  |.
  =+  (it)
  ?@  -
    $(it it-init)
  [i ..$(it next)]
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
  =+  [get-it get-select]=[(it) (select)]
  ?.  &(?=(^ get-it) ?=(^ get-select))
    ~
  ?.  i.get-select
    $(it next.get-it, select next.get-select)
  :-  i.get-it
  ..$(it next.get-it, select next.get-select)
::
++  drop-while
  |*  [f=$-(* ?) it=(iterator)]
  ^+  it
  |.
  =+  (it)
  ?~  -  ~
  ?:  (f i)
    $(it next)
  [i next]
::
++  filter
  |*  [f=$-(* ?) it=(iterator)]
  ^+  it
  |.
  =+  (it)
  ?~  -  ~
  ?.  (f i)
    $(it next)
  [i ..$(it next)]
::
++  slice
  |*  [[from=@ to=@ step=@] it=(iterator)]
  ^+  it
  =/  counter=@  0
  |.
  ?:  (gte counter to)
    ~
  =+  (it)
  ?~  -  ~
  ?.  =(0 from)
    $(it next, from (dec from), counter +(counter))
  :-  i
  ..$(it next, from (dec step), counter +(counter))
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
  |*  [f=$-(* ?) it=(iterator)]
  ^+  it
  |.
  =+  (it)
  ?~  -  ~
  ?.  (f i)  ~
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
  $(i i, next next)  ::  Replaces original [i next] pair from `(it)`
                     ::  with the new values from `(next)`. Then the
                     ::  cycle continues with `next` iterator. This idiom
                     ::  is equivalent to `$(+< -)`, but this is
                     ::  even more cursed.
::
++  get-ind
  |*  [ind=@ it=(iterator)]
  |-  ^-  (iterator-type it)
  =+  (it)
  ?:  &(!=(ind 0) ?=(^ -))
    $(ind (dec ind), it next)
  ?:  &(=(ind 0) ?=(^ -))
    i
  ~|  'index-not-reached'
  !!
::
++  is-empty
  |=  it=(iterator)
  ^-  ?
  =(~ (it))
::
++  zip
  |*  [a=(iterator) b=(iterator)]
  ^-  (iterator (pair (iterator-type a) (iterator-type b)))
  |.
  =+  [pop-a pop-b]=[(a) (b)]
  ?.  &(?=(^ pop-a) ?=(^ pop-b))
    ~
  [[i.pop-a i.pop-b] ..$(a next.pop-a, b next.pop-b)]
::
++  random
  |=  [from=@ to=@ eny=@]
  ?>  (lte from to)
  ^-  (iterator @)
  =+  rng=~(. og eny)
  =/  n=@  +((sub to from))
  |.
  =^  r  rng  (rads:rng n)
  [(add from r) ..$]
::
++  need-next
  |*  it=(iterator)
  ^-  [i=(iterator-type it) next=_it]
  =+  eval=(it)
  ~|  'empty-iterator'
  ?>(?=(^ eval) eval)
::
++  primes
  =/  n=@  2
  ^-  (iterator @)
  |.
  ~+
  ?:  =(n 2)
    [2 ..$(n 3)]
  =;  is-n-prime=?
    ?.  is-n-prime
      $(n (add 2 n))
    [n ..$(n (add 2 n))]
  %-  is-empty
  %+  filter  |=(i=@ =(0 (mod n i)))
  %+  take-while  |=(i=@ (lte (pow i 2) n))
  primes
::
--
