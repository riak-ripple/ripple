if defined? Encoding
  Encoding.default_internal = "UTF-8" if Encoding.default_internal.nil? ||
                                        !Encoding.default_internal.ascii_compatible?
else
  $KCODE = "U"
end
