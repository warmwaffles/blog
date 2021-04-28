module Jekyll
  class Youtube < Liquid::Tag
    attr_reader :width, :height

    def initialize(name, id, tokens)
      super
      @id = id
      @width  = 640
      @height = 510
    end

    def render(context)
      %(<iframe width="#{self.width}" height="#{self.height}" src="http://www.youtube.com/embed/#{@id}" frameborder="0" allowfullscreen></iframe>)
    end
  end
end

Liquid::Template.register_tag('youtube', Jekyll::Youtube)
