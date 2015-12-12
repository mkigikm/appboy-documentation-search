require 'json'
require 'fileutils'

module Jekyll
  module JsSearch
    class IndexFile < Jekyll::StaticFile
      def write(dest)
        return true
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
        return self
      end

      def to_h
        return {
          :id => @id,
          :title => @title,
          :body => @body,
          :url => @url
        }
      end
    end
    
    class Indexer < Jekyll::Generator
      HEADING_REGEX = Regexp.compile(/^(#+) +([^{}]*)(\{.*\})?/)
      def initialize(config = {})
        @sections = []
        @id = 1
      end

      def generate(site)
        Jekyll.logger.info('Appboy Documentation Search:', 'Indexing')

        site.pages.each do |page|
          initialize_page(page['permalink'], page['title'])

          case page['layout']
          when 'page'
            # pages with page layout contain their own content
            index(page.content)
          when 'section', 'collection'
            # section and collection are associated with a site.collection
            site.collections[page['collection']].docs.each do |article|
              index(article.content)
            end
          when 'platform'
            # platform has slightly more complicated logic for whether articles
            # are included
            site.collections[page['collection']].docs.each do |article|
              if self.class.article_on_page(article.data, page)
                index(article.content)
              end
            end
          end
        end

        write_index(site)

        return nil
      end

      private

      def self.heading_to_anchor(heading)
        return heading.strip.gsub(' ', '-').downcase().gsub(' ', '-')
          .gsub(/[^-a-z0-9]/, '')
      end

      # logic in `_layouts/platform.html` in documentation
      def self.article_on_page(data, page)
        return (!data['android_or_fireos'] ||
                data['android_or_fireos'] == page['android_or_fireos']) &&
               (!data['subplatform'] ||
                data['subplatform'] == page['subplatform'])
      end

      def initialize_page(link, title)
        @link = link
        @title = title
        @heading_stack = [title]
      end

      def index(content)
        content.each_line do |line|
          line = line.chomp()
          if HEADING_REGEX.match(line)
            start_new_section(line)
          else
            current_section << line
          end
        end

        return nil
      end

      def start_new_section(heading)
        _, level, heading, anchor = HEADING_REGEX.match(heading).to_a()
        push_heading(level.length, heading)
        add_section(heading, anchor)

        return nil
      end

      def push_heading(level, heading)
        # if heading stack only contains the page title, we have a top level
        # header. To guard against input error, we use the length of this
        # (how many ###'s) to determine how to pop the stack
        if @heading_stack.length == 1
          @initial_heading = level - 1
        end
        @heading_stack = @heading_stack.take(level - @initial_heading)
        @heading_stack << heading

        return nil
      end

      def add_section(heading, anchor)
        section = Section.new(
          section_title(),
          section_url(heading, anchor),
          @id
        )
        section << heading
        @sections << section
        @id += 1

        return nil
      end

      def section_title
        return @heading_stack.join(' > ')
      end

      def section_url(heading, anchor)
        return anchor ? "#{@link}##{anchor[2..-2]}" :
                 "#{@link}##{self.class.heading_to_anchor(heading)}"
      end

      def current_section
        return @sections.last()
      end

      def write_index(site)
        FileUtils.mkdir_p(File.join(site.dest, 'assets/js'))
        filename = File.join(site.dest, 'assets/js/lunr.json')
        File.open(filename, 'w') { |f| f.write(JSON.generate(to_h())) }
        site.static_files << IndexFile.new(site, site.dest, '/', 'assets/js/lunr.json')
      end

      def to_h
        return @sections.map(&:to_h)
      end
    end
  end
end
