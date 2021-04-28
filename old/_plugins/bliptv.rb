module Jekyll
  class Bliptv < Liquid::Tag
    attr_reader :width, :height

    def initialize(name, id, tokens)
      super
      @id = id
      @width = 640
      @height = 510
    end

    def render(context)
      %(<iframe src="http://blip.tv/play/#{@id}.html?p=1" width="#{self.width}" height="#{self.height}" frameborder="0" allowfullscreen></iframe>)
    end
  end
end

Liquid::Template.register_tag('bliptv', Jekyll::Bliptv)
