# Draws the SVG figures for trig-01 and its openers.
# Usage: bundle exec ruby make_figures.rb  (writes the SVGs into this folder)
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

# Returns an SVG canvas for a scene measured in metres, plus helpers that draw in metres.
# view is [left, bottom, right, top]; scale is pixels per metre.
class Scene
  attr_reader :svg

  def initialize(view, scale)
    @left, @bottom, @right, @top = view
    @scale = scale
    width, height = (@right - @left) * scale, (@top - @bottom) * scale
    @svg = Victor::SVG.new viewBox: "0 0 #{width} #{height}", width: width, height: height
  end

  def at(x, y) = [((x - @left) * @scale).round(2), ((@top - y) * @scale).round(2)]

  def line(from, to, **style)
    (x1, y1), (x2, y2) = at(*from), at(*to)
    svg.line x1: x1, y1: y1, x2: x2, y2: y2, stroke: :black, stroke_width: 1.6, **style
  end

  def dashed(from, to) = line(from, to, stroke_width: 1.3, stroke_dasharray: "6 4")

  def box(left, bottom, width, height, **style)
    x, y = at(left, bottom + height)
    svg.rect x: x, y: y, width: width * @scale, height: height * @scale,
             fill: :none, stroke: :black, stroke_width: 1.4, **style
  end

  def shade(*corners)
    svg.polygon points: corners.map { at(*_1).join(",") }.join(" "), fill: "#d9d9d9", stroke: :none
  end

  def dot(x, y) = svg.circle(cx: at(x, y)[0], cy: at(x, y)[1], r: 5, fill: :black)

  def label(str, x, y)
    svg.text str, x: at(x, y)[0], y: at(x, y)[1], dy: "0.35em", font_size: 14, **TEXT
  end
end

# Writes a side view of an archer on a tower looking over a wall, with the hidden strip shaded.
def line_of_sight(path)
  s = Scene.new([-3, -1.6, 20, 7.4], 22)
  s.shade([12.2, 2], [12.2, 0], [18, 0])
  s.line([-3, 0], [20, 0])
  s.box(-1.2, 0, 1.2, 6)
  s.box(11.8, 0, 0.4, 2, fill: "#888")
  s.dashed([0, 6], [18, 0])
  s.dot(0, 6)
  s.dot(13, 0.35)
  s.label("archer", 0, 6.7)
  s.label("6 m", -2.1, 3)
  s.label("2 m", 11.0, 1)
  s.label("wall", 12, 2.6)
  s.label("rogue", 13.1, 1.0)
  s.label("12 m", 6, -0.7)
  s.label("hidden strip: ? m", 15.5, -0.7)
  s.svg.save path
end

# Writes two glide paths drawn to the same scale: a squirrel (12 m over 30 m) and a lizard (4 m over 8 m).
def gliders(path)
  s = Scene.new([-4.5, -2.2, 48, 14.5], 9)
  s.line([-4, 0], [32, 0])
  s.box(-0.4, 0, 0.8, 13, fill: "#bbb")
  s.dashed([0, 12], [30, 0])
  s.label("12 m", -2.6, 6)
  s.label("30 m", 15, -1.2)
  s.label("squirrel", 15, 9)

  s.line([34, 0], [48, 0])
  s.box(36.6, 0, 0.8, 5, fill: "#bbb")
  s.dashed([37, 4], [45, 0])
  s.label("4 m", 34.9, 2)
  s.label("8 m", 41, -1.2)
  s.label("lizard", 41, 6.5)
  s.svg.save path
end

triangle "sides.svg", %w[adjacent opposite hypotenuse], ["θ"]
triangle "pqr.svg", %w[q r p], ["θ", "φ"]
line_of_sight "line-of-sight.svg"
gliders "gliders.svg"
