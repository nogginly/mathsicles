# Builds figures and worksheet PDFs, redoing only what is out of date.
#
#   bundle exec rake            figures, then all PDFs
#   bundle exec rake figures    regenerate stale figures only
#   bundle exec rake pdfs       build stale PDFs only
#   bundle exec rake clobber    delete all build output
#
# Set QUARTO to use a quarto binary that is not on PATH.

require "rake/clean"

QUARTO = ENV.fetch("QUARTO", "quarto")
OUTPUT = "_output"
SHARED = FileList["_quarto.yml", "templates/*"]
FIGURE_SCRIPTS = FileList["topics/*/figures/make_figures.rb"]
SOURCES = FileList["topics/**/*.md", "answers/**/*.md"]

CLOBBER.include(OUTPUT, ".quarto")

def pdf_for(source) = File.join(OUTPUT, source.ext("pdf"))

# A strand's figures are stale when there are none, or when any script in its
# figures folder is newer than the oldest SVG there.
def figures_stale?(dir)
  svgs = FileList[File.join(dir, "*.svg")]
  scripts = FileList[File.join(dir, "*.rb")]
  svgs.empty? || scripts.map { File.mtime(_1) }.max > svgs.map { File.mtime(_1) }.min
end

desc "Regenerate figures whose scripts have changed"
task :figures do
  FIGURE_SCRIPTS.each do |script|
    dir = File.dirname(script)
    next unless figures_stale?(dir)

    sh "ruby", File.basename(script), chdir: dir
  end
end

SOURCES.each do |source|
  strand_figures = FileList[File.join("topics", source.pathmap("%{^[^/]+/,}d"), "figures", "*.svg")]
  file pdf_for(source) => [source, *SHARED, *strand_figures] do
    sh QUARTO, "render", source
  end
end

desc "Build PDFs whose sources have changed"
task pdfs: SOURCES.map { pdf_for(_1) }

desc "Regenerate figures, then build PDFs"
task build: :figures do
  Rake::Task[:pdfs].invoke
end

task default: :build
