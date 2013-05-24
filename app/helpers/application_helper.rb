module ApplicationHelper
  def source_dive(&blk)
    content_tag :div, class: 'protip source_dive' do
      content_tag(:h3, 'Source Diving') +
      content_tag(:div, class: 'protip-content', &blk)
    end
  end

  def snippet(name)
    path = Rails.root + 'app/snippets' + name
    data = File.read path
    highlit = Albino.colorize data, :ruby
    Haml::Helpers.preserve(highlit)
  end
end
