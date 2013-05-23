module ApplicationHelper
  def source_dive(&blk)
    content_tag :div, class: 'protip source_dive' do
      content_tag(:h3, 'Source Diving') +
      content_tag(:div, class: 'protip-content', &blk)
    end
  end
end
