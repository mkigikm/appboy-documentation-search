require 'json'
require 'fileutils'

module Jekyll
  module JsSearch
    class IndexFile < Jekyll::StaticFile
      def write(dest)
        true
      end
    end

    class Section
      def initialize(title, url, id)
        @title = title
        @body = ''
        @url = url
        @id = id
      end

      def <<(line)
        @body << " #{line}"
      end

      def as_json
        return {
          :id => @id,
          :title => @title,
          :body => @body,
          :url => @url
        }
      end
    end
    
    class Indexer < Jekyll::Generator
      def initialize(config = {})
        @heading_regex = Regexp.compile(/^(#+) +([^{}]*)(\{.*\})?/)
        @sections = []
        @id = 1
      end

      def generate(site)
        Dir.glob('_collections/*/*.md').each do |filename|
          url_base = filename.split('/')[1]
          index(url_base, filename)
        end

        FileUtils.mkdir_p(File.join(site.dest, 'assets/js'))
        filename = File.join(site.dest, 'assets/js/lunr.json')
        File.open(filename, 'w') { |f| f.write(JSON.generate(as_json())) }
        site.static_files << IndexFile.new(site, site.dest, '/', 'assets/js/lunr.json')
      end

      private

      def index(url_base, filename)
        lines = File.readlines(filename)
        @heading_stack = []
        @heading_stack << url_base.gsub('_', ' ')
        @url_base = url_base
        # skip over jekyll frontmatter
        in_front_matter = true
        lines.drop(1).map(&:chomp).each do |line|
          if in_front_matter
            if line =~ /-+/
              in_front_matter = false
            end
          else
            handle_line(line)
          end
        end
      end

      def as_json
        @sections.map(&:as_json)
      end

      def handle_line(line)
        if @heading_regex.match(line)
          # new section
          start_new_section(line)
        else
          current_section << line
        end
      end

      def start_new_section(heading)
        _, level, heading, anchor = @heading_regex.match(heading).to_a()
        if anchor
          section_url = "/#{@url_base}/##{anchor[2..-2]}"
        else
          section_url = "/#{@url_base}/##{heading_to_anchor(heading)}"
        end

        @heading_stack = @heading_stack.take(level.length)
        @heading_stack << heading

        #section = Section.new(heading, section_url, @id)
        section = Section.new(@heading_stack.join(' > '), section_url, @id)
        @id += 1
        section << heading
        @sections << section
      end

      def current_section
        @sections.last
      end

      def heading_to_anchor(heading)
        heading.strip.gsub(' ', '-').downcase().gsub(' ', '-')
          .gsub(/[^-a-z0-9]/, '')
      end
    end
  end
end
