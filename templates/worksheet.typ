// Numbered lists are exercises: give each one room for working.
#set enum(spacing: 4em)
#show heading.where(level: 1): it => block(below: 1em)[
  #text(size: 13pt, fill: rgb("#2a7ae2"))[#it.body]
]
