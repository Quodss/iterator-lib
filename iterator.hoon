::  lib/iterator.hoon
::
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
++  to-list
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
::
++  take
  |*  [n=@ it=(iterator)]
  ^+  it
  |.
  ?:  =(0 n)  ~
  =+  (it)
  ?~  -  ~
  :-  i
  %=  ..$
    n  (dec n)
    it  next
  ==
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
  |*  [it=(iterator) f=_=>(~ |=([* *] +<+))]
  ^+  it
  |.
  =+  (it)
  ?~  -  ~
  =/  result  (f i +<+.f)
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
  |*  [it=(iterator) f=$-(* ?)]
  ^+  it
  |.
  =+  (it)
  ?~  -  ~
  ?:  (f i)
    $(it next)
  [i ..$(it next)]
::
++  slice
  |*  [from=@ to=@ step=@ it=(iterator)]
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
--
