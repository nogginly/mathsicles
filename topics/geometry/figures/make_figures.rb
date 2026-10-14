# Draws the SVG figures for the geometry strand and its openers.
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
# rays marked by an arc and labelled; a nil label leaves that gap unmarked. With straight: true the
# rays at 0° and 180° form one line. Labels that are a single letter are set in italics, as unknowns.
def angles_at_point(path, directions, labels, straight: false)
  s = Scene.new(straight ? [-2.4, -0.5, 2.4, 1.9] : [-2.1, -2.1, 2.1, 2.1], 45)
  o = [0, 0]
  directions.each { |d| s.line(o, s.polar(o, 1.9, d)) }
  gaps = directions.each_cons(2).to_a
  gaps << [directions.last, directions.first + 360] unless straight
  gaps.zip(labels).each_with_index do |((from, to), text), i|
    next unless text

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

# Draws two parallel lines crossed by a transversal at angle t (degrees) into scene s, offset by ox.
# marks are [crossing, from, to, label] with crossing :lower or :upper and from/to in degrees
# measured at that crossing; caption, if given, is written underneath.
def draw_parallels(s, ox, t, marks, caption = nil)
  gap = 1.5
  lower = [ox - 0.5, 0]
  upper = [lower[0] + gap / Math.tan(t * Math::PI / 180), gap]
  [0, gap].each do |y|
    s.line([ox - 2, y], [ox + 2, y])
    s.line([ox + 1.25, y + 0.12], [ox + 1.4, y], stroke_width: 1.4)
    s.line([ox + 1.25, y - 0.12], [ox + 1.4, y], stroke_width: 1.4)
  end
  s.line(s.polar(lower, 0.9, t + 180), s.polar(upper, 0.9, t))
  marks.each_with_index do |(which, from, to, text), i|
    at = which == :lower ? lower : upper
    radius = 0.32 + 0.06 * (i % 2)
    s.arc(at, radius, from, to)
    s.label(text, *s.polar(at, radius + 0.33, (from + to) / 2.0), size: 18, italic: text.length == 1)
  end
  s.label(caption, ox, -1.2, size: 18) if caption
end

def parallels(path, t, marks)
  s = Scene.new([-2.3, -1.1, 2.3, 2.6], 48)
  draw_parallels(s, 0, t, marks)
  s.svg.save path
end

def parallels_pair(path)
  s = Scene.new([-2.3, -1.6, 7.3, 2.6], 40)
  draw_parallels(s, 0, 60, [[:lower, 0, 60, "60°"], [:upper, 0, 60, "60°"]], "corresponding (F)")
  draw_parallels(s, 5, 60, [[:lower, 0, 60, "60°"], [:upper, 180, 240, "60°"]], "alternate (Z)")
  s.svg.save path
end

# Writes a cross-section of a periscope: two parallel mirrors at 45° and the light's path through it.
def periscope(path)
  s = Scene.new([-2.4, -0.6, 3.6, 5.8], 40)
  box = { stroke_width: 2.2 }
  s.line([0, 0], [1.2, 0], **box)
  s.line([0, 5.2], [1.2, 5.2], **box)
  s.line([0, 0], [0, 4.0], **box)
  s.line([1.2, 1.2], [1.2, 5.2], **box)
  mirror = { stroke_width: 4, stroke: "#555" }
  s.line([0.2, 4.8], [1.0, 4.0], **mirror)
  s.line([0.2, 1.0], [1.0, 0.2], **mirror)
  light = { stroke_width: 1.3, stroke_dasharray: "5 3" }
  s.line([-1.8, 4.4], [0.6, 4.4], **light)
  s.line([0.6, 4.4], [0.6, 0.6], **light)
  s.line([0.6, 0.6], [3.0, 0.6], **light)
  [[[-1.0, 4.4], 0], [[0.6, 2.5], 270], [[2.0, 0.6], 0]].each do |tip, d|
    s.line(tip, s.polar(tip, 0.22, d + 150), stroke_width: 1.3)
    s.line(tip, s.polar(tip, 0.22, d + 210), stroke_width: 1.3)
  end
  s.arc([0.6, 4.4], 0.35, 135, 180)
  s.label("45°", -0.25, 4.85, size: 16)
  s.arc([0.6, 0.6], 0.35, 315, 360)
  s.label("?", 1.45, 0.4, size: 18)
  s.label("light in", -1.4, 4.75, size: 16)
  s.label("to your eye", 2.65, 0.95, size: 16)
  s.label("mirror", 2.0, 4.4, size: 16)
  s.label("mirror", -0.9, 0.6, size: 16)
  s.svg.save path
end

# Writes Eratosthenes' set-up: parallel sun rays, a stick at Alexandria, a well at Syene, and the
# angle at the Earth's centre. The angle is exaggerated (20° drawn) so it can be seen.
def eratosthenes(path)
  s = Scene.new([-3.6, -3.0, 3.0, 5.0], 38)
  r = 2.5
  o = [0, 0]
  s.svg.circle cx: s.at(*o)[0], cy: s.at(*o)[1], r: r * 38, fill: :none, stroke: :black, stroke_width: 1.6
  syene, alex = s.polar(o, r, 90), s.polar(o, r, 110)
  ray = { stroke_width: 1.2, stroke: "#777" }
  [syene[0], alex[0], 1.0, 2.0].each { |x| s.line([x, 4.4], [x, Math.sqrt([r * r - x * x, 0].max)], **ray) }
  s.line(o, syene, stroke_width: 1.2, stroke_dasharray: "5 3")
  s.line(o, alex, stroke_width: 1.2, stroke_dasharray: "5 3")
  s.line(alex, s.polar(o, r + 0.9, 110), stroke_width: 2.6)
  s.arc(alex, 0.55, 90, 110)
  s.label("7.2°", *s.polar(alex, 1.15, 96), size: 15)
  s.arc(o, 0.6, 90, 110)
  s.label("?", -0.3, 0.95, size: 18)
  s.dot(*o)
  s.label("Syene", 0.7, 1.95, size: 15)
  s.label("Alexandria", -2.3, 2.3, size: 15)
  s.label("sun's rays", 1.5, 4.7, size: 15)
  s.label("not to scale", 1.9, -2.7, size: 13, italic: true)
  s.svg.save path
end

angles_at_point "line.svg", [0, 50, 180], ["?", "130°"], straight: true
angles_at_point "point.svg", [0, 90, 240], ["90°", "150°", "?"]
angles_at_point "practice-a.svg", [0, 108, 180], ["a", "72°"], straight: true
angles_at_point "practice-b.svg", [0, 100, 240], ["100°", "140°", "b"]
angles_at_point "practice-c.svg", [0, 65, 140, 180], ["65°", "c", "40°"], straight: true
honeycomb "honeycomb.svg"
angles_at_point "crossing.svg", [20, 90, 200, 270], ["70°", "b", "a", nil]
parallels_pair "parallels.svg"
angles_at_point "practice-d.svg", [15, 80, 195, 260], ["65°", "b", "a", nil]
parallels "practice-e.svg", 70, [[:lower, 70, 180, "110°"], [:upper, 0, 70, "c"], [:upper, 250, 360, "d"]]
parallels "practice-f.svg", 48, [[:upper, 180, 228, "48°"], [:lower, 48, 180, "f"]]
periscope "periscope.svg"
eratosthenes "eratosthenes.svg"
