# Draws the SVG figures for trig-01.
# Usage: bundle exec ruby make_figures.rb  (writes sides.svg and pqr.svg here)
require "victor"

UNIT = 60
VIEW = { left: -0.8, top: 3.3, width: 5.2, height: 4.0 }

A = [0.0, 0.0]
B = [4.0, 0.0]
C = [0.0, 3.0]

# Converts maths coordinates (y up, in units) to SVG coordinates (y down, in pixels).
def px(point)
  x, y = point
  [((x - VIEW[:left]) * UNIT).round(2), ((VIEW[:top] - y) * UNIT).round(2)]
end

def direction(from, to)
  Math.atan2(to[1] - from[1], to[0] - from[0])
end

def polar(origin, radius, angle)
  [origin[0] + radius * Math.cos(angle), origin[1] + radius * Math.sin(angle)]
end

# Marks the angle at vertex between the rays towards p1 and p2, and labels it.
def angle_mark(svg, vertex, p1, p2, label)
  lo, hi = [direction(vertex, p1), direction(vertex, p2)].sort
  start, finish = px(polar(vertex, 0.7, lo)), px(polar(vertex, 0.7, hi))
  r = 0.7 * UNIT
  svg.path d: "M #{start.join(' ')} A #{r} #{r} 0 0 0 #{finish.join(' ')}",
           fill: :none, stroke: :black, stroke_width: 1.2
  x, y = px(polar(vertex, 1.05, (lo + hi) / 2))
  svg.text label, x: x, y: y, dy: "0.35em", font_size: 20, font_style: :italic, **TEXT
end

TEXT = { text_anchor: :middle, font_family: "serif" }

# Writes a right triangle with the right angle at A, θ at B and an optional second angle at C.
# side_labels are for AB (bottom), AC (left) and BC (hypotenuse).
def triangle(path, side_labels, angle_labels)
  svg = Victor::SVG.new viewBox: "0 0 #{VIEW[:width] * UNIT} #{VIEW[:height] * UNIT}",
                        width: VIEW[:width] * UNIT, height: VIEW[:height] * UNIT
  ab, ac, bc = side_labels
  words = side_labels.first.length > 1
  style = words ? { font_size: 16 } : { font_size: 20, font_style: :italic }
  turn = ->(degrees, x, y) { words ? { transform: "rotate(#{degrees} #{x} #{y})" } : {} }

  svg.build do
    polygon points: [A, B, C].map { |p| px(p).join(",") }.join(" "),
            fill: :none, stroke: :black, stroke_width: 2
    square = [[0.3, 0], [0.3, 0.3], [0, 0.3]].map { |p| px(p).join(",") }.join(" ")
    polyline points: square, fill: :none, stroke: :black, stroke_width: 1.2

    x, y = px([2, -0.4])
    text ab, x: x, y: y, dy: "0.35em", **style, **TEXT
    x, y = px([-0.4, 1.5])
    text ac, x: x, y: y, dy: "0.35em", **turn.(-90, x, y), **style, **TEXT
    x, y = px([2.25, 1.8])
    text bc, x: x, y: y, dy: "0.35em", **turn.(36.87, x, y), **style, **TEXT
  end

  angle_mark(svg, B, A, C, angle_labels[0])
  angle_mark(svg, C, A, B, angle_labels[1]) if angle_labels[1]
  svg.save path
end

triangle "sides.svg", %w[adjacent opposite hypotenuse], ["θ"]
triangle "pqr.svg", %w[q r p], ["θ", "φ"]
