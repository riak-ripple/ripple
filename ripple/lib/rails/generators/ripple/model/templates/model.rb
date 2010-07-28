class <%= class_name %><%= " < #{options[:parent].classify}" if options[:parent] %>
<% unless options[:parent] -%>
  include Ripple::Document
<% end -%>

<% attributes.reject{|attr| attr.reference?}.each do |attribute| -%>
  property :<%= attribute.name %>, <%= attribute.type_class %>
<% end -%>
end
