if defined?(Encoding) && (Encoding.default_internal.nil? || !Encoding.default_internal.ascii_compatible?)
  Encoding.default_internal = "UTF-8" 
else
  $KCODE = "U"
end
