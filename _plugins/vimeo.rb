module Jekyll
  class Vimeo < Liquid::Tag
    attr_reader :width, :height

    def initialize(name, id, tokens)
      super
      @id = id
      @width = 640
      @height = 510
    end

    def render(context)
      %(<iframe src="http://player.vimeo.com/video/#{@id}" width="#{self.width}" height="#{self.height}" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>)
    end
  end
end

Liquid::Template.register_tag('vimeo', Jekyll::Vimeo)
