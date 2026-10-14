# Draws the SVG figures for geo-01 and its openers.
# Usage: bundle exec ruby make_figures.rb  (writes the SVGs into this folder)
require "victor"

TEXT = { text_anchor: :middle, font_family: "serif" }

# An SVG canvas for a scene measured in abstract units, with helpers that draw in those units.
# view is [left, bottom, right, top]; scale is pixels per unit.
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
    svg.line x1: x1, y1: y1, x2: x2, y2: y2, stroke: :black, stroke_width: 1.8, **style
  end

  def polygon(corners, **style)
    svg.polygon points: corners.map { at(*_1).join(",") }.join(" "),
                fill: :none, stroke: :black, stroke_width: 1.4, **style
  end

  def dot(x, y, r: 3.5) = svg.circle(cx: at(x, y)[0], cy: at(x, y)[1], r: r, fill: :black)

  # Draws an arc of the given radius around centre, from one direction to another (degrees, anticlockwise).
  def arc(centre, radius, from_deg, to_deg)
    start, finish = polar(centre, radius, from_deg), polar(centre, radius, to_deg)
    large = (to_deg - from_deg) % 360 > 180 ? 1 : 0
    r = radius * @scale
    svg.path d: "M #{at(*start).join(' ')} A #{r} #{r} 0 #{large} 0 #{at(*finish).join(' ')}",
             fill: :none, stroke: :black, stroke_width: 1.1
  end

  def label(str, x, y, size: 20, italic: false)
    style = italic ? { font_style: :italic } : {}
    svg.text str, x: at(x, y)[0], y: at(x, y)[1], dy: "0.35em", font_size: size, **TEXT, **style
  end

  def polar(centre, radius, deg)
    rad = deg * Math::PI / 180
    [centre[0] + radius * Math.cos(rad), centre[1] + radius * Math.sin(rad)]
  end
end

# Writes rays from a point at the given directions (degrees), with each gap between neighbouring
# rays marked by an arc and labelled. With straight: true the rays at 0° and 180° form one line.
# Labels that are a single letter are set in italics, as unknowns.
def angles_at_point(path, directions, labels, straight: false)
  s = Scene.new(straight ? [-2.4, -0.5, 2.4, 1.9] : [-2.1, -2.1, 2.1, 2.1], 45)
  o = [0, 0]
  directions.each { |d| s.line(o, s.polar(o, 1.9, d)) }
  gaps = directions.each_cons(2).to_a
  gaps << [directions.last, directions.first + 360] unless straight
  gaps.zip(labels).each_with_index do |((from, to), text), i|
    radius = 0.42 + 0.1 * (i % 2)
    s.arc(o, radius, from, to)
    s.label(text, *s.polar(o, radius + 0.5, (from + to) / 2.0), italic: text.length == 1)
  end
  s.dot(*o)
  s.svg.save path
end

# Writes a patch of honeycomb (flat-topped hexagons) with the corner where three cells meet marked.
def honeycomb(path)
  s = Scene.new([-2.9, -2.3, 4.4, 2.3], 42)
  r = 1.0
  (-3..3).each do |q|
    (-3..3).each do |row|
      cx, cy = 1.5 * r * q, Math.sqrt(3) * r * (row + q / 2.0)
      next if cx.abs > 4.5 || cy.abs > 3
      s.polygon((0...6).map { |k| s.polar([cx, cy], r, 60 * k) }, stroke: "#777")
    end
  end
  corner = [r, 0]
  [0, 120, 240].each { |d| s.line(corner, s.polar(corner, r, d), stroke_width: 2.4) }
  [[0, 120], [120, 240], [240, 360]].each do |from, to|
    s.arc(corner, 0.3, from, to)
    s.label("?", *s.polar(corner, 0.6, (from + to) / 2.0), size: 22)
  end
  s.dot(*corner, r: 4.5)
  s.svg.save path
end

angles_at_point "line.svg", [0, 50, 180], ["?", "130°"], straight: true
angles_at_point "point.svg", [0, 90, 240], ["90°", "150°", "?"]
angles_at_point "practice-a.svg", [0, 108, 180], ["a", "72°"], straight: true
angles_at_point "practice-b.svg", [0, 100, 240], ["100°", "140°", "b"]
angles_at_point "practice-c.svg", [0, 65, 140, 180], ["65°", "c", "40°"], straight: true
honeycomb "honeycomb.svg"
